// In-memory mock store — seeded with the canonical narrative, full CRUD,
// order-lifecycle transition rules, and snake_case error codes from the docs
// taxonomy. Module singleton (globalThis) so state is dev-persistent across
// HMR and shared by all route handlers.
import type {
  Account,
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
  OrderStatus,
  Post,
  Report,
  ReportReason,
  ReportSubjectKind,
  ThreadMessage,
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
} from "./seed";

const USERNAME_RE = /^[a-z0-9._]{3,30}$/;

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
  likes = new Set<string>();
  saves = new Set<string>();
  /** `${followerAccountId}:${designerUsername}` */
  follows = new Set<string>(seedFollows.map(([a, d]) => `${a}:${d}`));
  blocks = new Set<string>();
  /** Idempotency replay cache: key → serialized response (api.md §4). */
  idempotency = new Map<string, { payloadHash: string; response: unknown }>();
  orderCounter = 1059;

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
    patch: Partial<Pick<Account, "username" | "display_name" | "profile_location">>,
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
    if (patch.display_name !== undefined) account.display_name = patch.display_name;
    if (patch.profile_location !== undefined) {
      account.profile_location = patch.profile_location;
    }
    return deepClone(account);
  }

  // -- social ---------------------------------------------------------------

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
    return posts
      .sort(
        (a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
      )
      .map((p) => this.viewPost(p, viewer.id));
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
    if (!designer || !account.designer.enabled) {
      throw new MockApiError(
        "kyc_incomplete",
        "Enable a designer profile and complete KYC to post",
        403,
      );
    }
    if (!account.designer.kyc_complete) {
      throw new MockApiError("kyc_incomplete", "Complete KYC to post", 403);
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

  setFollow(viewerUsername: string, designerUsername: string, on: boolean): void {
    const viewer = this.accountByUsername(viewerUsername);
    if (!this.designerByUsername(designerUsername)) {
      throw new MockApiError("not_found", "Designer not found", 404);
    }
    const key = `${viewer.id}:${designerUsername}`;
    if (on) this.follows.add(key);
    else this.follows.delete(key);
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
      input_height_cm: number;
      measurements: { name: string; value_cm: number }[];
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
      input_height_cm: input.input_height_cm,
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

  ordersFor(username: string, role: "customer" | "designer"): CommissionRequest[] {
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
    if (
      !input.delivery ||
      requiredDelivery.some((k) => !input.delivery[k])
    ) {
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

  private orderAsDesigner(orderId: string, username: string): CommissionRequest {
    const designer = this.designerByUsername(username);
    const order = this.orders.find((o) => o.id === orderId);
    if (!order || !designer || order.designer.id !== designer.id) {
      throw new MockApiError("not_found", "Order not found", 404);
    }
    return order;
  }

  private orderAsCustomer(orderId: string, username: string): CommissionRequest {
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
      throw new MockApiError("validation_failed", "quote_cents must be a positive integer", 422);
    }
    this.transition(order, "quoted", "designer");
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
      throw new MockApiError("validation_failed", "Decline reason is required", 422);
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

  confirmDelivery(orderId: string, customerUsername: string): CommissionRequest {
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
    const message: ThreadMessage = {
      id: id("msg"),
      request_id: orderId,
      author_id:
        designer && this.orders.find((o) => o.id === orderId)?.designer.id === designer.id
          ? designer.id
          : account.id,
      body,
      image_url: imageUrl,
      created_at: new Date().toISOString(),
    };
    this.messages.push(message);
    return deepClone(message);
  }

  // -- notifications --------------------------------------------------------

  notificationsFor(username: string): Notification[] {
    const account = this.accountByUsername(username);
    return deepClone(
      this.notifications
        .filter((n) => n.account_id === account.id || n.account_id === this.designerByUsername(username)?.id)
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

  enableDesigner(username: string, displayName: string, bio?: string): DesignerProfile {
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
    if (!/^\d{10}$/.test(accountNumber)) {
      // Paystack resolution mismatch path (pages.md B8)
      throw new MockApiError(
        "bank_resolution_failed",
        "Could not resolve that account number",
        422,
      );
    }
    designer.payout_account = {
      provider_ref: `PSTK-RCP-${accountNumber.slice(-5)}`,
      bank_name: bankCode,
      account_last4: accountNumber.slice(-4),
      kyc_state: "verified",
    };
    account.designer.kyc_complete = true;
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
          created_at: order.events.find((e) => e.kind === "paid")?.created_at ?? order.created_at,
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
      },
      reason,
      detail: detail ?? null,
      status: "open",
      actioned_by: null,
      created_at: new Date().toISOString(),
    };
    this.reports.unshift(report);
    return deepClone(report);
  }

  setBlock(blockerUsername: string, blockedUsername: string, on: boolean): void {
    const blocker = this.accountByUsername(blockerUsername);
    const blocked = this.accountByUsername(blockedUsername);
    const key = `${blocker.id}:${blocked.id}`;
    if (on) this.blocks.add(key);
    else this.blocks.delete(key);
  }

  moderationQueue(): Report[] {
    return deepClone(
      this.reports.filter((r) => r.status === "open"),
    );
  }

  actOnReport(
    reportId: string,
    moderatorUsername: string,
    action: ModerationAction,
  ): Report {
    const report = this.reports.find((r) => r.id === reportId);
    if (!report) throw new MockApiError("not_found", "Report not found", 404);
    const moderator = this.accountByUsername(moderatorUsername);
    if (action === "hide_post" && report.subject_kind === "post") {
      this.posts = this.posts.filter((p) => p.id !== report.subject_id);
    }
    if (action === "hide_post" && report.subject_kind === "comment") {
      const comment = this.comments.find((c) => c.id === report.subject_id);
      if (comment) comment.hidden_by_moderation = true;
    }
    report.status = action === "dismiss" ? "dismissed" : "actioned";
    report.actioned_by = moderator.id;
    return deepClone(report);
  }

  // -- consent ----------------------------------------------------------------

  consentFor(username: string) {
    return deepClone(this.accountByUsername(username).consent);
  }

  recordConsent(username: string, document: "tos" | "privacy", version: string) {
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
