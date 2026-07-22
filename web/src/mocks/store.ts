// In-memory mock store — seeded with the canonical narrative, full CRUD,
// order-lifecycle transition rules, and snake_case error codes from the docs
// taxonomy. Module singleton (globalThis) so state is dev-persistent across
// HMR and shared by all route handlers.
import type {
  Account,
  BankResolution,
  Comment,
  CommissionRequest,
  DeclineReason,
  DesignerProfile,
  DisputeReason,
  Earnings,
  EarningsEntry,
  MeasurementSession,
  ModerationAction,
  Notification,
  NotificationKind,
  NotificationPrefs,
  OrderStatus,
  Post,
  PublicProfile,
  Report,
  ReportReason,
  ReportSubjectKind,
  ThreadMessage,
  UserSummary,
} from "@/models";
import { canTransition } from "@/models";
import { MockApiError } from "./http";
import {
  daysAgo,
  seedAccounts,
  seedComments,
  seedDesigners,
  seedFollows,
  seedNotifications,
  seedOrders,
  seedPosts,
  seedReports,
  seedSessions,
  seedThreadMessages,
  seedLikes,
  seedSaves,
} from "./seed";

const USERNAME_RE = /^[a-z0-9._]{3,30}$/;

/**
 * QC failure taxonomy (capture-qc.md §1–2) with the canonical retake copy
 * (flows/vault.md), ordered EXACTLY as the contract tables run — §1
 * pre-checks first, then the §2 pose rows — because multiple failures
 * report the first by table order. QC is per pose (M-10): the front pose
 * keeps the frontality row; the side pose swaps in `not_side_profile` and
 * the arms-relaxed copy. The upload path reproduces a code when a pose's
 * file name contains it (designated fixture images).
 */
const QC_PRECHECKS: [code: string, guidance: string][] = [
  ["undecodable_image", "That image couldn't be read — try another photo"],
  ["low_resolution", "Move closer or use a higher-quality camera"],
  ["poor_lighting", "Find better lighting — avoid strong backlight"],
  ["blurry", "Hold steady and retake"],
];

export const QC_ORDER_FRONT: [code: string, guidance: string][] = [
  ...QC_PRECHECKS,
  ["no_body", "Make sure your whole body is visible"],
  ["multiple_bodies", "Make sure you're alone in frame"],
  ["partial_body", "Include head to ankles"],
  ["not_frontal", "Face the camera straight on"],
  ["camera_tilt", "Hold the phone upright"],
  ["arms_position", "Keep arms slightly away from your body"],
  ["too_far", "Move closer — fill more of the frame"],
];

export const QC_ORDER_SIDE: [code: string, guidance: string][] = [
  ...QC_PRECHECKS,
  ["no_body", "Make sure your whole body is visible"],
  ["multiple_bodies", "Make sure you're alone in frame"],
  ["partial_body", "Include head to ankles"],
  // Profile orientation sits at the frontality row's position (§2 pose 2).
  ["not_side_profile", "Turn your right side to the camera"],
  ["camera_tilt", "Hold the phone upright"],
  // Arms-relaxed replaces the front pose's arms-clearance rule, same slot.
  ["arms_position", "Let your arms hang relaxed at your sides"],
  ["too_far", "Move closer — fill more of the frame"],
];

/** Notification kind → the pref that gates it (pages.md B7 Notifications). */
const KIND_TO_PREF: Record<NotificationKind, keyof NotificationPrefs> = {
  quote: "quotes",
  status_change: "order_status",
  like: "social",
  follow: "social",
  comment: "social",
  payout: "payouts",
};

let nextId = 1;
function id(prefix: string): string {
  // crypto.randomUUID over Math.random — mock-only ids, but CodeQL
  // (js/insecure-randomness) is right that randomness feeding identifiers
  // should be cryptographic by default.
  return `${prefix}-${nextId++}-${crypto.randomUUID().slice(0, 8)}`;
}

function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

/**
 * A real (minimal) PDF for the F2-9 pdf export: Helvetica text lines,
 * uncompressed streams, byte-accurate xref — enough that any viewer opens
 * it. Lines flow across as many pages as they need (PR #103 review:
 * sessions carry unbounded manual measurements + append-only corrections,
 * so a single page dropped rows below the media box). Stands in for the
 * backend's rendered report the way the rest of the mock stands in for
 * api/common.
 */
function minimalPdf(lines: string[]): Buffer {
  const escape = (s: string) =>
    s.replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
  // 12pt Helvetica on 18pt leading from y=720 down to a 72pt bottom
  // margin → 36 lines per US-Letter page.
  const LINES_PER_PAGE = 36;
  const chunks: string[][] = [];
  for (let i = 0; i < Math.max(lines.length, 1); i += LINES_PER_PAGE) {
    chunks.push(lines.slice(i, i + LINES_PER_PAGE));
  }
  // Object layout: 1 catalog · 2 pages · 3 font · then per page i:
  // page object (4+2i) + its contents stream (5+2i).
  const objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    `<< /Type /Pages /Kids [${chunks
      .map((_, i) => `${4 + 2 * i} 0 R`)
      .join(" ")}] /Count ${chunks.length} >>`,
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
  ];
  for (const [i, chunk] of chunks.entries()) {
    const text = chunk
      .map((line, j) => `1 0 0 1 72 ${720 - j * 18} Tm (${escape(line)}) Tj`)
      .join("\n");
    const stream = `BT\n/F1 12 Tf\n${text}\nET`;
    objects.push(
      `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents ${5 + 2 * i} 0 R >>`,
      `<< /Length ${Buffer.byteLength(stream, "utf8")} >>\nstream\n${stream}\nendstream`,
    );
  }
  let body = "%PDF-1.4\n";
  const offsets: number[] = [];
  objects.forEach((obj, i) => {
    offsets.push(Buffer.byteLength(body, "utf8"));
    body += `${i + 1} 0 obj\n${obj}\nendobj\n`;
  });
  const xrefAt = Buffer.byteLength(body, "utf8");
  body += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const offset of offsets) {
    body += `${String(offset).padStart(10, "0")} 00000 n \n`;
  }
  body += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefAt}\n%%EOF`;
  return Buffer.from(body, "utf8");
}

/**
 * Seeded NG banks (mirrors the B8 onboarding Select). Payout surfaces
 * render the DISPLAY name ("GTBank ••• 4521 · Verified", Figma 210:3) —
 * the CBN code is a Paystack wire detail that must never reach bank_name.
 */
const BANK_NAMES: Record<string, string> = {
  "058": "GTBank",
  "044": "Access Bank",
  "057": "Zenith Bank",
  "011": "First Bank",
  "033": "UBA",
};

export class MockStore {
  accounts: Account[] = deepClone(seedAccounts);
  designers: DesignerProfile[] = deepClone(seedDesigners);
  posts: Post[] = deepClone(seedPosts);
  comments: Comment[] = deepClone(seedComments);
  sessions: MeasurementSession[] = deepClone(seedSessions);
  orders: CommissionRequest[] = deepClone(seedOrders);
  messages: ThreadMessage[] = deepClone(seedThreadMessages);
  notifications: Notification[] = deepClone(seedNotifications);
  reports: Report[] = deepClone(seedReports);
  /** viewer engagement: `${accountId}:${postId}` */
  likes = new Set<string>(seedLikes.map(([acc, post]) => `${acc}:${post}`));
  saves = new Set<string>(seedSaves.map(([acc, post]) => `${acc}:${post}`));
  /** `${followerAccountId}:${designerUsername}` */
  follows = new Set<string>(seedFollows.map(([a, d]) => `${a}:${d}`));
  blocks = new Set<string>();
  /** Idempotency replay cache: key → serialized response (api.md §4). */
  idempotency = new Map<string, { payloadHash: string; response: unknown }>();
  /**
   * Ranked-cursor snapshots (api.md §5 [Decided]): rank is computed at
   * first page and frozen for the cursor's 24h lifetime. Each snapshot is
   * bound to its viewer + endpoint/filter fingerprint — a cursor minted
   * on /feed is not honored on /explore or by another actor (PR #103
   * review).
   */
  rankedSnapshots = new Map<
    string,
    { ids: string[]; fingerprint: string; created_at: number }
  >();
  orderCounter = 1059;
  /** Uploaded media (composer) — stands in for object storage. */
  media = new Map<string, { data: string; contentType: string }>();
  /** Threads that already received the scripted counterparty reply (MI-17). */
  autoReplied = new Set<string>();

  // -- helpers --------------------------------------------------------------

  accountByUsername(username: string): Account {
    const account = this.accounts.find((a) => a.username === username);
    if (!account) {
      throw new MockApiError("not_found", "Account not found", 404);
    }
    return account;
  }

  designerByUsername(username: string): DesignerProfile | undefined {
    return this.designers.find((d) => d.username === username);
  }

  private viewPost(post: Post, viewerId: string): Post {
    return {
      ...deepClone(post),
      liked: this.likes.has(`${viewerId}:${post.id}`),
      saved: this.saves.has(`${viewerId}:${post.id}`),
    };
  }

  private notify(input: Omit<Notification, "id" | "created_at" | "read_at">) {
    // Per-event toggles (pages.md B7): a disabled pref drops the event for
    // that recipient — account_id may be an account or designer-profile id.
    const designer = this.designers.find((d) => d.id === input.account_id);
    const account = this.accounts.find(
      (a) => a.id === (designer?.account_id ?? input.account_id),
    );
    if (account && !account.notification_prefs[KIND_TO_PREF[input.kind]]) {
      return;
    }
    this.notifications.unshift({
      ...input,
      id: id("ntf"),
      read_at: null,
      created_at: new Date().toISOString(),
    });
  }

  /** Same key + same payload → replay; different payload → 409 (api.md §4). */
  idempotent<T>(key: string | null, payloadHash: string, run: () => T): T {
    if (!key) return run();
    const existing = this.idempotency.get(key);
    if (existing) {
      if (existing.payloadHash !== payloadHash) {
        throw new MockApiError(
          "idempotency_conflict",
          "Idempotency key reused with a different payload",
          409,
        );
      }
      return existing.response as T;
    }
    const response = run();
    this.idempotency.set(key, { payloadHash, response });
    return response;
  }

  // -- auth & profile -------------------------------------------------------

  me(username: string): Account {
    return deepClone(this.accountByUsername(username));
  }

  updateMe(
    username: string,
    patch: Partial<
      Pick<Account, "username" | "display_name" | "profile_location">
    > & {
      /** Partial per-event toggles — merged over the existing prefs. */
      notification_prefs?: Partial<NotificationPrefs>;
    },
  ): Account {
    const account = this.accountByUsername(username);
    if (patch.username && patch.username !== account.username) {
      if (!USERNAME_RE.test(patch.username)) {
        throw new MockApiError(
          "validation_failed",
          "Username must be 3-30 chars of a-z 0-9 . _",
          422,
        );
      }
      if (
        this.accounts.some(
          (a) => a.username.toLowerCase() === patch.username!.toLowerCase(),
        )
      ) {
        throw new MockApiError("name_taken", "That username is taken", 409);
      }
      account.username = patch.username;
    }
    if (patch.display_name !== undefined)
      account.display_name = patch.display_name;
    if (patch.profile_location !== undefined) {
      account.profile_location = patch.profile_location;
      // The designer profile's cached location mirrors the account's —
      // settings B7 is the single write path (X-10 tier 1), and near-me
      // must rank against the CURRENT value (PR #103 review).
      const designer = this.designerByUsername(account.username);
      if (designer) designer.location = patch.profile_location;
    }
    if (patch.notification_prefs !== undefined) {
      account.notification_prefs = {
        ...account.notification_prefs,
        ...patch.notification_prefs,
      };
    }
    return deepClone(account);
  }

  /** GDPR-parity data export (pages.md B7 Account & data; data-model §4). */
  exportData(username: string): Record<string, unknown> {
    const account = this.accountByUsername(username);
    return deepClone({
      account,
      sessions: this.sessions.filter((s) => s.customer_id === account.id),
      orders: this.orders.filter((o) => o.customer.id === account.id),
      consent: account.consent,
      saved_post_ids: [...this.saves]
        .filter((k) => k.startsWith(`${account.id}:`))
        .map((k) => k.split(":")[1]),
      exported_at: new Date().toISOString(),
    });
  }

  /** Delete-all request — flags the account; purge is a backend job later. */
  requestDeletion(username: string): Account {
    const account = this.accountByUsername(username);
    account.deletion_state = "deletion_pending";
    return deepClone(account);
  }

  // -- social ---------------------------------------------------------------

  /**
   * Ranked pagination (api.md §5 [Decided]): the cursor encodes a snapshot
   * of the ranked order frozen at first-page time for its 24h lifetime, so
   * pages never duplicate or skip posts within one scroll session — new
   * posts appear on refresh, not mid-scroll; posts deleted after the
   * snapshot simply drop out. Engagement state (liked/saved/counts) stays
   * live — only the RANK is frozen. Expired/garbled cursors start a fresh
   * scroll session (PR #103 review: the plain offset cursor recomputed the
   * rank per page and could duplicate or skip).
   */
  rankedPage(
    viewerUsername: string,
    queryFingerprint: string,
    rank: () => Post[],
    cursorRaw: string | null,
    limit: number,
  ): { items: Post[]; next_cursor: string | null } {
    const viewer = this.accountByUsername(viewerUsername);
    const fingerprint = `${viewer.id}|${queryFingerprint}`;
    const DAY_MS = 24 * 60 * 60 * 1000;
    // Registry hygiene = expiry only: snapshots live for the FULL 24h
    // cursor lifetime (PR #103 review: size-based FIFO eviction silently
    // invalidated still-active cursors under multi-user load, producing
    // duplicate/skipped pages).
    for (const [key, snapshot] of this.rankedSnapshots) {
      if (Date.now() - snapshot.created_at >= DAY_MS) {
        this.rankedSnapshots.delete(key);
      }
    }
    let snapshotId: string | null = null;
    let offset = 0;
    if (cursorRaw) {
      const decoded = Buffer.from(cursorRaw, "base64url").toString("utf8");
      const at = decoded.lastIndexOf(":");
      const id = decoded.slice(0, at);
      const parsedOffset = Number(decoded.slice(at + 1));
      const snapshot = this.rankedSnapshots.get(id);
      if (
        snapshot &&
        snapshot.fingerprint === fingerprint &&
        Number.isFinite(parsedOffset) &&
        parsedOffset >= 0
      ) {
        snapshotId = id;
        offset = parsedOffset;
      }
    }
    if (snapshotId === null) {
      snapshotId = id("rank");
      this.rankedSnapshots.set(snapshotId, {
        ids: rank().map((p) => p.id),
        fingerprint,
        created_at: Date.now(),
      });
    }
    const snapshot = this.rankedSnapshots.get(snapshotId)!;
    const live = new Map(this.posts.map((p) => [p.id, p] as const));
    const items: Post[] = [];
    let i = offset;
    for (; i < snapshot.ids.length && items.length < limit; i++) {
      const post = live.get(snapshot.ids[i]);
      if (post) items.push(this.viewPost(post, viewer.id));
    }
    return {
      items,
      next_cursor:
        i < snapshot.ids.length
          ? Buffer.from(`${snapshotId}:${i}`, "utf8").toString("base64url")
          : null,
    };
  }

  feed(viewerUsername: string): Post[] {
    const viewer = this.accountByUsername(viewerUsername);
    const followed = new Set(
      [...this.follows]
        .filter((f) => f.startsWith(`${viewer.id}:`))
        .map((f) => f.split(":")[1]),
    );
    return this.posts
      .filter((p) => followed.has(p.designer.username))
      .sort(
        (a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
      )
      .map((p) => this.viewPost(p, viewer.id));
  }

  explore(
    viewerUsername: string,
    q?: string,
    tags?: string[],
    priceBand?: "budget" | "mid" | "premium",
    maxTurnaroundDays?: number,
    nearMe?: boolean,
  ): Post[] {
    const viewer = this.accountByUsername(viewerUsername);
    let posts = [...this.posts];
    if (q) {
      const needle = q.toLowerCase();
      posts = posts.filter(
        (p) =>
          p.caption.toLowerCase().includes(needle) ||
          p.designer.username.includes(needle) ||
          p.designer.display_name.toLowerCase().includes(needle) ||
          p.style_tags.some((t) => t.includes(needle)),
      );
    }
    if (tags && tags.length > 0) {
      posts = posts.filter((p) => tags.some((t) => p.style_tags.includes(t)));
    }
    if (priceBand) {
      // bands: budget <25k, mid 25–100k, premium >100k NGN (api.md §5)
      posts = posts.filter((p) => {
        if (p.base_price_cents === null) return false;
        const naira = p.base_price_cents / 100;
        if (priceBand === "budget") return naira < 25_000;
        if (priceBand === "mid") return naira >= 25_000 && naira <= 100_000;
        return naira > 100_000;
      });
    }
    if (maxTurnaroundDays !== undefined) {
      posts = posts.filter((p) => p.turnaround_days <= maxTurnaroundDays);
    }
    posts.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    );
    if (nearMe) {
      // Proximity RANKING, not a hard gate (pages.md B2, X-10 tier 1):
      // designer profile_location vs the caller's — city > state > country;
      // locationless designers simply don't rank (sort last). Recency holds
      // within a tier. Callers without a profile location keep recency order.
      const home = viewer.profile_location;
      if (home) {
        const tierOf = (post: Post): number => {
          const loc = this.designerByUsername(post.designer.username)?.location;
          if (!loc) return 3;
          // City/state names repeat across countries (locations are
          // free-text and editable), so the finer tiers require country
          // equality first (PR #103 review).
          if (loc.country !== home.country) return 3;
          if (loc.city === home.city && loc.state === home.state) return 0;
          if (loc.state === home.state) return 1;
          return 2;
        };
        // Array.prototype.sort is stable — recency survives within tiers.
        posts.sort((a, b) => tierOf(a) - tierOf(b));
      }
    }
    return posts.map((p) => this.viewPost(p, viewer.id));
  }

  post(idOrPermalink: string, viewerUsername: string): Post {
    const post = this.posts.find((p) => p.id === idOrPermalink);
    if (!post) throw new MockApiError("not_found", "Post not found", 404);
    const viewer = this.accountByUsername(viewerUsername);
    return this.viewPost(post, viewer.id);
  }

  createPost(
    designerUsername: string,
    input: {
      caption: string;
      style_tags: string[];
      base_price_cents: number | null;
      turnaround_days: number;
      media: { url: string; alt_text: string }[];
    },
  ): Post {
    const account = this.accountByUsername(designerUsername);
    const designer = this.designerByUsername(designerUsername);
    // Posting is allowed pre-KYC; accepting requests is not (flows/designer.md
    // §1 — the A-2 gate lives on createRequest as `post_unavailable`).
    if (!designer || !account.designer.enabled) {
      throw new MockApiError(
        "designer_profile_required",
        "Enable a designer profile to post",
        403,
      );
    }
    if (input.media.length === 0 || input.media.length > 10) {
      throw new MockApiError(
        "validation_failed",
        "Posts carry 1-10 images",
        422,
      );
    }
    const postId = id("post");
    const post: Post = {
      id: postId,
      designer: {
        id: designer.id,
        username: designer.username,
        display_name: designer.display_name,
        avatar_url: designer.avatar_url,
        verified: designer.verified,
      },
      caption: input.caption,
      style_tags: input.style_tags,
      base_price_cents: input.base_price_cents,
      currency: "NGN",
      turnaround_days: input.turnaround_days,
      media: input.media.map((m, i) => ({
        id: `${postId}-m${i}`,
        post_id: postId,
        url: m.url,
        position: i,
        alt_text: m.alt_text || `Outfit by ${designer.display_name}`,
        width: 1024,
        height: 1280,
      })),
      like_count: 0,
      comment_count: 0,
      liked: false,
      saved: false,
      created_at: new Date().toISOString(),
    };
    this.posts.unshift(post);
    designer.posts_count += 1;
    return deepClone(post);
  }

  deletePost(postId: string, actorUsername: string): void {
    const post = this.posts.find((p) => p.id === postId);
    if (!post) throw new MockApiError("not_found", "Post not found", 404);
    if (post.designer.username !== actorUsername) {
      throw new MockApiError("forbidden", "Only the author can delete", 403);
    }
    this.posts = this.posts.filter((p) => p.id !== postId);
  }

  /** Idempotent like/save toggles (MI-18 optimistic semantics). */
  setEngagement(
    postId: string,
    viewerUsername: string,
    kind: "like" | "save",
    on: boolean,
  ): void {
    const post = this.posts.find((p) => p.id === postId);
    if (!post) throw new MockApiError("not_found", "Post not found", 404);
    const viewer = this.accountByUsername(viewerUsername);
    const set = kind === "like" ? this.likes : this.saves;
    const key = `${viewer.id}:${postId}`;
    const had = set.has(key);
    if (on && !had) {
      set.add(key);
      if (kind === "like") post.like_count += 1;
    } else if (!on && had) {
      set.delete(key);
      if (kind === "like") post.like_count -= 1;
    }
  }

  commentsFor(postId: string): Comment[] {
    if (!this.posts.some((p) => p.id === postId)) {
      throw new MockApiError("not_found", "Post not found", 404);
    }
    return deepClone(
      this.comments
        .filter((c) => c.post_id === postId && !c.hidden_by_moderation)
        .sort(
          (a, b) =>
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
        ),
    );
  }

  addComment(postId: string, authorUsername: string, body: string): Comment {
    const post = this.posts.find((p) => p.id === postId);
    if (!post) throw new MockApiError("not_found", "Post not found", 404);
    if (!body || body.length > 500) {
      throw new MockApiError(
        "validation_failed",
        "Comment body must be 1-500 characters",
        422,
      );
    }
    const author = this.accountByUsername(authorUsername);
    const comment: Comment = {
      id: id("cmt"),
      post_id: postId,
      author: {
        id: author.id,
        username: author.username,
        avatar_url: author.avatar_url,
      },
      body,
      like_count: 0,
      liked: false,
      hidden_by_moderation: false,
      created_at: new Date().toISOString(),
    };
    this.comments.push(comment);
    post.comment_count += 1;
    return deepClone(comment);
  }

  // -- profiles & social lists (pages.md B6/B2 — mock-ahead-of-contract) ----

  private summaryOf(account: Account, viewer: Account): UserSummary {
    const designer = this.designerByUsername(account.username);
    return {
      username: account.username,
      display_name: account.display_name,
      avatar_url: account.avatar_url,
      verified: designer?.verified ?? false,
      is_designer: designer !== undefined,
      meta: designer ? designer.bio.split(/[.·]/)[0].trim() : null,
      viewer_follows:
        designer !== undefined &&
        this.follows.has(`${viewer.id}:${account.username}`),
    };
  }

  profileFor(username: string, viewerUsername: string): PublicProfile {
    const viewer = this.accountByUsername(viewerUsername);
    const designer = this.designerByUsername(username);
    if (designer) {
      return {
        kind: "designer",
        designer: deepClone(designer),
        viewer_follows: this.follows.has(`${viewer.id}:${username}`),
        viewer_is_self: viewer.username === username,
      };
    }
    const account = this.accountByUsername(username);
    return {
      kind: "user",
      account: {
        username: account.username,
        display_name: account.display_name,
        avatar_url: account.avatar_url,
      },
      viewer_is_self: viewer.username === username,
    };
  }

  postsBy(username: string, viewerUsername: string): Post[] {
    const viewer = this.accountByUsername(viewerUsername);
    return this.posts
      .filter((p) => p.designer.username === username)
      .sort(
        (a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
      )
      .map((p) => this.viewPost(p, viewer.id));
  }

  savedPosts(viewerUsername: string): Post[] {
    const viewer = this.accountByUsername(viewerUsername);
    return this.posts
      .filter((p) => this.saves.has(`${viewer.id}:${p.id}`))
      .map((p) => this.viewPost(p, viewer.id));
  }

  followersOf(designerUsername: string, viewerUsername: string): UserSummary[] {
    if (!this.designerByUsername(designerUsername)) {
      throw new MockApiError("not_found", "Designer not found", 404);
    }
    const viewer = this.accountByUsername(viewerUsername);
    return this.accounts
      .filter((a) => this.follows.has(`${a.id}:${designerUsername}`))
      .map((a) => this.summaryOf(a, viewer));
  }

  followingOf(username: string, viewerUsername: string): UserSummary[] {
    const subject = this.accountByUsername(username);
    const viewer = this.accountByUsername(viewerUsername);
    return [...this.follows]
      .filter((k) => k.startsWith(`${subject.id}:`))
      .map((k) => k.split(":")[1])
      .map((designerUsername) => {
        const account = this.accounts.find(
          (a) => a.username === designerUsername,
        );
        return account ? this.summaryOf(account, viewer) : null;
      })
      .filter((row): row is UserSummary => row !== null);
  }

  suggestedDesigners(viewerUsername: string): UserSummary[] {
    const viewer = this.accountByUsername(viewerUsername);
    return this.designers
      .filter(
        (d) =>
          d.username !== viewer.username &&
          !this.follows.has(`${viewer.id}:${d.username}`),
      )
      .map((d) => this.summaryOf(this.accountByUsername(d.username), viewer));
  }

  searchDesigners(q: string, viewerUsername: string): UserSummary[] {
    const viewer = this.accountByUsername(viewerUsername);
    const needle = q.toLowerCase();
    return this.designers
      .filter(
        (d) =>
          d.username.includes(needle) ||
          d.display_name.toLowerCase().includes(needle) ||
          d.bio.toLowerCase().includes(needle),
      )
      .map((d) => this.summaryOf(this.accountByUsername(d.username), viewer));
  }

  setFollow(
    viewerUsername: string,
    designerUsername: string,
    on: boolean,
  ): void {
    const viewer = this.accountByUsername(viewerUsername);
    if (!this.designerByUsername(designerUsername)) {
      throw new MockApiError("not_found", "Designer not found", 404);
    }
    const key = `${viewer.id}:${designerUsername}`;
    const had = this.follows.has(key);
    if (on) this.follows.add(key);
    else this.follows.delete(key);
    // followers_count mirrors the follow list exactly (P1 realism pass —
    // the profile header and the followers sheet must never disagree).
    if (had !== on) {
      const designer = this.designerByUsername(designerUsername)!;
      designer.followers_count += on ? 1 : -1;
    }
  }

  // -- vault ----------------------------------------------------------------

  sessionsFor(username: string): MeasurementSession[] {
    const account = this.accountByUsername(username);
    return deepClone(
      this.sessions
        .filter((s) => s.customer_id === account.id)
        .sort(
          (a, b) =>
            new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
        ),
    );
  }

  createManualSession(
    username: string,
    input: {
      measurements: { name: string; value_cm: number }[];
    },
  ): MeasurementSession {
    const account = this.accountByUsername(username);
    if (!input.measurements || input.measurements.length === 0) {
      throw new MockApiError(
        "validation_failed",
        "At least one measurement is required",
        422,
      );
    }
    const sessionId = id("sess");
    const session: MeasurementSession = {
      id: sessionId,
      customer_id: account.id,
      method: "manual",
      // Manual sessions carry no height (flows/vault.md §2; data-model.md
      // §2: input_height_cm nullable — null for method: manual).
      input_height_cm: null,
      status: "complete",
      measurements: input.measurements.map((m, i) => ({
        id: `${sessionId}-m${i}`,
        session_id: sessionId,
        name: m.name,
        value_cm: m.value_cm,
        source: "pipeline",
        confidence: null,
      })),
      pipeline_meta: {},
      created_at: new Date().toISOString(),
    };
    this.sessions.unshift(session);
    return deepClone(session);
  }

  /**
   * Two-photo upload path (B4, M-10/M-12): multipart image_front +
   * image_side + height → per-pose QC → pending_save session with
   * per-measurement confidence (api.md §2 v2 schema). QC failures are
   * reproduced when a pose's file name contains a QC code (designated
   * fixtures); multiple codes report the FIRST by the contract table
   * order (capture-qc.md §2), the front pose first — a pose-2 failure
   * never discards the accepted pose 1 (the 422 names the failing pose).
   */
  createCaptureSession(
    username: string,
    input: {
      input_height_cm: number;
      filenameFront: string;
      filenameSide: string;
    },
  ): MeasurementSession {
    const account = this.accountByUsername(username);
    if (
      !Number.isFinite(input.input_height_cm) ||
      input.input_height_cm < 100 ||
      input.input_height_cm > 230
    ) {
      throw new MockApiError(
        "validation_failed",
        "Height must be 100-230 cm",
        422,
      );
    }
    const poses: [
      pose: "front" | "side",
      name: string,
      table: [string, string][],
    ][] = [
      ["front", input.filenameFront.toLowerCase(), QC_ORDER_FRONT],
      ["side", input.filenameSide.toLowerCase(), QC_ORDER_SIDE],
    ];
    for (const [pose, name, table] of poses) {
      for (const [code, guidance] of table) {
        if (name.includes(code)) {
          throw new MockApiError(code, guidance, 422, { guidance, pose });
        }
      }
    }
    const sessionId = id("sess");
    const scale = input.input_height_cm / 168;
    const seededResults: [string, number, number][] = [
      ["shoulder_width", 42.7, 0.93],
      ["hip_width", 36.9, 0.9],
      ["chest_girth", 91.2, 0.74],
      ["waist_girth", 78.1, 0.68], // low-confidence chip renders from seed
    ];
    const session: MeasurementSession = {
      id: sessionId,
      customer_id: account.id,
      method: "mediapipe_2d_v2",
      input_height_cm: input.input_height_cm,
      status: "pending_save",
      measurements: seededResults.map(([mName, value, confidence], i) => ({
        id: `${sessionId}-m${i}`,
        session_id: sessionId,
        name: mName,
        value_cm: Math.round(value * scale * 10) / 10,
        source: "pipeline",
        confidence,
      })),
      pipeline_meta: { model_version: "mp2d-v2.3", qc: "pass" },
      created_at: new Date().toISOString(),
    };
    this.sessions.unshift(session);
    return deepClone(session);
  }

  /** "Save to vault" — flips pending_save → complete (flows/vault.md §1). */
  saveSession(sessionId: string, username: string): MeasurementSession {
    const account = this.accountByUsername(username);
    const session = this.sessions.find(
      (s) => s.id === sessionId && s.customer_id === account.id,
    );
    if (!session) throw new MockApiError("not_found", "Session not found", 404);
    if (session.status !== "pending_save") {
      throw new MockApiError(
        "invalid_transition",
        "Only unsaved capture results can be saved",
        409,
      );
    }
    session.status = "complete";
    return deepClone(session);
  }

  /**
   * PLAT-004 / F2-9 export — pdf or csv per the api.md contract; the mock
   * returns an inline data URL where the backend will return a signed URL.
   */
  sessionExport(
    sessionId: string,
    username: string,
    format: "csv" | "pdf",
  ): { url: string; format: string } {
    const session = this.session(sessionId, username);
    if (format === "pdf") {
      const pdf = minimalPdf([
        "Apparule — measurement session export",
        `Session ${session.id} · method ${session.method}`,
        `Captured ${new Date(session.created_at).toDateString()}`,
        "",
        ...session.measurements.map(
          (m) =>
            `${m.name}: ${m.value_cm} cm (${m.source}` +
            `${m.confidence !== null ? `, confidence ${m.confidence}` : ""})`,
        ),
      ]);
      return {
        url: `data:application/pdf;base64,${pdf.toString("base64")}`,
        format,
      };
    }
    const rows = [
      "name,value_cm,source,confidence",
      ...session.measurements.map(
        (m) => `${m.name},${m.value_cm},${m.source},${m.confidence ?? ""}`,
      ),
    ].join("\n");
    return {
      url: `data:text/csv;base64,${Buffer.from(rows, "utf8").toString("base64")}`,
      format,
    };
  }

  session(sessionId: string, username: string): MeasurementSession {
    const account = this.accountByUsername(username);
    const session = this.sessions.find(
      (s) => s.id === sessionId && s.customer_id === account.id,
    );
    // cross-tenant access reads as not_found, never 403 (openapi.yaml)
    if (!session) throw new MockApiError("not_found", "Session not found", 404);
    return deepClone(session);
  }

  appendCorrections(
    sessionId: string,
    username: string,
    corrections: { name: string; value_cm: number }[],
  ): MeasurementSession {
    const account = this.accountByUsername(username);
    const session = this.sessions.find(
      (s) => s.id === sessionId && s.customer_id === account.id,
    );
    if (!session) throw new MockApiError("not_found", "Session not found", 404);
    for (const c of corrections) {
      session.measurements.push({
        id: id("m"),
        session_id: sessionId,
        name: c.name,
        value_cm: c.value_cm,
        source: "manual_correction",
        confidence: null,
      });
    }
    return deepClone(session);
  }

  deleteSession(sessionId: string, username: string): void {
    const account = this.accountByUsername(username);
    const exists = this.sessions.some(
      (s) => s.id === sessionId && s.customer_id === account.id,
    );
    if (!exists) throw new MockApiError("not_found", "Session not found", 404);
    this.sessions = this.sessions.filter((s) => s.id !== sessionId);
  }

  // -- orders ---------------------------------------------------------------

  ordersFor(
    username: string,
    role: "customer" | "designer",
  ): CommissionRequest[] {
    const account = this.accountByUsername(username);
    const designer = this.designerByUsername(username);
    return deepClone(
      this.orders
        .filter((o) =>
          role === "customer"
            ? o.customer.id === account.id
            : designer !== undefined && o.designer.id === designer.id,
        )
        .sort(
          (a, b) =>
            new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
        ),
    );
  }

  order(orderId: string, username: string): CommissionRequest {
    const account = this.accountByUsername(username);
    const designer = this.designerByUsername(username);
    const order = this.orders.find(
      (o) =>
        o.id === orderId &&
        (o.customer.id === account.id ||
          (designer !== undefined && o.designer.id === designer.id)),
    );
    // party-only; others get 404 (openapi.yaml)
    if (!order) throw new MockApiError("not_found", "Order not found", 404);
    return deepClone(order);
  }

  createRequest(
    customerUsername: string,
    postId: string,
    input: {
      session_id: string;
      notes?: string;
      budget_cents?: number;
      target_date?: string;
      delivery: CommissionRequest["delivery"];
    },
  ): CommissionRequest {
    const customer = this.accountByUsername(customerUsername);
    const post = this.posts.find((p) => p.id === postId);
    if (!post) throw new MockApiError("not_found", "Post not found", 404);
    // A-2 gate: posts of non-KYC (or KYC-lapsed) designers don't accept
    // requests (flows/designer.md §1).
    const postDesigner = this.designerByUsername(post.designer.username);
    if (!postDesigner || postDesigner.payout_account.kyc_state !== "verified") {
      throw new MockApiError(
        "post_unavailable",
        "This outfit is no longer available",
        409,
      );
    }
    const session = this.sessions.find(
      (s) => s.id === input.session_id && s.customer_id === customer.id,
    );
    if (!session || session.status !== "complete") {
      throw new MockApiError(
        "snapshot_invalid",
        "The selected measurement session is not usable",
        422,
      );
    }
    const openStates: OrderStatus[] = [
      "requested",
      "quoted",
      "paid",
      "in_progress",
      "shipped",
      "disputed",
    ];
    const open = this.orders.filter(
      (o) => o.customer.id === customer.id && openStates.includes(o.status),
    );
    if (open.some((o) => o.post.id === postId)) {
      throw new MockApiError(
        "duplicate_request",
        "You already have an open request for this outfit",
        409,
      );
    }
    if (open.length >= 10) {
      throw new MockApiError(
        "rate_limited",
        "You have too many open requests",
        429,
      );
    }
    const requiredDelivery: (keyof CommissionRequest["delivery"])[] = [
      "recipient_name",
      "phone",
      "line1",
      "city",
      "state",
      "country",
    ];
    if (!input.delivery || requiredDelivery.some((k) => !input.delivery[k])) {
      throw new MockApiError(
        "validation_failed",
        "Delivery address is incomplete",
        422,
      );
    }
    const orderId = id("req");
    const now = new Date().toISOString();
    const order: CommissionRequest = {
      id: orderId,
      order_number: `APR-${this.orderCounter++}`,
      post: {
        id: post.id,
        caption: post.caption,
        thumb_url: post.media[0]?.url ?? "",
      },
      customer: {
        id: customer.id,
        username: customer.username,
        avatar_url: customer.avatar_url,
      },
      designer: {
        id: post.designer.id,
        username: post.designer.username,
        avatar_url: post.designer.avatar_url,
      },
      status: "requested",
      notes: input.notes ?? "",
      budget_cents: input.budget_cents ?? null,
      quote_cents: null,
      currency: "NGN",
      due_at: null,
      target_date: input.target_date ?? null,
      tracking: null,
      decline_reason: null,
      dispute: null,
      delivery: input.delivery,
      snapshot: {
        id: id("snap"),
        request_id: orderId,
        values: {
          method: session.method,
          measured_at: session.created_at,
          // frozen copy — vault changes never mutate an order
          measurements: session.measurements.map((m) => ({
            name: m.name,
            value_cm: m.value_cm,
          })),
        },
        created_at: now,
      },
      events: [
        {
          id: id("evt"),
          request_id: orderId,
          kind: "requested",
          actor: "customer",
          created_at: now,
        },
      ],
      payment: null,
      created_at: now,
    };
    this.orders.unshift(order);
    this.notify({
      account_id: order.designer.id,
      kind: "status_change",
      payload_ref: order.id,
      text: `${customer.username} requested ${post.caption.split(" — ")[0]} (#${order.order_number})`,
      actor: { username: customer.username, avatar_url: customer.avatar_url },
      thumb_url: order.post.thumb_url,
    });
    return deepClone(order);
  }

  /** Customer withdraws (requested) or rejects the quote (quoted). */
  cancel(orderId: string, customerUsername: string): CommissionRequest {
    const order = this.orderAsCustomer(orderId, customerUsername);
    this.transition(order, "cancelled", "customer");
    this.notify({
      account_id: order.designer.id,
      kind: "status_change",
      payload_ref: order.id,
      text: `${order.customer.username} cancelled request #${order.order_number}`,
      actor: { username: order.customer.username, avatar_url: null },
      thumb_url: order.post.thumb_url,
    });
    return deepClone(order);
  }

  private transition(
    order: CommissionRequest,
    to: OrderStatus,
    actor: "customer" | "designer" | "system",
  ): void {
    if (!canTransition(order.status, to)) {
      throw new MockApiError(
        "invalid_transition",
        `Cannot move an order from ${order.status} to ${to}`,
        409,
      );
    }
    order.status = to;
    order.events.push({
      id: id("evt"),
      request_id: order.id,
      kind: to,
      actor,
      created_at: new Date().toISOString(),
    });
  }

  private orderAsDesigner(
    orderId: string,
    username: string,
  ): CommissionRequest {
    const designer = this.designerByUsername(username);
    const order = this.orders.find((o) => o.id === orderId);
    if (!order || !designer || order.designer.id !== designer.id) {
      throw new MockApiError("not_found", "Order not found", 404);
    }
    return order;
  }

  private orderAsCustomer(
    orderId: string,
    username: string,
  ): CommissionRequest {
    const account = this.accountByUsername(username);
    const order = this.orders.find(
      (o) => o.id === orderId && o.customer.id === account.id,
    );
    if (!order) throw new MockApiError("not_found", "Order not found", 404);
    return order;
  }

  quote(
    orderId: string,
    designerUsername: string,
    quoteCents: number,
    dueAt: string,
  ): CommissionRequest {
    const order = this.orderAsDesigner(orderId, designerUsername);
    if (!Number.isInteger(quoteCents) || quoteCents <= 0) {
      throw new MockApiError(
        "validation_failed",
        "quote_cents must be a positive integer",
        422,
      );
    }
    if (order.status !== "quoted") {
      // Requote is allowed while `quoted` — replaces the quote without a
      // transition (flows/designer.md §2); otherwise requested → quoted.
      this.transition(order, "quoted", "designer");
    }
    order.quote_cents = quoteCents;
    order.due_at = dueAt;
    this.notify({
      account_id: order.customer.id,
      kind: "quote",
      payload_ref: order.id,
      text: `${order.designer.username} quoted your request #${order.order_number}`,
      actor: { username: order.designer.username, avatar_url: null },
      thumb_url: order.post.thumb_url,
    });
    return deepClone(order);
  }

  decline(
    orderId: string,
    designerUsername: string,
    reason: DeclineReason,
  ): CommissionRequest {
    const order = this.orderAsDesigner(orderId, designerUsername);
    if (!reason) {
      throw new MockApiError(
        "validation_failed",
        "Decline reason is required",
        422,
      );
    }
    this.transition(order, "declined", "designer");
    order.decline_reason = reason;
    this.notify({
      account_id: order.customer.id,
      kind: "status_change",
      payload_ref: order.id,
      text: `${order.designer.username} declined request #${order.order_number}`,
      actor: { username: order.designer.username, avatar_url: null },
      thumb_url: order.post.thumb_url,
    });
    return deepClone(order);
  }

  setStatus(
    orderId: string,
    designerUsername: string,
    status: "in_progress" | "shipped",
    tracking?: string,
  ): CommissionRequest {
    const order = this.orderAsDesigner(orderId, designerUsername);
    this.transition(order, status, "designer");
    if (status === "shipped" && tracking) order.tracking = tracking;
    this.notify({
      account_id: order.customer.id,
      kind: "status_change",
      payload_ref: order.id,
      text:
        status === "in_progress"
          ? `${order.designer.username} started work on your order #${order.order_number}`
          : `Order #${order.order_number} shipped${tracking ? ` — ${tracking}` : ""}`,
      actor: { username: order.designer.username, avatar_url: null },
      thumb_url: order.post.thumb_url,
    });
    return deepClone(order);
  }

  pay(orderId: string, customerUsername: string): CommissionRequest {
    const order = this.orderAsCustomer(orderId, customerUsername);
    if (order.quote_cents === null) {
      throw new MockApiError("invalid_transition", "Order has no quote", 409);
    }
    this.transition(order, "paid", "customer");
    // charge.success lands directly in held (Paystack capture model)
    order.payment = {
      id: id("pay"),
      request_id: order.id,
      provider: "paystack",
      state: "held",
      currency: order.currency,
      amount_cents: order.quote_cents,
      platform_fee_cents: Math.round(order.quote_cents * 0.1), // 10% (A-1)
    };
    return deepClone(order);
  }

  confirmDelivery(
    orderId: string,
    customerUsername: string,
  ): CommissionRequest {
    const order = this.orderAsCustomer(orderId, customerUsername);
    this.transition(order, "delivered", "customer");
    if (order.payment) order.payment.state = "released";
    this.notify({
      account_id: order.designer.id,
      kind: "payout",
      payload_ref: order.id,
      text: `Payout released for order #${order.order_number}`,
      actor: { username: order.customer.username, avatar_url: null },
      thumb_url: order.post.thumb_url,
    });
    return deepClone(order);
  }

  dispute(
    orderId: string,
    username: string,
    reason: DisputeReason,
    detail?: string,
  ): CommissionRequest {
    // either party (order-lifecycle §2)
    const account = this.accountByUsername(username);
    const designer = this.designerByUsername(username);
    const order = this.orders.find(
      (o) =>
        o.id === orderId &&
        (o.customer.id === account.id ||
          (designer !== undefined && o.designer.id === designer.id)),
    );
    if (!order) throw new MockApiError("not_found", "Order not found", 404);
    this.transition(
      order,
      "disputed",
      order.customer.id === account.id ? "customer" : "designer",
    );
    order.dispute = { reason, detail: detail ?? null };
    return deepClone(order);
  }

  messagesFor(orderId: string, username: string): ThreadMessage[] {
    this.order(orderId, username); // party check
    return deepClone(
      this.messages
        .filter((m) => m.request_id === orderId)
        .sort(
          (a, b) =>
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
        ),
    );
  }

  addMessage(
    orderId: string,
    username: string,
    body: string,
    imageUrl: string | null,
  ): ThreadMessage {
    this.order(orderId, username); // party check
    if (!body || body.length > 1000) {
      throw new MockApiError(
        "validation_failed",
        "Message body must be 1-1000 characters",
        422,
      );
    }
    const account = this.accountByUsername(username);
    const designer = this.designerByUsername(username);
    const order = this.orders.find((o) => o.id === orderId)!;
    const authorIsDesigner =
      designer !== undefined && order.designer.id === designer.id;
    const message: ThreadMessage = {
      id: id("msg"),
      request_id: orderId,
      author_id: authorIsDesigner ? designer.id : account.id,
      body,
      image_url: imageUrl,
      created_at: new Date().toISOString(),
    };
    this.messages.push(message);
    // Scripted counterparty reply (once per thread) — gives the MI-17
    // "responding…" indicator a real payoff in TEST_MODE.
    if (!authorIsDesigner && !this.autoReplied.has(orderId)) {
      this.autoReplied.add(orderId);
      this.messages.push({
        id: id("msg"),
        request_id: orderId,
        author_id: order.designer.id,
        body: "Got it — thanks! I'll take a look and reply properly shortly.",
        image_url: null,
        created_at: new Date(Date.now() + 1).toISOString(),
      });
    }
    return deepClone(message);
  }

  // -- notifications --------------------------------------------------------

  notificationsFor(username: string): Notification[] {
    const account = this.accountByUsername(username);
    return deepClone(
      this.notifications
        .filter(
          (n) =>
            n.account_id === account.id ||
            n.account_id === this.designerByUsername(username)?.id,
        )
        .sort(
          (a, b) =>
            new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
        ),
    );
  }

  markNotificationsRead(username: string, ids?: string[]): void {
    const account = this.accountByUsername(username);
    const designerId = this.designerByUsername(username)?.id;
    const now = new Date().toISOString();
    for (const n of this.notifications) {
      const mine = n.account_id === account.id || n.account_id === designerId;
      if (mine && (!ids || ids.includes(n.id)) && n.read_at === null) {
        n.read_at = now;
      }
    }
  }

  // -- designer & earnings --------------------------------------------------

  enableDesigner(
    username: string,
    displayName: string,
    bio?: string,
  ): DesignerProfile {
    const account = this.accountByUsername(username);
    let designer = this.designerByUsername(username);
    if (!designer) {
      designer = {
        id: id("des"),
        account_id: account.id,
        username: account.username,
        display_name: displayName,
        bio: bio ?? "",
        avatar_url: account.avatar_url,
        payout_account: {
          provider_ref: null,
          bank_name: null,
          account_last4: null,
          kyc_state: "pending",
        },
        verified: false,
        location: account.profile_location,
        followers_count: 0,
        following_count: 0,
        posts_count: 0,
      };
      this.designers.push(designer);
    }
    account.designer.enabled = true;
    return deepClone(designer);
  }

  /**
   * Paystack account resolution (pages.md B8 scripted states): a 10-digit
   * number resolves to the holder's registered name; numbers starting "00"
   * reproduce the mismatch/unresolvable path deterministically.
   */
  resolveBank(
    username: string,
    bankCode: string,
    accountNumber: string,
  ): BankResolution {
    const account = this.accountByUsername(username);
    if (!bankCode) {
      throw new MockApiError("validation_failed", "Pick your bank", 422);
    }
    if (!/^\d{10}$/.test(accountNumber) || accountNumber.startsWith("00")) {
      throw new MockApiError(
        "bank_resolution_failed",
        "Could not resolve that account number",
        422,
      );
    }
    return {
      account_name: account.display_name.toUpperCase(),
      bank_code: bankCode,
      account_number: accountNumber,
    };
  }

  attachPayoutAccount(
    username: string,
    bankCode: string,
    accountNumber: string,
  ): DesignerProfile["payout_account"] {
    const account = this.accountByUsername(username);
    const designer = this.designerByUsername(username);
    if (!designer) {
      throw new MockApiError(
        "designer_profile_required",
        "Enable a designer profile first",
        403,
      );
    }
    // Same deterministic failure script as resolveBank.
    this.resolveBank(username, bankCode, accountNumber);
    // Designated fixture: 9999999999 attaches, then the provider invalidates
    // it — reproduces the KYC-lapse banner state (flows/designer.md §1).
    const lapsed = accountNumber === "9999999999";
    designer.payout_account = {
      provider_ref: `PSTK-RCP-${accountNumber.slice(-5)}`,
      bank_name: BANK_NAMES[bankCode] ?? bankCode,
      account_last4: accountNumber.slice(-4),
      kyc_state: lapsed ? "lapsed" : "verified",
    };
    account.designer.kyc_complete = !lapsed;
    return deepClone(designer.payout_account);
  }

  earnings(username: string): Earnings {
    const designer = this.designerByUsername(username);
    if (!designer) {
      throw new MockApiError(
        "designer_profile_required",
        "Earnings are available to designer profiles only",
        403,
      );
    }
    const transactions: EarningsEntry[] = [];
    let balance = 0;
    let pending = 0;
    for (const order of this.orders) {
      if (order.designer.id !== designer.id || !order.payment) continue;
      const net = order.payment.amount_cents - order.payment.platform_fee_cents;
      if (order.payment.state === "held") {
        pending += net;
        transactions.push({
          id: `txn-held-${order.id}`,
          kind: "escrow_held",
          amount_cents: net,
          currency: order.currency,
          order_number: `#${order.order_number}`,
          provider_ref: null,
          created_at:
            order.events.find((e) => e.kind === "paid")?.created_at ??
            order.created_at,
        });
      } else if (order.payment.state === "released") {
        balance += net;
        const deliveredAt =
          order.events.find((e) => e.kind === "delivered")?.created_at ??
          order.created_at;
        transactions.push({
          id: `txn-payout-${order.id}`,
          kind: "payout",
          amount_cents: net,
          currency: order.currency,
          order_number: `#${order.order_number}`,
          provider_ref: `PSTK-TRF-${order.order_number}`,
          created_at: deliveredAt,
        });
        transactions.push({
          id: `txn-fee-${order.id}`,
          kind: "fee_line",
          amount_cents: -order.payment.platform_fee_cents,
          currency: order.currency,
          order_number: `#${order.order_number}`,
          provider_ref: null,
          created_at: deliveredAt,
        });
      }
    }
    transactions.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    );
    return {
      balance_cents: balance,
      pending_cents: pending,
      currency: "NGN",
      transactions,
    };
  }

  // -- trust & safety -------------------------------------------------------

  fileReport(
    reporterUsername: string,
    subjectKind: ReportSubjectKind,
    subjectId: string,
    reason: ReportReason,
    detail?: string,
  ): Report {
    const reporter = this.accountByUsername(reporterUsername);
    const post = this.posts.find((p) => p.id === subjectId);
    const comment = this.comments.find((c) => c.id === subjectId);
    const report: Report = {
      id: id("rep"),
      reporter: { id: reporter.id, username: reporter.username },
      subject_kind: subjectKind,
      subject_id: subjectId,
      subject_preview: {
        text: post?.caption ?? comment?.body ?? subjectId,
        thumb_url: post?.media[0]?.url ?? null,
        author_username:
          post?.designer.username ?? comment?.author.username ?? null,
      },
      reason,
      detail: detail ?? null,
      status: "open",
      action: null,
      actioned_by: null,
      actioned_at: null,
      created_at: new Date().toISOString(),
    };
    this.reports.unshift(report);
    return deepClone(report);
  }

  setBlock(
    blockerUsername: string,
    blockedUsername: string,
    on: boolean,
  ): void {
    const blocker = this.accountByUsername(blockerUsername);
    const blocked = this.accountByUsername(blockedUsername);
    const key = `${blocker.id}:${blocked.id}`;
    if (on) this.blocks.add(key);
    else this.blocks.delete(key);
  }

  /** B7a is staff-only (pages.md) — non-staff read as forbidden. */
  private requireStaff(username: string): Account {
    const account = this.accountByUsername(username);
    if (!account.is_staff) {
      throw new MockApiError("forbidden", "Moderation is staff-only", 403);
    }
    return account;
  }

  moderationQueue(moderatorUsername: string): Report[] {
    this.requireStaff(moderatorUsername);
    // Open reports lead; actioned rows stay listed as the audit trail
    // (canvas narrative — the queue shows what moderation did, not just
    // what's pending). Dismissed reports leave the queue.
    return deepClone([
      ...this.reports.filter((r) => r.status === "open"),
      ...this.reports.filter((r) => r.status === "actioned"),
    ]);
  }

  actOnReport(
    reportId: string,
    moderatorUsername: string,
    action: ModerationAction,
  ): Report {
    const moderator = this.requireStaff(moderatorUsername);
    const report = this.reports.find((r) => r.id === reportId);
    if (!report) throw new MockApiError("not_found", "Report not found", 404);
    if (action === "hide_post" && report.subject_kind === "post") {
      this.posts = this.posts.filter((p) => p.id !== report.subject_id);
    }
    if (action === "hide_post" && report.subject_kind === "comment") {
      const comment = this.comments.find((c) => c.id === report.subject_id);
      if (comment) comment.hidden_by_moderation = true;
    }
    report.status = action === "dismiss" ? "dismissed" : "actioned";
    report.action = action;
    report.actioned_by = { id: moderator.id, username: moderator.username };
    report.actioned_at = new Date().toISOString();
    return deepClone(report);
  }

  // -- media (composer uploads — stands in for object storage) --------------

  uploadMedia(data: string, contentType: string): { id: string; url: string } {
    const mediaId = id("med");
    this.media.set(mediaId, { data, contentType });
    return { id: mediaId, url: `/api/mock/v1/media/${mediaId}` };
  }

  getMedia(mediaId: string): { data: string; contentType: string } {
    const item = this.media.get(mediaId);
    if (!item) throw new MockApiError("not_found", "Media not found", 404);
    return item;
  }

  // -- consent ----------------------------------------------------------------

  consentFor(username: string) {
    return deepClone(this.accountByUsername(username).consent);
  }

  recordConsent(
    username: string,
    document: "tos" | "privacy",
    version: string,
  ) {
    const account = this.accountByUsername(username);
    const record = {
      document,
      version,
      accepted_at: new Date().toISOString(),
    };
    account.consent = [
      ...account.consent.filter((c) => c.document !== document),
      record,
    ];
    return deepClone(record);
  }
}

// Module singleton, dev-persistent across HMR reloads.
const globalKey = Symbol.for("apparule.mock-store");
type GlobalWithStore = typeof globalThis & { [globalKey]?: MockStore };

export function getStore(): MockStore {
  const g = globalThis as GlobalWithStore;
  if (!g[globalKey]) {
    g[globalKey] = new MockStore();
  }
  return g[globalKey];
}

/** Test hook: reset to the seeded state. */
export function resetStore(): MockStore {
  const g = globalThis as GlobalWithStore;
  g[globalKey] = new MockStore();
  return g[globalKey];
}

// Re-exported so tests can assert against seed freshness helpers.
export { daysAgo };
