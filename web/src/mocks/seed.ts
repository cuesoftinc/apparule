// Seed data — the canonical Figma narrative (docs/design.md §8.3 sourced
// photography; the mock narratives the designs boot with):
//   kiki.adeyemi (customer) · amara.designs / tunde.o / maisonbisi
//   (designers, Lagos) · orders #APR-1042 (ankara, ₦45,000, in_progress) and
//   #APR-1058 (aso-oke, ₦62,000, delivered/paid-out) · measurements
//   (shoulder 42.5 cm etc. with freshness) · feed posts referencing the
//   CC-licensed photos in web/public/demo (see ATTRIBUTIONS.md there).
import type {
  Account,
  Comment,
  CommissionRequest,
  DesignerProfile,
  MeasurementSession,
  Notification,
  Post,
  Report,
} from "@/models";

export const NOW = () => new Date();

export function daysAgo(days: number, base: Date = NOW()): string {
  return new Date(base.getTime() - days * 24 * 60 * 60 * 1000).toISOString();
}

function hoursAgo(hours: number): string {
  return new Date(NOW().getTime() - hours * 60 * 60 * 1000).toISOString();
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
    avatar_url: null,
    profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    deletion_state: "active",
    designer: { enabled: true, kyc_complete: true },
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
    consent: [
      { document: "tos", version: "1.0", accepted_at: daysAgo(220) },
      { document: "privacy", version: "1.0", accepted_at: daysAgo(220) },
    ],
    created_at: daysAgo(400),
  },
];

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
    followers_count: 1284,
    following_count: 87,
    posts_count: 4,
  },
  {
    id: "des-tunde",
    account_id: "acc-tunde",
    username: "tunde.o",
    display_name: "Tunde Okonkwo",
    bio: "Agbada, senator suits, and sharp menswear.",
    avatar_url: null,
    payout_account: {
      provider_ref: "PSTK-RCP-77310",
      bank_name: "Access Bank",
      account_last4: "9930",
      kyc_state: "verified",
    },
    verified: true,
    location: { city: "Lagos", state: "Lagos", country: "NG" },
    followers_count: 642,
    following_count: 120,
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
    followers_count: 2310,
    following_count: 45,
    posts_count: 3,
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
    id: "post-ankara-gown",
    designerId: "des-amara",
    caption:
      "Ankara midi gown with structured shoulders — made to your exact measurements. DM slots open for June.",
    tags: ["ankara", "gown", "occasion"],
    priceCents: 4_500_000,
    turnaround: 14,
    media: [
      { file: "outfit-w00.jpg", alt: "Model in a vibrant ankara gown on the runway" },
      { file: "outfit-w01.jpg", alt: "Ankara look, full-length runway shot" },
    ],
    likes: 214,
    comments: 3,
    createdDaysAgo: 2,
  }),
  makePost({
    id: "post-asooke-set",
    designerId: "des-bisi",
    caption:
      "Hand-woven aso-oke two-piece — ceremonial weight, modern cut. Quote on request.",
    tags: ["aso-oke", "traditional", "wedding"],
    priceCents: 6_200_000,
    turnaround: 21,
    media: [{ file: "outfit-w13.jpg", alt: "Traditional aso-oke outfit worn at a ceremony" }],
    likes: 452,
    comments: 5,
    createdDaysAgo: 4,
  }),
  makePost({
    id: "post-print-couple",
    designerId: "des-amara",
    caption: "Matching African print set for two — coordination without the costume feel.",
    tags: ["print", "couple", "casual"],
    priceCents: 3_800_000,
    turnaround: 10,
    media: [{ file: "outfit-w16.jpg", alt: "Couple wearing matching African print outfits" }],
    likes: 128,
    comments: 2,
    createdDaysAgo: 1,
  }),
  makePost({
    id: "post-agbada",
    designerId: "des-tunde",
    caption: "Classic agbada, updated proportions. Ceremony-ready in three weeks.",
    tags: ["agbada", "menswear", "traditional"],
    priceCents: 5_500_000,
    turnaround: 21,
    media: [{ file: "outfit-w11.jpg", alt: "Man wearing a tailored agbada" }],
    likes: 301,
    comments: 4,
    createdDaysAgo: 6,
  }),
  makePost({
    id: "post-print-brothers",
    designerId: "des-tunde",
    caption: "African print shirts — brothers edition. Casual fit, sharp collars.",
    tags: ["print", "menswear", "casual"],
    priceCents: 2_200_000,
    turnaround: 7,
    media: [{ file: "outfit-w15.jpg", alt: "Two men in matching African print shirts" }],
    likes: 96,
    comments: 1,
    createdDaysAgo: 8,
  }),
  makePost({
    id: "post-runway-orange",
    designerId: "des-bisi",
    caption: "Orange is the colour of the season — runway sample now available made-to-measure.",
    tags: ["runway", "gown", "occasion"],
    priceCents: null,
    turnaround: 18,
    media: [{ file: "outfit-w05.jpg", alt: "Runway model in an orange statement outfit" }],
    likes: 519,
    comments: 6,
    createdDaysAgo: 11,
  }),
  makePost({
    id: "post-fabric-drop",
    designerId: "des-amara",
    caption: "New fabric drop — bring your vault measurements and pick a silhouette.",
    tags: ["fabric", "ankara"],
    priceCents: null,
    turnaround: 14,
    media: [
      { file: "outfit-w14.jpg", alt: "African print fabrics on display" },
      { file: "outfit-w10.jpg", alt: "Designer cutting cloth at a work table" },
    ],
    likes: 87,
    comments: 2,
    createdDaysAgo: 15,
  }),
  makePost({
    id: "post-chromat-look",
    designerId: "des-bisi",
    caption: "Statement eveningwear commission from last season — silhouettes like this start at ₦80k.",
    tags: ["evening", "occasion"],
    priceCents: 8_000_000,
    turnaround: 28,
    media: [{ file: "outfit-w03.jpg", alt: "Model in a statement evening look" }],
    likes: 233,
    comments: 3,
    createdDaysAgo: 20,
  }),
  makePost({
    id: "post-dance-troupe",
    designerId: "des-tunde",
    caption: "Costume set delivered for a university culture showcase — 12 pieces, one week.",
    tags: ["traditional", "group"],
    priceCents: null,
    turnaround: 7,
    media: [
      { file: "outfit-w06.jpg", alt: "Dancers performing in traditional dress" },
    ],
    likes: 164,
    comments: 2,
    createdDaysAgo: 26,
  }),
];

export const seedComments: Comment[] = [
  {
    id: "cmt-1",
    post_id: "post-ankara-gown",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Obsessed with the shoulders 😍",
    like_count: 12,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.5),
  },
  {
    id: "cmt-2",
    post_id: "post-ankara-gown",
    author: { id: "acc-bisi", username: "maisonbisi", avatar_url: null },
    body: "Beautiful work as always, Amara.",
    like_count: 8,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.2),
  },
  {
    id: "cmt-3",
    post_id: "post-asooke-set",
    author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    body: "Commissioned one of these — the weave is even better in person.",
    like_count: 21,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(3),
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
      { id: "m-1", session_id: "sess-recent-scan", name: "shoulder_width", value_cm: 42.5, source: "pipeline", confidence: 0.92 },
      { id: "m-2", session_id: "sess-recent-scan", name: "hip_width", value_cm: 36.8, source: "pipeline", confidence: 0.88 },
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
      { id: "m-3", session_id: "sess-manual-tape", name: "shoulder_width", value_cm: 42.0, source: "pipeline", confidence: null },
      { id: "m-4", session_id: "sess-manual-tape", name: "hip_width", value_cm: 37.2, source: "pipeline", confidence: null },
      { id: "m-5", session_id: "sess-manual-tape", name: "chest_girth", value_cm: 92.0, source: "pipeline", confidence: null },
      { id: "m-6", session_id: "sess-manual-tape", name: "waist_girth", value_cm: 78.5, source: "pipeline", confidence: null },
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
      { id: "m-7", session_id: "sess-old-scan", name: "shoulder_width", value_cm: 41.8, source: "pipeline", confidence: 0.81 },
      { id: "m-8", session_id: "sess-old-scan", name: "hip_width", value_cm: 37.0, source: "pipeline", confidence: 0.64 },
    ],
    pipeline_meta: { model_version: "mp2d-v1.9", qc: "pass" },
    created_at: daysAgo(140), // stale (>90d)
  },
];

// ---------------------------------------------------------------------------
// Orders — #APR-1042 (in_progress) and #APR-1058 (delivered/paid out)
// ---------------------------------------------------------------------------

export const seedOrders: CommissionRequest[] = [
  {
    id: "req-apr-1042",
    order_number: "APR-1042",
    post: {
      id: "post-ankara-gown",
      caption: "Ankara midi gown with structured shoulders",
      thumb_url: "/demo/outfit-w00.jpg",
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: { id: "des-amara", username: "amara.designs", avatar_url: null },
    status: "in_progress",
    notes: "Slightly longer sleeves than the sample, please. Event is July 26.",
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
      created_at: daysAgo(8),
    },
    events: [
      { id: "evt-1042-1", request_id: "req-apr-1042", kind: "requested", actor: "customer", created_at: daysAgo(8) },
      { id: "evt-1042-2", request_id: "req-apr-1042", kind: "quoted", actor: "designer", created_at: daysAgo(7) },
      { id: "evt-1042-3", request_id: "req-apr-1042", kind: "paid", actor: "customer", created_at: daysAgo(6) },
      { id: "evt-1042-4", request_id: "req-apr-1042", kind: "in_progress", actor: "designer", created_at: daysAgo(5) },
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
    created_at: daysAgo(8),
  },
  {
    id: "req-apr-1058",
    order_number: "APR-1058",
    post: {
      id: "post-asooke-set",
      caption: "Hand-woven aso-oke two-piece",
      thumb_url: "/demo/outfit-w13.jpg",
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: { id: "des-bisi", username: "maisonbisi", avatar_url: null },
    status: "delivered",
    notes: "For a family wedding — colour scheme attached in thread.",
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
    snapshot: {
      id: "snap-1058",
      request_id: "req-apr-1058",
      values: {
        method: "manual",
        measured_at: daysAgo(58),
        measurements: [
          { name: "shoulder_width", value_cm: 42.0 },
          { name: "hip_width", value_cm: 37.2 },
          { name: "chest_girth", value_cm: 92.0 },
          { name: "waist_girth", value_cm: 78.5 },
        ],
      },
      created_at: daysAgo(40),
    },
    events: [
      { id: "evt-1058-1", request_id: "req-apr-1058", kind: "requested", actor: "customer", created_at: daysAgo(40) },
      { id: "evt-1058-2", request_id: "req-apr-1058", kind: "quoted", actor: "designer", created_at: daysAgo(38) },
      { id: "evt-1058-3", request_id: "req-apr-1058", kind: "paid", actor: "customer", created_at: daysAgo(36) },
      { id: "evt-1058-4", request_id: "req-apr-1058", kind: "in_progress", actor: "designer", created_at: daysAgo(30) },
      { id: "evt-1058-5", request_id: "req-apr-1058", kind: "shipped", actor: "designer", created_at: daysAgo(10) },
      { id: "evt-1058-6", request_id: "req-apr-1058", kind: "delivered", actor: "customer", created_at: daysAgo(7) },
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
    created_at: daysAgo(40),
  },
];

export const seedThreadMessages = [
  {
    id: "msg-1042-1",
    request_id: "req-apr-1042",
    author_id: "acc-kiki",
    body: "Hi Amara! Excited about this one — here's my inspiration.",
    image_url: "/demo/outfit-w01.jpg",
    created_at: daysAgo(8),
  },
  {
    id: "msg-1042-2",
    request_id: "req-apr-1042",
    author_id: "des-amara",
    body: "Love it. Quote sent — I can have it ready two weeks after payment.",
    image_url: null,
    created_at: daysAgo(7),
  },
  {
    id: "msg-1042-3",
    request_id: "req-apr-1042",
    author_id: "des-amara",
    body: "Fabric cut today — progress shot attached.",
    image_url: "/demo/outfit-w14.jpg",
    created_at: daysAgo(2),
  },
  {
    id: "msg-1058-1",
    request_id: "req-apr-1058",
    author_id: "acc-kiki",
    body: "Colour scheme: burgundy and gold, please.",
    image_url: null,
    created_at: daysAgo(39),
  },
  {
    id: "msg-1058-2",
    request_id: "req-apr-1058",
    author_id: "des-bisi",
    body: "Delivered via GIG — enjoy the wedding!",
    image_url: null,
    created_at: daysAgo(10),
  },
];

// ---------------------------------------------------------------------------
// Notifications (kiki's activity sheet) + moderation queue
// ---------------------------------------------------------------------------

export const seedNotifications: Notification[] = [
  {
    id: "ntf-1",
    account_id: "acc-kiki",
    kind: "status_change",
    payload_ref: "req-apr-1042",
    text: "amara.designs started work on your order #APR-1042",
    actor: { username: "amara.designs", avatar_url: null },
    thumb_url: "/demo/outfit-w00.jpg",
    read_at: null,
    created_at: daysAgo(5),
  },
  {
    id: "ntf-2",
    account_id: "acc-kiki",
    kind: "like",
    payload_ref: "post-ankara-gown",
    text: "maisonbisi liked your comment",
    actor: { username: "maisonbisi", avatar_url: null },
    thumb_url: "/demo/outfit-w00.jpg",
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
    kind: "follow",
    payload_ref: "des-tunde",
    text: "tunde.o started following you",
    actor: { username: "tunde.o", avatar_url: null },
    thumb_url: null,
    read_at: daysAgo(12),
    created_at: daysAgo(14),
  },
];

export const seedReports: Report[] = [
  {
    id: "rep-1",
    reporter: { id: "acc-tunde", username: "tunde.o" },
    subject_kind: "comment",
    subject_id: "cmt-spam-1",
    subject_preview: {
      text: "🔥🔥 Buy followers cheap — link in bio",
      thumb_url: null,
    },
    reason: "spam",
    detail: null,
    status: "open",
    actioned_by: null,
    created_at: daysAgo(1),
  },
];

/** kiki follows amara + bisi (tunde is the "suggested designer"). */
export const seedFollows: [string, string][] = [
  ["acc-kiki", "amara.designs"],
  ["acc-kiki", "maisonbisi"],
];
