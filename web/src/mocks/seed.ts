// Seed data — the canonical Figma narrative (docs/design.md §8.3 sourced
// photography; the mock narratives the designs boot with):
//   kiki.adeyemi (customer) · amara.designs / tunde.o / maisonbisi
//   (designers, Lagos) · eniola.stitches (designer, Abuja — the non-Lagos
//   contrast that makes the explore "near me" proximity ranking visible)
//   · orders #APR-1042 (ankara, ₦45,000, in_progress) and
//   #APR-1058 (little senator, ₦62,000, delivered/paid-out) · measurements
//   (shoulder 42.5 cm etc. with freshness) · feed posts referencing the
//   CC-licensed photos in web/public/demo (see ATTRIBUTIONS.md there).
import type {
  Account,
  Comment,
  CommissionRequest,
  DeclineReason,
  DesignerProfile,
  DisputeReason,
  MeasurementSession,
  Notification,
  OrderStatus,
  Post,
  Report,
} from "@/models";

export const NOW = () => new Date();

export function daysAgo(days: number, base: Date = NOW()): string {
  return new Date(base.getTime() - days * 24 * 60 * 60 * 1000).toISOString();
}

/**
 * N days ago, pinned to a plausible local time of day ("HH:mm"). daysAgo
 * alone stamps everything with the boot minute, so a multi-event order
 * timeline read as a synthetic same-minute cluster (PR #102 cadence rule:
 * timelines must read like days of real back-and-forth, not one batch
 * insert). Only used for whole-day offsets ≥ 1 — a pinned time on a
 * same-day offset could land in the future.
 */
function daysAgoAt(days: number, time: string, base: Date = NOW()): string {
  const d = new Date(base.getTime() - days * 24 * 60 * 60 * 1000);
  const [hours, minutes] = time.split(":").map(Number);
  d.setHours(hours, minutes, 0, 0);
  return d.toISOString();
}

function hoursAgo(hours: number): string {
  return new Date(NOW().getTime() - hours * 60 * 60 * 1000).toISOString();
}

function defaultPrefs() {
  return { quotes: true, order_status: true, social: true, payouts: true };
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

export const seedAccounts: Account[] = [
  {
    id: "acc-kiki",
    firebase_uid: "test-uid-kiki",
    email: "kiki.adeyemi@example.com",
    username: "kiki.adeyemi",
    display_name: "Kiki Adeyemi",
    avatar_url: null,
    profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    deletion_state: "active",
    designer: { enabled: false, kyc_complete: false },
    // The TEST_MODE user doubles as staff so the B7a moderation queue is
    // walkable from the seeded session (A-6).
    is_staff: true,
    notification_prefs: defaultPrefs(),
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(40) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(40) },
    ],
    created_at: daysAgo(120),
  },
  {
    id: "acc-amara",
    firebase_uid: "test-uid-amara",
    email: "amara@example.com",
    username: "amara.designs",
    display_name: "Amara Designs",
    avatar_url: null,
    profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    deletion_state: "active",
    designer: { enabled: true, kyc_complete: true },
    is_staff: false,
    notification_prefs: defaultPrefs(),
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(200) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(200) },
    ],
    created_at: daysAgo(300),
  },
  {
    id: "acc-tunde",
    firebase_uid: "test-uid-tunde",
    email: "tunde@example.com",
    username: "tunde.o",
    display_name: "Tunde Okonkwo",
    // Suggestion-rail avatars are real photos from the licensed pool
    // (audit 2026-07-20: initials-only reads as broken beside the canvas).
    // Each designer fronts their OWN published work — no new assets.
    avatar_url: "/demo/outfit-w15.jpg",
    profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    deletion_state: "active",
    designer: { enabled: true, kyc_complete: true },
    is_staff: false,
    notification_prefs: defaultPrefs(),
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(180) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(180) },
    ],
    created_at: daysAgo(250),
  },
  {
    id: "acc-bisi",
    firebase_uid: "test-uid-bisi",
    email: "bisi@example.com",
    username: "maisonbisi",
    display_name: "Maison Bisi",
    avatar_url: null,
    profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    deletion_state: "active",
    designer: { enabled: true, kyc_complete: true },
    is_staff: false,
    notification_prefs: defaultPrefs(),
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(220) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(220) },
    ],
    created_at: daysAgo(400),
  },
  {
    id: "acc-eniola",
    firebase_uid: "test-uid-eniola",
    email: "eniola@example.com",
    username: "eniola.stitches",
    display_name: "Eniola Stitches",
    avatar_url: "/demo/outfit-w10.jpg", // her own atelier post photo
    // The one non-Lagos designer: kiki (Lagos) ranks her LAST under the
    // explore "near me" proximity ordering — the visible contrast case.
    profile_location: { city: "Abuja", state: "FCT", country: "NG" },
    deletion_state: "active",
    designer: { enabled: true, kyc_complete: true },
    is_staff: false,
    notification_prefs: defaultPrefs(),
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(160) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(160) },
    ],
    created_at: daysAgo(160),
  },
  {
    // Platform moderator — the B7a audit-trail actor (the actioned queue
    // row reads "… by @mod.sarah"). Staff, not a designer; no social edges.
    id: "acc-sarah",
    firebase_uid: "test-uid-sarah",
    email: "sarah@apparule.example.com",
    username: "mod.sarah",
    display_name: "Sarah Bello",
    avatar_url: null,
    profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    deletion_state: "active",
    designer: { enabled: false, kyc_complete: false },
    is_staff: true,
    notification_prefs: defaultPrefs(),
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(320) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(320) },
    ],
    created_at: daysAgo(320),
  },
];

// Community members — the wider Lagos-scene audience around the four core
// personas: comment authors, follower rows, and fresh activity actors, so
// engagement reads as multiple real users at a plausible cadence.
function makeCommunityAccount(input: {
  id: string;
  username: string;
  displayName: string;
  city: string;
  state: string;
  joinedDaysAgo: number;
}): Account {
  return {
    id: input.id,
    firebase_uid: `test-uid-${input.id.replace("acc-", "")}`,
    email: `${input.username.replace(/\./g, "_")}@example.com`,
    username: input.username,
    display_name: input.displayName,
    avatar_url: null,
    profile_location: { city: input.city, state: input.state, country: "NG" },
    deletion_state: "active",
    designer: { enabled: false, kyc_complete: false },
    is_staff: false,
    notification_prefs: defaultPrefs(),
    consent: [
      {
        document: "tos",
        version: "1.0",
        accepted_at: daysAgo(input.joinedDaysAgo),
      },
      {
        document: "privacy",
        version: "1.0",
        accepted_at: daysAgo(input.joinedDaysAgo),
      },
    ],
    created_at: daysAgo(input.joinedDaysAgo),
  };
}

seedAccounts.push(
  makeCommunityAccount({
    id: "acc-ada",
    username: "ada.eze",
    displayName: "Ada Eze",
    city: "Lagos",
    state: "Lagos",
    joinedDaysAgo: 90,
  }),
  makeCommunityAccount({
    id: "acc-funmi",
    username: "funmi.b",
    displayName: "Funmi Balogun",
    city: "Lagos",
    state: "Lagos",
    joinedDaysAgo: 130,
  }),
  makeCommunityAccount({
    id: "acc-chidi",
    username: "chidi.n",
    displayName: "Chidi Nwosu",
    city: "Enugu",
    state: "Enugu",
    joinedDaysAgo: 75,
  }),
  makeCommunityAccount({
    id: "acc-zainab",
    username: "zainab.k",
    displayName: "Zainab Kassim",
    city: "Abuja",
    state: "FCT",
    joinedDaysAgo: 150,
  }),
  makeCommunityAccount({
    id: "acc-emeka",
    username: "emeka.u",
    displayName: "Emeka Udo",
    city: "Lagos",
    state: "Lagos",
    joinedDaysAgo: 210,
  }),
  makeCommunityAccount({
    id: "acc-tola",
    username: "tola.mak",
    displayName: "Tola Makinde",
    city: "Ibadan",
    state: "Oyo",
    joinedDaysAgo: 60,
  }),
);

export const seedDesigners: DesignerProfile[] = [
  {
    id: "des-amara",
    account_id: "acc-amara",
    username: "amara.designs",
    display_name: "Amara Designs",
    bio: "Ankara & contemporary tailoring. Lagos. Made-to-measure only.",
    avatar_url: null,
    payout_account: {
      provider_ref: "PSTK-RCP-88121",
      bank_name: "GTBank",
      account_last4: "4021",
      kyc_state: "verified",
    },
    verified: true,
    location: { city: "Lagos", state: "Lagos", country: "NG" },
    // Counts mirror the seeded graph exactly (P1 realism pass: the
    // followers sheet lists every follower, so count == list; posts_count
    // == the seeded grid).
    followers_count: 8,
    following_count: 2,
    posts_count: 3,
  },
  {
    id: "des-tunde",
    account_id: "acc-tunde",
    username: "tunde.o",
    display_name: "Tunde Okonkwo",
    bio: "Agbada, senator suits, and sharp menswear.",
    avatar_url: "/demo/outfit-w15.jpg", // mirrors acc-tunde — one identity
    payout_account: {
      provider_ref: "PSTK-RCP-77310",
      bank_name: "Access Bank",
      account_last4: "9930",
      kyc_state: "verified",
    },
    verified: true,
    location: { city: "Lagos", state: "Lagos", country: "NG" },
    followers_count: 4,
    following_count: 1,
    posts_count: 3,
  },
  {
    id: "des-bisi",
    account_id: "acc-bisi",
    username: "maisonbisi",
    display_name: "Maison Bisi",
    bio: "Aso-oke ceremonial wear — weddings, chieftaincy, statement pieces.",
    avatar_url: null,
    payout_account: {
      provider_ref: "PSTK-RCP-66104",
      bank_name: "Zenith Bank",
      account_last4: "1188",
      kyc_state: "verified",
    },
    verified: true,
    location: { city: "Lagos", state: "Lagos", country: "NG" },
    followers_count: 6,
    following_count: 1,
    posts_count: 4,
  },
  {
    id: "des-eniola",
    account_id: "acc-eniola",
    username: "eniola.stitches",
    display_name: "Eniola Stitches",
    bio: "Bespoke womenswear from the Abuja atelier — corporate and occasion.",
    avatar_url: "/demo/outfit-w10.jpg", // mirrors acc-eniola — one identity
    payout_account: {
      provider_ref: "PSTK-RCP-55492",
      bank_name: "UBA",
      account_last4: "7305",
      kyc_state: "verified",
    },
    verified: true,
    location: { city: "Abuja", state: "FCT", country: "NG" },
    followers_count: 1,
    following_count: 1,
    posts_count: 1,
  },
];

// ---------------------------------------------------------------------------
// Posts (photos from web/public/demo — attributions in ATTRIBUTIONS.md)
// ---------------------------------------------------------------------------

interface SeedPostInput {
  id: string;
  designerId: string;
  caption: string;
  tags: string[];
  priceCents: number | null;
  turnaround: number;
  media: { file: string; alt: string }[];
  likes: number;
  comments: number;
  createdDaysAgo: number;
}

const designerById = new Map(seedDesigners.map((d) => [d.id, d]));

function makePost(input: SeedPostInput): Post {
  const designer = designerById.get(input.designerId)!;
  return {
    id: input.id,
    designer: {
      id: designer.id,
      username: designer.username,
      display_name: designer.display_name,
      avatar_url: designer.avatar_url,
      verified: designer.verified,
    },
    caption: input.caption,
    style_tags: input.tags,
    base_price_cents: input.priceCents,
    currency: "NGN",
    turnaround_days: input.turnaround,
    media: input.media.map((m, i) => ({
      id: `${input.id}-m${i}`,
      post_id: input.id,
      url: `/demo/${m.file}`,
      position: i,
      alt_text: m.alt,
      width: 1024,
      height: 1280,
    })),
    like_count: input.likes,
    comment_count: input.comments,
    liked: false,
    saved: false,
    created_at: daysAgo(input.createdDaysAgo),
  };
}

export const seedPosts: Post[] = [
  makePost({
    // Newest post overall: explore's default recency order leads with the
    // Abuja atelier, and switching "near me" on visibly re-ranks it below
    // every Lagos designer for the Lagos-based test user.
    id: "post-atelier-abuja",
    designerId: "des-eniola",
    caption:
      "Cutting for the September calendar at the Abuja atelier — corporate and occasion pieces, made to your vault numbers.",
    tags: ["bespoke", "workwear"],
    priceCents: 3_800_000,
    turnaround: 10,
    media: [
      {
        file: "outfit-w10.jpg",
        alt: "Designer at a work table making clothes in the atelier",
      },
    ],
    likes: 9,
    comments: 1,
    createdDaysAgo: 0.3,
  }),
  makePost({
    id: "post-ankara-gown",
    designerId: "des-amara",
    caption:
      "Ankara maxi skirt with structured waistband — made to your exact measurements. DM slots open for June.",
    tags: ["ankara", "skirt", "occasion"],
    priceCents: 4_500_000,
    turnaround: 14,
    media: [
      {
        file: "outfit-w01.jpg",
        alt: "Model in an ankara maxi skirt on the runway",
      },
    ],
    likes: 34,
    comments: 3,
    createdDaysAgo: 2,
  }),
  makePost({
    id: "post-asooke-set",
    designerId: "des-bisi",
    caption:
      "Little senator — ceremonial set for the youngest guest. Aso-oke trim, custom-sized, hand-finished.",
    tags: ["senator", "kids", "traditional"],
    priceCents: 6_200_000,
    turnaround: 21,
    media: [
      {
        file: "outfit-w13.jpg",
        alt: "Boy in a royal blue senator outfit with white piping",
      },
    ],
    likes: 41,
    comments: 5,
    createdDaysAgo: 4,
  }),
  makePost({
    id: "post-bridal-gown",
    designerId: "des-bisi",
    caption:
      "Bridal second-look gown — blush, structured train, hand-finished. Booked per season, two fittings included.",
    tags: ["bridal", "gown", "wedding"],
    priceCents: 15_000_000,
    turnaround: 30,
    media: [
      {
        file: "outfit-w00.jpg",
        alt: "Model in a blush bridal gown with a structured train",
      },
    ],
    likes: 38,
    comments: 4,
    createdDaysAgo: 9,
  }),
  makePost({
    id: "post-print-couple",
    designerId: "des-amara",
    caption:
      "Matching African print set for two — coordination without the costume feel.",
    tags: ["print", "couple", "casual"],
    priceCents: 3_800_000,
    turnaround: 10,
    media: [
      {
        file: "outfit-w16.jpg",
        alt: "Couple wearing matching African print outfits",
      },
    ],
    likes: 18,
    comments: 2,
    createdDaysAgo: 1,
  }),
  makePost({
    id: "post-agbada",
    designerId: "des-tunde",
    caption:
      "Ceremonial robe set — traditional cut, made for movement. Ceremony-ready in three weeks.",
    tags: ["ceremonial", "menswear", "traditional"],
    priceCents: 5_500_000,
    turnaround: 21,
    media: [
      { file: "outfit-w06.jpg", alt: "Men in traditional ceremonial dress" },
    ],
    likes: 27,
    comments: 4,
    createdDaysAgo: 6,
  }),
  makePost({
    id: "post-print-brothers",
    designerId: "des-tunde",
    caption:
      "African print shirts — brothers edition. Casual fit, sharp collars.",
    tags: ["print", "menswear", "casual"],
    priceCents: 2_200_000,
    turnaround: 7,
    media: [
      {
        file: "outfit-w15.jpg",
        alt: "Two men in matching African print shirts",
      },
    ],
    likes: 12,
    comments: 1,
    createdDaysAgo: 8,
  }),
  makePost({
    id: "post-runway-orange",
    designerId: "des-bisi",
    caption:
      "Resort one-piece from the new capsule — palm print, runway sample available made-to-measure.",
    tags: ["resort", "runway", "swim"],
    priceCents: null,
    turnaround: 18,
    media: [
      {
        file: "outfit-w05.jpg",
        alt: "Runway model in a palm-print one-piece swimsuit",
      },
    ],
    likes: 46,
    comments: 6,
    createdDaysAgo: 11,
  }),
  makePost({
    id: "post-fabric-drop",
    designerId: "des-amara",
    caption:
      "New fabric drop — bring your vault measurements and pick a silhouette.",
    tags: ["fabric", "ankara"],
    priceCents: null,
    turnaround: 14,
    media: [
      { file: "outfit-w14.jpg", alt: "African print fabrics on display" },
      { file: "outfit-w10.jpg", alt: "Designer cutting cloth at a work table" },
    ],
    likes: 14,
    comments: 2,
    createdDaysAgo: 15,
  }),
  makePost({
    id: "post-chromat-look",
    designerId: "des-bisi",
    caption:
      "Statement eveningwear commission from last season — silhouettes like this start at ₦80k.",
    tags: ["evening", "occasion"],
    priceCents: 8_000_000,
    turnaround: 28,
    media: [
      { file: "outfit-w03.jpg", alt: "Model in a statement evening look" },
    ],
    likes: 22,
    comments: 3,
    createdDaysAgo: 20,
  }),
  makePost({
    id: "post-dance-troupe",
    designerId: "des-tunde",
    caption:
      "Costume set delivered for a university culture showcase — 12 pieces, one week.",
    tags: ["traditional", "group"],
    priceCents: null,
    turnaround: 7,
    media: [
      {
        file: "outfit-w06.jpg",
        alt: "Dancers performing in traditional dress",
      },
    ],
    likes: 19,
    comments: 2,
    createdDaysAgo: 26,
  }),
];

export const seedComments: Comment[] = [
  {
    id: "cmt-33",
    post_id: "post-atelier-abuja",
    author: { id: "acc-zainab", username: "zainab.k", avatar_url: null },
    body: "An atelier this side of Abuja at last — booking for December.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.15),
  },
  {
    id: "cmt-1",
    post_id: "post-ankara-gown",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Obsessed with this print 😍",
    like_count: 4,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.5),
  },
  {
    id: "cmt-2",
    post_id: "post-ankara-gown",
    author: { id: "acc-bisi", username: "maisonbisi", avatar_url: null },
    body: "Beautiful work as always, Amara.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.2),
  },
  {
    id: "cmt-3",
    post_id: "post-ankara-gown",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: null },
    body: "Do you have this in a longer length? Asking for a wedding guest look.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.8),
  },
  {
    id: "cmt-4",
    post_id: "post-asooke-set",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Commissioned one of these — the finish is even better in person.",
    like_count: 6,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(3),
  },
  {
    id: "cmt-5",
    post_id: "post-asooke-set",
    author: { id: "acc-bisi", username: "maisonbisi", avatar_url: null },
    body: "@kiki.adeyemi thank you! Your little senator came out so well — one of my favourites this year.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2.8),
  },
  {
    id: "cmt-6",
    post_id: "post-asooke-set",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: null },
    body: "The texture on this is unreal.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2.5),
  },
  {
    id: "cmt-7",
    post_id: "post-asooke-set",
    author: { id: "acc-tunde", username: "tunde.o", avatar_url: null },
    body: "Clean finishing as usual, Bisi. 🔥",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2),
  },
  {
    id: "cmt-8",
    post_id: "post-asooke-set",
    author: { id: "acc-zainab", username: "zainab.k", avatar_url: null },
    body: "Could you do a lighter fabric version for Abuja heat?",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1),
  },
  {
    id: "cmt-9",
    post_id: "post-bridal-gown",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Sending this to my cousin immediately.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2.5),
  },
  {
    id: "cmt-10",
    post_id: "post-bridal-gown",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: null },
    body: "That train 😭😭",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2),
  },
  {
    id: "cmt-11",
    post_id: "post-bridal-gown",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: null },
    body: "How far in advance should a bride book?",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.5),
  },
  {
    id: "cmt-12",
    post_id: "post-bridal-gown",
    author: { id: "acc-tunde", username: "tunde.o", avatar_url: null },
    body: "Season's best, easily.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1),
  },
  {
    id: "cmt-13",
    post_id: "post-print-couple",
    author: { id: "acc-chidi", username: "chidi.n", avatar_url: null },
    body: "My fiancée just tagged me. I know what that means.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.7),
  },
  {
    id: "cmt-14",
    post_id: "post-print-couple",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: null },
    body: "Coordination without the costume feel — exactly right.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.4),
  },
  {
    id: "cmt-15",
    post_id: "post-agbada",
    author: { id: "acc-emeka", username: "emeka.u", avatar_url: null },
    body: "That drape — exactly what ceremony wear needed.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(5),
  },
  {
    id: "cmt-16",
    post_id: "post-agbada",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: null },
    body: "My dad would love this.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(3),
  },
  {
    id: "cmt-17",
    post_id: "post-agbada",
    author: { id: "acc-tola", username: "tola.mak", avatar_url: null },
    body: "Ceremony-ready indeed. Sharp.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2),
  },
  {
    id: "cmt-18",
    post_id: "post-agbada",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Just sent a request for my brother's wedding — fingers crossed! 🤞",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1),
  },
  {
    id: "cmt-19",
    post_id: "post-print-brothers",
    author: { id: "acc-chidi", username: "chidi.n", avatar_url: null },
    body: "Need this for my brother and me. Those collars!",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(6),
  },
  {
    id: "cmt-20",
    post_id: "post-runway-orange",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: null },
    body: "Resort season starts here.",
    like_count: 4,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(10),
  },
  {
    id: "cmt-21",
    post_id: "post-runway-orange",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: null },
    body: "Saw this on the runway — stunned it's available made-to-measure.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(9.5),
  },
  {
    id: "cmt-22",
    post_id: "post-runway-orange",
    author: { id: "acc-zainab", username: "zainab.k", avatar_url: null },
    body: "This silhouette would be perfect for a December event.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(9),
  },
  {
    id: "cmt-23",
    post_id: "post-runway-orange",
    author: { id: "acc-emeka", username: "emeka.u", avatar_url: null },
    body: "Vacation booked just for this.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(8),
  },
  {
    id: "cmt-24",
    post_id: "post-runway-orange",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "This print 😍",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(7),
  },
  {
    id: "cmt-25",
    post_id: "post-runway-orange",
    author: { id: "acc-tola", username: "tola.mak", avatar_url: null },
    body: "Bisi never misses.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(5),
  },
  {
    id: "cmt-26",
    post_id: "post-fabric-drop",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: null },
    body: "That second print — reserving a silhouette this week.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(14),
  },
  {
    id: "cmt-27",
    post_id: "post-fabric-drop",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Coming through with my vault numbers!",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(13),
  },
  {
    id: "cmt-28",
    post_id: "post-chromat-look",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: null },
    body: "Statement is an understatement.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(19),
  },
  {
    id: "cmt-29",
    post_id: "post-chromat-look",
    author: { id: "acc-zainab", username: "zainab.k", avatar_url: null },
    body: "The drape on this — beautiful.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(18),
  },
  {
    id: "cmt-30",
    post_id: "post-chromat-look",
    author: { id: "acc-chidi", username: "chidi.n", avatar_url: null },
    body: "Saving this for my sister.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(17),
  },
  {
    id: "cmt-31",
    post_id: "post-dance-troupe",
    author: { id: "acc-emeka", username: "emeka.u", avatar_url: null },
    body: "12 pieces in a week is wild. Respect.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(25),
  },
  {
    id: "cmt-32",
    post_id: "post-dance-troupe",
    author: { id: "acc-tola", username: "tola.mak", avatar_url: null },
    body: "The showcase was amazing — costumes made it.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(24),
  },
];

// ---------------------------------------------------------------------------
// Vault — kiki's measurement sessions (shoulder 42.5 cm etc., freshness)
// ---------------------------------------------------------------------------

export const seedSessions: MeasurementSession[] = [
  {
    id: "sess-recent-scan",
    customer_id: "acc-kiki",
    method: "mediapipe_2d_v2",
    input_height_cm: 168,
    status: "complete",
    measurements: [
      {
        id: "m-1",
        session_id: "sess-recent-scan",
        name: "shoulder_width",
        value_cm: 42.5,
        source: "pipeline",
        confidence: 0.92,
      },
      {
        id: "m-2",
        session_id: "sess-recent-scan",
        name: "hip_width",
        value_cm: 36.8,
        source: "pipeline",
        confidence: 0.88,
      },
    ],
    pipeline_meta: { model_version: "mp2d-v2.3", qc: "pass" },
    created_at: daysAgo(12), // fresh (<30d) — "Measured 12 days ago" (MI-11)
  },
  {
    id: "sess-manual-tape",
    customer_id: "acc-kiki",
    method: "manual",
    input_height_cm: 168,
    status: "complete",
    measurements: [
      {
        id: "m-3",
        session_id: "sess-manual-tape",
        name: "shoulder_width",
        value_cm: 42.0,
        source: "pipeline",
        confidence: null,
      },
      {
        id: "m-4",
        session_id: "sess-manual-tape",
        name: "hip_width",
        value_cm: 37.2,
        source: "pipeline",
        confidence: null,
      },
      {
        id: "m-5",
        session_id: "sess-manual-tape",
        name: "chest_girth",
        value_cm: 92.0,
        source: "pipeline",
        confidence: null,
      },
      {
        id: "m-6",
        session_id: "sess-manual-tape",
        name: "waist_girth",
        value_cm: 78.5,
        source: "pipeline",
        confidence: null,
      },
    ],
    pipeline_meta: {},
    created_at: daysAgo(58), // aging (30–90d)
  },
  {
    id: "sess-old-scan",
    customer_id: "acc-kiki",
    method: "mediapipe_2d",
    input_height_cm: 168,
    status: "complete",
    measurements: [
      {
        id: "m-7",
        session_id: "sess-old-scan",
        name: "shoulder_width",
        value_cm: 41.8,
        source: "pipeline",
        confidence: 0.81,
      },
      {
        id: "m-8",
        session_id: "sess-old-scan",
        name: "hip_width",
        value_cm: 37.0,
        source: "pipeline",
        confidence: 0.64,
      },
    ],
    pipeline_meta: { model_version: "mp2d-v1.9", qc: "pass" },
    created_at: daysAgo(140), // stale (>90d)
  },
];

// ---------------------------------------------------------------------------
// Orders — all ten lifecycle states from seed (web-implementation.md §6:
// every StatusPill, OrderTimelineRow, and PaymentBox variant renders from
// boot). #APR-1042 (in_progress) and #APR-1058 (delivered) carry the full
// detailed narrative; the other eight are helper-built.
// ---------------------------------------------------------------------------

const KIKI_DELIVERY = {
  recipient_name: "Kiki Adeyemi",
  phone: "+2348012345678",
  line1: "14 Adeola Odeku St",
  city: "Lagos",
  state: "Lagos",
  country: "NG",
};

interface SeedOrderInput {
  num: number;
  postId: string;
  status: OrderStatus;
  createdDaysAgo: number;
  events: {
    kind: string;
    actor: "customer" | "designer" | "system";
    at: number;
    /**
     * Local time of day ("HH:mm") for the event — required for whole-day
     * offsets so each order's story spreads across real-looking hours
     * (PR #102 cadence rule); omit only for same-day offsets (< 1), which
     * stay relative to boot.
     */
    time?: string;
  }[];
  quote?: number | null;
  budget?: number | null;
  dueInDays?: number | null;
  payment?: "held" | "released" | "refunded" | null;
  tracking?: string | null;
  decline?: DeclineReason | null;
  dispute?: { reason: DisputeReason; detail: string | null } | null;
  notes?: string;
}

const postById = (id: string) => {
  const post = seedPosts.find((p) => p.id === id)!;
  return post;
};

function makeOrder(input: SeedOrderInput): CommissionRequest {
  const post = postById(input.postId);
  const id = `req-apr-${input.num}`;
  const quote = input.quote ?? null;
  const events = input.events.map((e, i) => ({
    id: `evt-${input.num}-${i}`,
    request_id: id,
    kind: e.kind,
    actor: e.actor,
    created_at: e.time ? daysAgoAt(e.at, e.time) : daysAgo(e.at),
  }));
  // The order (and the snapshot freeze) exists from the moment it was
  // requested — anchor both to the first event so the record is one
  // coherent story, not three separately-stamped rows.
  const requestedAt = events[0].created_at;
  return {
    id,
    order_number: `APR-${input.num}`,
    post: {
      id: post.id,
      caption: post.caption.split(" — ")[0],
      thumb_url: post.media[0].url,
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: {
      id: post.designer.id,
      username: post.designer.username,
      avatar_url: post.designer.avatar_url,
    },
    status: input.status,
    notes: input.notes ?? "",
    budget_cents: input.budget ?? null,
    quote_cents: quote,
    currency: "NGN",
    due_at: input.dueInDays != null ? daysAgo(-input.dueInDays) : null,
    target_date: null,
    tracking: input.tracking ?? null,
    decline_reason: input.decline ?? null,
    dispute: input.dispute ?? null,
    delivery: KIKI_DELIVERY,
    // The snapshot freezes whichever vault session existed when the order
    // was placed — measured_at always precedes the order (P1 realism pass).
    snapshot: {
      id: `snap-${input.num}`,
      request_id: id,
      values:
        input.createdDaysAgo <= 12
          ? {
              method: "mediapipe_2d_v2",
              measured_at: daysAgo(12),
              measurements: [
                { name: "shoulder_width", value_cm: 42.5 },
                { name: "hip_width", value_cm: 36.8 },
              ],
            }
          : input.createdDaysAgo <= 58
            ? {
                method: "manual",
                measured_at: daysAgo(58),
                measurements: [
                  { name: "shoulder_width", value_cm: 42.0 },
                  { name: "hip_width", value_cm: 37.2 },
                  { name: "chest_girth", value_cm: 92.0 },
                  { name: "waist_girth", value_cm: 78.5 },
                ],
              }
            : {
                method: "mediapipe_2d",
                measured_at: daysAgo(140),
                measurements: [
                  { name: "shoulder_width", value_cm: 41.8 },
                  { name: "hip_width", value_cm: 37.0 },
                ],
              },
      created_at: requestedAt,
    },
    events,
    payment:
      input.payment && quote !== null
        ? {
            id: `pay-${input.num}`,
            request_id: id,
            provider: "paystack",
            state: input.payment,
            currency: "NGN",
            amount_cents: quote,
            platform_fee_cents: Math.round(quote * 0.1),
          }
        : null,
    created_at: requestedAt,
  };
}

export const seedOrders: CommissionRequest[] = [
  {
    id: "req-apr-1042",
    order_number: "APR-1042",
    post: {
      id: "post-ankara-gown",
      caption: "Ankara maxi skirt with structured waistband",
      thumb_url: "/demo/outfit-w01.jpg",
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: { id: "des-amara", username: "amara.designs", avatar_url: null },
    status: "in_progress",
    notes:
      "Ankle length please, with a small side slit — easier to dance in. Event is July 26.",
    budget_cents: 5_000_000,
    quote_cents: 4_500_000, // ₦45,000
    currency: "NGN",
    due_at: daysAgo(-10), // due in 10 days
    target_date: daysAgo(-14),
    tracking: null,
    decline_reason: null,
    dispute: null,
    delivery: {
      recipient_name: "Kiki Adeyemi",
      phone: "+2348012345678",
      line1: "14 Adeola Odeku St",
      city: "Lagos",
      state: "Lagos",
      country: "NG",
    },
    snapshot: {
      id: "snap-1042",
      request_id: "req-apr-1042",
      values: {
        method: "mediapipe_2d_v2",
        measured_at: daysAgo(12),
        measurements: [
          { name: "shoulder_width", value_cm: 42.5 },
          { name: "hip_width", value_cm: 36.8 },
        ],
      },
      created_at: daysAgoAt(8, "09:14"),
    },
    // Event times spread across real-looking hours (PR #102 cadence rule);
    // the B3 canvas timeline adopts these same stamps.
    events: [
      {
        id: "evt-1042-1",
        request_id: "req-apr-1042",
        kind: "requested",
        actor: "customer",
        created_at: daysAgoAt(8, "09:14"),
      },
      {
        id: "evt-1042-2",
        request_id: "req-apr-1042",
        kind: "quoted",
        actor: "designer",
        created_at: daysAgoAt(7, "14:02"),
      },
      {
        id: "evt-1042-3",
        request_id: "req-apr-1042",
        kind: "paid",
        actor: "customer",
        created_at: daysAgoAt(6, "10:26"),
      },
      {
        id: "evt-1042-4",
        request_id: "req-apr-1042",
        kind: "in_progress",
        actor: "designer",
        created_at: daysAgoAt(5, "09:40"),
      },
    ],
    payment: {
      id: "pay-1042",
      request_id: "req-apr-1042",
      provider: "paystack",
      state: "held",
      currency: "NGN",
      amount_cents: 4_500_000,
      platform_fee_cents: 450_000, // 10% (A-1)
    },
    created_at: daysAgoAt(8, "09:14"),
  },
  {
    id: "req-apr-1058",
    order_number: "APR-1058",
    post: {
      id: "post-asooke-set",
      caption: "Little senator",
      thumb_url: "/demo/outfit-w13.jpg",
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: { id: "des-bisi", username: "maisonbisi", avatar_url: null },
    status: "delivered",
    notes:
      "Gift for my nephew Tobi (age 6) — family wedding. Colour scheme in thread; his measurements are tape-measured, entered by hand.",
    budget_cents: null,
    quote_cents: 6_200_000, // ₦62,000
    currency: "NGN",
    due_at: daysAgo(9),
    target_date: daysAgo(5),
    tracking: "GIG-4411-LAG",
    decline_reason: null,
    dispute: null,
    delivery: {
      recipient_name: "Kiki Adeyemi",
      phone: "+2348012345678",
      line1: "14 Adeola Odeku St",
      city: "Lagos",
      state: "Lagos",
      country: "NG",
    },
    // The child outfit is a GIFT: kiki tape-measured her nephew and entered
    // the values as a manual vault session just before requesting, then
    // deleted that session after the order was placed — snapshots freeze at
    // request time, so the order keeps the child's numbers while her own
    // vault (adult sessions above) is untouched (PR #102 review: an adult
    // 42 cm-shoulder snapshot can't dress a six-year-old).
    snapshot: {
      id: "snap-1058",
      request_id: "req-apr-1058",
      values: {
        method: "manual",
        measured_at: daysAgo(41),
        measurements: [
          { name: "shoulder_width", value_cm: 28.0 },
          { name: "hip_width", value_cm: 25.5 },
          { name: "chest_girth", value_cm: 60.5 },
          { name: "waist_girth", value_cm: 55.0 },
        ],
      },
      created_at: daysAgoAt(40, "11:05"),
    },
    events: [
      {
        id: "evt-1058-1",
        request_id: "req-apr-1058",
        kind: "requested",
        actor: "customer",
        created_at: daysAgoAt(40, "11:05"),
      },
      {
        id: "evt-1058-2",
        request_id: "req-apr-1058",
        kind: "quoted",
        actor: "designer",
        created_at: daysAgoAt(38, "16:40"),
      },
      {
        id: "evt-1058-3",
        request_id: "req-apr-1058",
        kind: "paid",
        actor: "customer",
        created_at: daysAgoAt(36, "08:57"),
      },
      {
        id: "evt-1058-4",
        request_id: "req-apr-1058",
        kind: "in_progress",
        actor: "designer",
        created_at: daysAgoAt(30, "09:18"),
      },
      {
        id: "evt-1058-5",
        request_id: "req-apr-1058",
        kind: "shipped",
        actor: "designer",
        created_at: daysAgoAt(10, "17:25"),
      },
      {
        id: "evt-1058-6",
        request_id: "req-apr-1058",
        kind: "delivered",
        actor: "customer",
        created_at: daysAgoAt(7, "13:44"),
      },
    ],
    payment: {
      id: "pay-1058",
      request_id: "req-apr-1058",
      provider: "paystack",
      state: "released",
      currency: "NGN",
      amount_cents: 6_200_000,
      platform_fee_cents: 620_000,
    },
    created_at: daysAgoAt(40, "11:05"),
  },
  makeOrder({
    num: 1031,
    postId: "post-agbada",
    status: "requested",
    createdDaysAgo: 1,
    budget: 6_000_000,
    notes: "Need it for my brother's wedding in August.",
    events: [{ kind: "requested", actor: "customer", at: 1, time: "18:32" }],
  }),
  makeOrder({
    num: 1033,
    postId: "post-print-couple",
    status: "quoted",
    createdDaysAgo: 3,
    quote: 4_000_000,
    budget: 4_500_000,
    dueInDays: 12,
    notes: "Two-piece for an engagement shoot.",
    events: [
      { kind: "requested", actor: "customer", at: 3, time: "12:47" },
      // 0.25d = 6h, relative to boot — matches the unread "quoted ₦40,000"
      // notification (hoursAgo(6)); same-day offsets stay unpinned.
      { kind: "quoted", actor: "designer", at: 0.25 },
    ],
  }),
  makeOrder({
    num: 1036,
    postId: "post-runway-orange",
    status: "paid",
    createdDaysAgo: 6,
    quote: 3_500_000,
    dueInDays: 21,
    payment: "held",
    events: [
      { kind: "requested", actor: "customer", at: 6, time: "09:05" },
      { kind: "quoted", actor: "designer", at: 5, time: "15:22" },
      { kind: "paid", actor: "customer", at: 4, time: "19:48" },
    ],
  }),
  makeOrder({
    num: 1044,
    postId: "post-print-brothers",
    status: "shipped",
    createdDaysAgo: 20,
    quote: 2_200_000,
    dueInDays: -2,
    payment: "held",
    tracking: "GIG-5567-LAG",
    events: [
      { kind: "requested", actor: "customer", at: 20, time: "10:12" },
      { kind: "quoted", actor: "designer", at: 19, time: "13:37" },
      { kind: "paid", actor: "customer", at: 18, time: "08:26" },
      { kind: "in_progress", actor: "designer", at: 15, time: "11:54" },
      { kind: "shipped", actor: "designer", at: 3, time: "16:09" },
    ],
  }),
  makeOrder({
    num: 1018,
    postId: "post-dance-troupe",
    status: "disputed",
    createdDaysAgo: 25,
    quote: 3_000_000,
    payment: "held",
    dispute: {
      reason: "not_as_described",
      detail: "Colours differ from the reference photos.",
    },
    events: [
      { kind: "requested", actor: "customer", at: 25, time: "14:31" },
      { kind: "quoted", actor: "designer", at: 24, time: "10:58" },
      { kind: "paid", actor: "customer", at: 22, time: "20:15" },
      { kind: "in_progress", actor: "designer", at: 20, time: "09:47" },
      { kind: "disputed", actor: "customer", at: 2, time: "18:03" },
    ],
  }),
  makeOrder({
    num: 1012,
    postId: "post-fabric-drop",
    status: "declined",
    createdDaysAgo: 30,
    decline: "workload",
    events: [
      { kind: "requested", actor: "customer", at: 30, time: "13:20" },
      { kind: "declined", actor: "designer", at: 29, time: "09:36" },
    ],
  }),
  makeOrder({
    num: 1009,
    postId: "post-ankara-gown",
    status: "refunded",
    createdDaysAgo: 60,
    quote: 4_200_000,
    payment: "refunded",
    events: [
      { kind: "requested", actor: "customer", at: 60, time: "11:41" },
      { kind: "quoted", actor: "designer", at: 58, time: "15:07" },
      { kind: "paid", actor: "customer", at: 55, time: "10:33" },
      { kind: "refunded", actor: "system", at: 41, time: "09:02" },
    ],
  }),
  makeOrder({
    num: 1005,
    postId: "post-chromat-look",
    status: "cancelled",
    createdDaysAgo: 45,
    events: [
      { kind: "requested", actor: "customer", at: 45, time: "17:29" },
      { kind: "cancelled", actor: "customer", at: 44, time: "08:44" },
    ],
  }),
];

// Message times sit minutes-to-hours around the order events they narrate
// (PR #102 cadence rule — the thread and the timeline tell one story).
export const seedThreadMessages = [
  {
    id: "msg-1042-1",
    request_id: "req-apr-1042",
    author_id: "acc-kiki",
    body: "Hi Amara! Excited about this one — here's my inspiration.",
    image_url: "/demo/outfit-w01.jpg",
    created_at: daysAgoAt(8, "09:31"), // shortly after requesting (09:14)
  },
  {
    id: "msg-1042-2",
    request_id: "req-apr-1042",
    author_id: "des-amara",
    body: "Love it. Quote sent — I can have it ready two weeks after payment.",
    image_url: null,
    created_at: daysAgoAt(7, "14:05"), // right behind the quote (14:02)
  },
  {
    id: "msg-1042-3",
    request_id: "req-apr-1042",
    author_id: "des-amara",
    body: "Fabric cut today — progress shot attached.",
    image_url: "/demo/outfit-w14.jpg",
    created_at: daysAgoAt(2, "16:12"),
  },
  {
    id: "msg-1058-1",
    request_id: "req-apr-1058",
    author_id: "acc-kiki",
    body: "Colour scheme: royal blue and white, please — same as the post.",
    image_url: null,
    created_at: daysAgoAt(39, "10:20"),
  },
  {
    id: "msg-1058-2",
    request_id: "req-apr-1058",
    author_id: "des-bisi",
    body: "Delivered via GIG — enjoy the wedding!",
    image_url: null,
    created_at: daysAgoAt(10, "17:31"), // minutes after shipping (17:25)
  },
  // The helper-built orders carry short, state-appropriate exchanges so
  // every thread reads like a real buyer–designer conversation.
  {
    id: "msg-1031-1",
    request_id: "req-apr-1031",
    author_id: "acc-kiki",
    body: "Sent the request — it's for my brother's wedding on Aug 22. Can you match the fabric in your post?",
    image_url: null,
    created_at: daysAgoAt(1, "18:41"), // right after requesting (18:32)
  },
  {
    id: "msg-1033-1",
    request_id: "req-apr-1033",
    author_id: "acc-kiki",
    body: "The engagement shoot is in three weeks — is that doable?",
    image_url: null,
    created_at: daysAgo(2.5),
  },
  {
    id: "msg-1033-2",
    request_id: "req-apr-1033",
    author_id: "des-amara",
    body: "Just quoted ₦40,000 — three weeks is fine if payment lands this week.",
    image_url: null,
    created_at: daysAgo(0.24), // ~15 min after the 0.25d quote event
  },
  {
    id: "msg-1036-1",
    request_id: "req-apr-1036",
    author_id: "des-bisi",
    body: "Payment received — sourcing the print lycra this week. Will share swatches here.",
    image_url: null,
    created_at: daysAgo(3.5),
  },
  {
    id: "msg-1044-1",
    request_id: "req-apr-1044",
    author_id: "des-tunde",
    body: "Shipped via GIG — tracking GIG-5567-LAG. Apologies for the two-day slip, the collars took longer than planned.",
    image_url: null,
    created_at: daysAgoAt(3, "16:14"), // minutes after shipping (16:09)
  },
  {
    id: "msg-1018-1",
    request_id: "req-apr-1018",
    author_id: "acc-kiki",
    body: "The colours are quite different from the reference photos — can we talk about this?",
    image_url: null,
    created_at: daysAgo(2.5),
  },
  {
    id: "msg-1018-2",
    request_id: "req-apr-1018",
    author_id: "des-tunde",
    body: "I see it — the dye lot shifted between samples. Happy to redo the top piece once support weighs in.",
    image_url: null,
    created_at: daysAgo(1.8),
  },
  {
    id: "msg-1012-1",
    request_id: "req-apr-1012",
    author_id: "des-tunde",
    body: "Fully booked until September, so I have to decline — sorry! maisonbisi does beautiful work in this style.",
    image_url: null,
    created_at: daysAgoAt(29, "09:41"), // right after declining (09:36)
  },
];

// ---------------------------------------------------------------------------
// Notifications (kiki's activity sheet) + moderation queue
// ---------------------------------------------------------------------------

export const seedNotifications: Notification[] = [
  {
    id: "ntf-quote",
    account_id: "acc-kiki",
    kind: "quote",
    payload_ref: "req-apr-1033",
    text: "amara.designs quoted your request #APR-1033 — ₦40,000",
    actor: { username: "amara.designs", avatar_url: null },
    thumb_url: "/demo/outfit-w16.jpg",
    read_at: null,
    created_at: hoursAgo(6),
  },
  {
    id: "ntf-comment",
    account_id: "acc-kiki",
    kind: "comment",
    payload_ref: "post-asooke-set",
    // Matches cmt-5 (bisi's reply, 2.8d) — read when kiki next opened the app.
    text: "maisonbisi replied to your comment on Little senator",
    actor: { username: "maisonbisi", avatar_url: null },
    thumb_url: "/demo/outfit-w13.jpg",
    read_at: daysAgo(2),
    created_at: daysAgo(2.8),
  },
  {
    id: "ntf-payout-bisi",
    account_id: "des-bisi",
    kind: "payout",
    payload_ref: "req-apr-1058",
    text: "Payout released for order #APR-1058 — ₦55,800",
    actor: { username: "kiki.adeyemi", avatar_url: null },
    thumb_url: "/demo/outfit-w13.jpg",
    read_at: daysAgo(6),
    created_at: daysAgo(7),
  },
  {
    id: "ntf-request-tunde",
    account_id: "des-tunde",
    kind: "status_change",
    payload_ref: "req-apr-1031",
    text: "kiki.adeyemi requested Ceremonial robe set (#APR-1031)",
    actor: { username: "kiki.adeyemi", avatar_url: null },
    thumb_url: "/demo/outfit-w06.jpg",
    read_at: null,
    created_at: daysAgo(1),
  },
  {
    id: "ntf-1",
    account_id: "acc-kiki",
    kind: "status_change",
    payload_ref: "req-apr-1042",
    text: "amara.designs started work on your order #APR-1042",
    actor: { username: "amara.designs", avatar_url: null },
    thumb_url: "/demo/outfit-w01.jpg",
    read_at: daysAgo(4),
    created_at: daysAgo(5),
  },
  {
    id: "ntf-2",
    account_id: "acc-kiki",
    kind: "like",
    payload_ref: "post-ankara-gown",
    text: "maisonbisi liked your comment",
    actor: { username: "maisonbisi", avatar_url: null },
    thumb_url: "/demo/outfit-w01.jpg",
    read_at: null,
    created_at: hoursAgo(20),
  },
  {
    id: "ntf-3",
    account_id: "acc-kiki",
    kind: "status_change",
    payload_ref: "req-apr-1058",
    text: "Order #APR-1058 was delivered — payout released to maisonbisi",
    actor: { username: "maisonbisi", avatar_url: null },
    thumb_url: "/demo/outfit-w13.jpg",
    read_at: daysAgo(6),
    created_at: daysAgo(7),
  },
  {
    id: "ntf-4",
    account_id: "acc-kiki",
    kind: "like",
    payload_ref: "post-runway-orange",
    // Fresh activity — someone browsing an older post minutes ago.
    text: "ada.eze liked your comment on Resort one-piece",
    actor: { username: "ada.eze", avatar_url: null },
    thumb_url: "/demo/outfit-w05.jpg",
    read_at: null,
    created_at: hoursAgo(0.6),
  },
  {
    id: "ntf-follow-tunde",
    account_id: "des-tunde",
    kind: "follow",
    payload_ref: "des-tunde",
    text: "funmi.b started following you",
    actor: { username: "funmi.b", avatar_url: null },
    thumb_url: null,
    read_at: daysAgo(2),
    created_at: daysAgo(3),
  },
];

// The B7a queue narrative (canvas shape): two open reports — a spam
// comment and a reported post with its thumb — plus one actioned exemplar
// so the audit-trail row state renders from boot. Reported comments exist
// as previews only (the spam one was never a seeded comment; the actioned
// one is hidden), so post comment_counts stay honest.
export const seedReports: Report[] = [
  {
    id: "rep-1",
    reporter: { id: "acc-tunde", username: "tunde.o" },
    subject_kind: "comment",
    subject_id: "cmt-spam-1",
    subject_preview: {
      text: "🔥🔥 Buy followers cheap — link in bio",
      thumb_url: null,
      author_username: null,
    },
    reason: "spam",
    detail: null,
    status: "open",
    action: null,
    actioned_by: null,
    actioned_at: null,
    created_at: daysAgoAt(1, "21:37"),
  },
  {
    id: "rep-2",
    reporter: { id: "acc-chidi", username: "chidi.n" },
    subject_kind: "post",
    subject_id: "post-fabric-drop",
    subject_preview: {
      text: "New fabric drop — bring your vault measurements and pick a silhouette.",
      thumb_url: "/demo/outfit-w14.jpg",
      author_username: "amara.designs",
    },
    reason: "spam",
    detail: "Reads like an ad, not an outfit post.",
    status: "open",
    action: null,
    actioned_by: null,
    actioned_at: null,
    created_at: daysAgoAt(2, "08:19"),
  },
  {
    id: "rep-3",
    reporter: { id: "acc-zainab", username: "zainab.k" },
    subject_kind: "comment",
    subject_id: "cmt-counterfeit-1",
    subject_preview: {
      text: "DM for the exact same aso-oke, half the price 👀",
      thumb_url: null,
      author_username: null,
    },
    reason: "counterfeit",
    detail: "Selling knockoffs of maisonbisi pieces in the comments.",
    status: "actioned",
    action: "hide_post", // comment subject — renders as hide_comment
    actioned_by: { id: "acc-sarah", username: "mod.sarah" },
    actioned_at: daysAgoAt(5, "09:12"),
    created_at: daysAgoAt(6, "22:05"),
  },
];

/**
 * kiki's own engagement — the posts she commissioned or commented on carry
 * her like/save so her profile and action rows reflect real history
 * (a signed-in demo user who has never liked anything reads as synthetic).
 */
export const seedLikes: [string, string][] = [
  ["acc-kiki", "post-asooke-set"],
  ["acc-kiki", "post-runway-orange"],
  ["acc-kiki", "post-bridal-gown"],
];

export const seedSaves: [string, string][] = [
  ["acc-kiki", "post-bridal-gown"],
  ["acc-kiki", "post-chromat-look"],
];

/**
 * kiki follows amara + bisi (tunde is the "suggested designer"); designer-
 * to-designer and community edges fill the B6 followers/following sheets.
 */
export const seedFollows: [string, string][] = [
  ["acc-kiki", "amara.designs"],
  ["acc-kiki", "maisonbisi"],
  ["acc-amara", "tunde.o"],
  ["acc-amara", "maisonbisi"],
  ["acc-tunde", "amara.designs"],
  ["acc-bisi", "amara.designs"],
  // The Abuja designer follows the Lagos scene; zainab (Abuja) follows her
  // hometown atelier.
  ["acc-eniola", "amara.designs"],
  ["acc-zainab", "eniola.stitches"],
  // Community edges — the designers' followers_count mirrors this graph
  // exactly (amara 8 · tunde 4 · bisi 6 · eniola 1).
  ["acc-ada", "amara.designs"],
  ["acc-ada", "maisonbisi"],
  ["acc-funmi", "amara.designs"],
  ["acc-funmi", "maisonbisi"],
  ["acc-funmi", "tunde.o"],
  ["acc-chidi", "tunde.o"],
  ["acc-zainab", "amara.designs"],
  ["acc-zainab", "maisonbisi"],
  ["acc-emeka", "amara.designs"],
  ["acc-emeka", "tunde.o"],
  ["acc-tola", "maisonbisi"],
];
