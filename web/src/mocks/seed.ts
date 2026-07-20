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

function hoursAgo(hours: number): string {
  return new Date(NOW().getTime() - hours * 60 * 60 * 1000).toISOString();
}

/**
 * daysAgo pinned to a local clock time ("09:14") — seeded history events
 * carry a plausible time-of-day cadence instead of all clustering at the
 * boot minute (PR #102 plausible-cadence rule; audit #27/#19).
 */
export function daysAgoAt(
  days: number,
  time: `${number}:${number}`,
  base: Date = NOW(),
): string {
  const date = new Date(base.getTime() - days * 24 * 60 * 60 * 1000);
  const [hour, minute] = time.split(":").map(Number);
  date.setHours(hour, minute, 0, 0);
  return date.toISOString();
}

function defaultPrefs() {
  return { quotes: true, order_status: true, social: true, payouts: true };
}

/**
 * Licensed avatar pool — the same CC photo set the Figma Assets page
 * documents and the marketing MiniScreens already ship (web/public/demo;
 * attributions stay in ATTRIBUTIONS.md there). Every seeded account carries
 * a photo avatar so the TEST_MODE boot looks like the B/C canvases (photo
 * avatars inside the freshness/story rings, never the initials fallback) —
 * web-implementation.md §6 seed contract (audit #9).
 */
const AVATARS = {
  kiki: "/demo/outfit-w16.jpg",
  amara: "/demo/outfit-w00.jpg",
  tunde: "/demo/outfit-w15.jpg",
  bisi: "/demo/outfit-w13.jpg",
  eniola: "/demo/outfit-w10.jpg",
  ada: "/demo/outfit-w01.jpg",
  funmi: "/demo/outfit-w03.jpg",
  chidi: "/demo/outfit-w06.jpg",
  zainab: "/demo/outfit-w05.jpg",
  emeka: "/demo/outfit-w14.jpg",
  // The pool holds ten photos for eleven personas; tola shares chidi's
  // group shot — their follower sheets are disjoint, so the two avatars
  // never co-render.
  tola: "/demo/outfit-w06.jpg",
} as const;

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
    avatar_url: AVATARS.kiki,
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
    avatar_url: AVATARS.amara,
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
    avatar_url: AVATARS.tunde,
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
    avatar_url: AVATARS.bisi,
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
    avatar_url: AVATARS.eniola,
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
    // Community ids mirror the AVATARS keys ("acc-ada" → AVATARS.ada).
    avatar_url: AVATARS[input.id.replace("acc-", "") as keyof typeof AVATARS],
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
    avatar_url: AVATARS.amara,
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
    avatar_url: AVATARS.tunde,
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
    avatar_url: AVATARS.bisi,
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
    avatar_url: AVATARS.eniola,
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
    author: {
      id: "acc-zainab",
      username: "zainab.k",
      avatar_url: AVATARS.zainab,
    },
    body: "An atelier this side of Abuja at last — booking for December.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.15),
  },
  {
    id: "cmt-1",
    post_id: "post-ankara-gown",
    author: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    body: "Obsessed with this print 😍",
    like_count: 4,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.5),
  },
  {
    id: "cmt-2",
    post_id: "post-ankara-gown",
    author: {
      id: "acc-bisi",
      username: "maisonbisi",
      avatar_url: AVATARS.bisi,
    },
    body: "Beautiful work as always, Amara.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.2),
  },
  {
    id: "cmt-3",
    post_id: "post-ankara-gown",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: AVATARS.funmi },
    body: "Do you have this in a longer length? Asking for a wedding guest look.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.8),
  },
  {
    id: "cmt-4",
    post_id: "post-asooke-set",
    author: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    body: "Commissioned one of these — the finish is even better in person.",
    like_count: 6,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(3),
  },
  {
    id: "cmt-5",
    post_id: "post-asooke-set",
    author: {
      id: "acc-bisi",
      username: "maisonbisi",
      avatar_url: AVATARS.bisi,
    },
    body: "@kiki.adeyemi thank you! Your little senator came out so well — one of my favourites this year.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2.8),
  },
  {
    id: "cmt-6",
    post_id: "post-asooke-set",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: AVATARS.ada },
    body: "The texture on this is unreal.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2.5),
  },
  {
    id: "cmt-7",
    post_id: "post-asooke-set",
    author: { id: "acc-tunde", username: "tunde.o", avatar_url: AVATARS.tunde },
    body: "Clean finishing as usual, Bisi. 🔥",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2),
  },
  {
    id: "cmt-8",
    post_id: "post-asooke-set",
    author: {
      id: "acc-zainab",
      username: "zainab.k",
      avatar_url: AVATARS.zainab,
    },
    body: "Could you do a lighter fabric version for Abuja heat?",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1),
  },
  {
    id: "cmt-9",
    post_id: "post-bridal-gown",
    author: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    body: "Sending this to my cousin immediately.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2.5),
  },
  {
    id: "cmt-10",
    post_id: "post-bridal-gown",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: AVATARS.funmi },
    body: "That train 😭😭",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2),
  },
  {
    id: "cmt-11",
    post_id: "post-bridal-gown",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: AVATARS.ada },
    body: "How far in advance should a bride book?",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1.5),
  },
  {
    id: "cmt-12",
    post_id: "post-bridal-gown",
    author: { id: "acc-tunde", username: "tunde.o", avatar_url: AVATARS.tunde },
    body: "Season's best, easily.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1),
  },
  {
    id: "cmt-13",
    post_id: "post-print-couple",
    author: { id: "acc-chidi", username: "chidi.n", avatar_url: AVATARS.chidi },
    body: "My fiancée just tagged me. I know what that means.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.7),
  },
  {
    id: "cmt-14",
    post_id: "post-print-couple",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: AVATARS.funmi },
    body: "Coordination without the costume feel — exactly right.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(0.4),
  },
  {
    id: "cmt-15",
    post_id: "post-agbada",
    author: { id: "acc-emeka", username: "emeka.u", avatar_url: AVATARS.emeka },
    body: "That drape — exactly what ceremony wear needed.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(5),
  },
  {
    id: "cmt-16",
    post_id: "post-agbada",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: AVATARS.ada },
    body: "My dad would love this.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(3),
  },
  {
    id: "cmt-17",
    post_id: "post-agbada",
    author: { id: "acc-tola", username: "tola.mak", avatar_url: AVATARS.tola },
    body: "Ceremony-ready indeed. Sharp.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(2),
  },
  {
    id: "cmt-18",
    post_id: "post-agbada",
    author: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    body: "Just sent a request for my brother's wedding — fingers crossed! 🤞",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(1),
  },
  {
    id: "cmt-19",
    post_id: "post-print-brothers",
    author: { id: "acc-chidi", username: "chidi.n", avatar_url: AVATARS.chidi },
    body: "Need this for my brother and me. Those collars!",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(6),
  },
  {
    id: "cmt-20",
    post_id: "post-runway-orange",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: AVATARS.funmi },
    body: "Resort season starts here.",
    like_count: 4,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(10),
  },
  {
    id: "cmt-21",
    post_id: "post-runway-orange",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: AVATARS.ada },
    body: "Saw this on the runway — stunned it's available made-to-measure.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(9.5),
  },
  {
    id: "cmt-22",
    post_id: "post-runway-orange",
    author: {
      id: "acc-zainab",
      username: "zainab.k",
      avatar_url: AVATARS.zainab,
    },
    body: "This silhouette would be perfect for a December event.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(9),
  },
  {
    id: "cmt-23",
    post_id: "post-runway-orange",
    author: { id: "acc-emeka", username: "emeka.u", avatar_url: AVATARS.emeka },
    body: "Vacation booked just for this.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(8),
  },
  {
    id: "cmt-24",
    post_id: "post-runway-orange",
    author: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    body: "This print 😍",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(7),
  },
  {
    id: "cmt-25",
    post_id: "post-runway-orange",
    author: { id: "acc-tola", username: "tola.mak", avatar_url: AVATARS.tola },
    body: "Bisi never misses.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(5),
  },
  {
    id: "cmt-26",
    post_id: "post-fabric-drop",
    author: { id: "acc-funmi", username: "funmi.b", avatar_url: AVATARS.funmi },
    body: "That second print — reserving a silhouette this week.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(14),
  },
  {
    id: "cmt-27",
    post_id: "post-fabric-drop",
    author: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    body: "Coming through with my vault numbers!",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(13),
  },
  {
    id: "cmt-28",
    post_id: "post-chromat-look",
    author: { id: "acc-ada", username: "ada.eze", avatar_url: AVATARS.ada },
    body: "Statement is an understatement.",
    like_count: 2,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(19),
  },
  {
    id: "cmt-29",
    post_id: "post-chromat-look",
    author: {
      id: "acc-zainab",
      username: "zainab.k",
      avatar_url: AVATARS.zainab,
    },
    body: "The drape on this — beautiful.",
    like_count: 0,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(18),
  },
  {
    id: "cmt-30",
    post_id: "post-chromat-look",
    author: { id: "acc-chidi", username: "chidi.n", avatar_url: AVATARS.chidi },
    body: "Saving this for my sister.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(17),
  },
  {
    id: "cmt-31",
    post_id: "post-dance-troupe",
    author: { id: "acc-emeka", username: "emeka.u", avatar_url: AVATARS.emeka },
    body: "12 pieces in a week is wild. Respect.",
    like_count: 3,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(25),
  },
  {
    id: "cmt-32",
    post_id: "post-dance-troupe",
    author: { id: "acc-tola", username: "tola.mak", avatar_url: AVATARS.tola },
    body: "The showcase was amazing — costumes made it.",
    like_count: 1,
    liked: false,
    hidden_by_moderation: false,
    created_at: daysAgo(24),
  },
];

// ---------------------------------------------------------------------------
// Vault — kiki's measurement sessions (shoulder 42.5 cm etc., freshness).
// The latest values fan out to 14 metrics (B4 frame: "14 measurements on
// file", 6-card grid + "+8 more measurements →") including one 0.62
// low-confidence exemplar so the MeasurementCard low-confidence chip is
// reachable from boot (audit #20). Scan girths come from the fresh 12d
// pipeline session; sleeve/inseam stay manual-only (tape) so the grid mixes
// Scan and Manual source chips like the canvas.
// ---------------------------------------------------------------------------

/** The 12d scan session's metric list (12 of the 14 latest values). */
const RECENT_SCAN_MEASUREMENTS: [string, number, number][] = [
  ["shoulder_width", 42.5, 0.92],
  ["hip_width", 36.8, 0.88],
  ["chest_girth", 101.5, 0.62], // the low-confidence exemplar (<0.7 chip)
  ["waist_girth", 78.4, 0.9],
  ["hip_girth", 96.2, 0.87],
  ["neck_girth", 34.6, 0.85],
  ["bicep_girth", 29.4, 0.79],
  ["wrist_girth", 15.8, 0.74],
  ["thigh_girth", 55.4, 0.83],
  ["knee_girth", 37.2, 0.8],
  ["calf_girth", 36.5, 0.81],
  ["ankle_girth", 22.1, 0.76],
];

export const seedSessions: MeasurementSession[] = [
  {
    id: "sess-recent-scan",
    customer_id: "acc-kiki",
    method: "mediapipe_2d_v2",
    input_height_cm: 168,
    status: "complete",
    measurements: RECENT_SCAN_MEASUREMENTS.map(
      ([name, value, confidence], i) => ({
        id: `m-scan-${i + 1}`,
        session_id: "sess-recent-scan",
        name,
        value_cm: value,
        source: "pipeline" as const,
        confidence,
      }),
    ),
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
      // Tape-only metrics the scan doesn't produce — these stay the latest
      // values, so the B4 grid mixes Manual chips among the Scan ones.
      {
        id: "m-6b",
        session_id: "sess-manual-tape",
        name: "sleeve_length",
        value_cm: 58.0,
        source: "pipeline",
        confidence: null,
      },
      {
        id: "m-6c",
        session_id: "sess-manual-tape",
        name: "inseam_length",
        value_cm: 81.0,
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

/**
 * Snapshot value lists — orders freeze whichever vault session existed at
 * request time. Recent orders freeze the full 12-metric scan (B3 frame:
 * four chips + "+N more"); older ones freeze the 6-metric tape session.
 */
const SCAN_SNAPSHOT_VALUES = RECENT_SCAN_MEASUREMENTS.map(
  ([name, value_cm]) => ({ name, value_cm }),
);
const MANUAL_SNAPSHOT_VALUES = [
  { name: "shoulder_width", value_cm: 42.0 },
  { name: "hip_width", value_cm: 37.2 },
  { name: "chest_girth", value_cm: 92.0 },
  { name: "waist_girth", value_cm: 78.5 },
  { name: "sleeve_length", value_cm: 58.0 },
  { name: "inseam_length", value_cm: 81.0 },
];

/**
 * Timeline events land at plausible business-hour clock times (B3 frame
 * cadence: 09:14 / 14:02 / 10:26 / 09:40), minute-varied per order — not
 * all stamped at the boot minute (PR #102 plausible-cadence rule, audit
 * #27). Fresh (<1d) events keep their exact relative offset so they stay
 * coherent with the notifications that reference them ("6h ago").
 */
const EVENT_CLOCK: Record<string, [number, number]> = {
  requested: [9, 14],
  quoted: [14, 2],
  paid: [10, 26],
  in_progress: [9, 40],
  shipped: [11, 5],
  delivered: [16, 20],
  declined: [13, 45],
  disputed: [18, 32],
  refunded: [12, 10],
  cancelled: [8, 55],
};

function eventTimestamp(kind: string, daysBack: number, num: number): string {
  if (daysBack < 1) return daysAgo(daysBack);
  const [hour, minute] = EVENT_CLOCK[kind] ?? [12, 0];
  return daysAgoAt(daysBack, `${hour}:${(minute + (num % 9)) % 60}`);
}

function makeOrder(input: SeedOrderInput): CommissionRequest {
  const post = postById(input.postId);
  const id = `req-apr-${input.num}`;
  const quote = input.quote ?? null;
  return {
    id,
    order_number: `APR-${input.num}`,
    post: {
      id: post.id,
      caption: post.caption.split(" — ")[0],
      thumb_url: post.media[0].url,
    },
    customer: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
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
              measurements: SCAN_SNAPSHOT_VALUES,
            }
          : input.createdDaysAgo <= 58
            ? {
                method: "manual",
                measured_at: daysAgo(58),
                measurements: MANUAL_SNAPSHOT_VALUES,
              }
            : {
                method: "mediapipe_2d",
                measured_at: daysAgo(140),
                measurements: [
                  { name: "shoulder_width", value_cm: 41.8 },
                  { name: "hip_width", value_cm: 37.0 },
                ],
              },
      created_at: daysAgo(input.createdDaysAgo),
    },
    events: input.events.map((e, i) => ({
      id: `evt-${input.num}-${i}`,
      request_id: id,
      kind: e.kind,
      actor: e.actor,
      created_at: eventTimestamp(e.kind, e.at, input.num),
    })),
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
    created_at: daysAgo(input.createdDaysAgo),
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
    customer: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    designer: {
      id: "des-amara",
      username: "amara.designs",
      avatar_url: AVATARS.amara,
    },
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
        // Full 12-metric scan freeze — B3 renders four chips + "+8 more".
        measurements: SCAN_SNAPSHOT_VALUES,
      },
      created_at: daysAgo(8),
    },
    events: [
      {
        id: "evt-1042-1",
        request_id: "req-apr-1042",
        kind: "requested",
        actor: "customer",
        created_at: daysAgoAt(8, "9:14"),
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
        created_at: daysAgoAt(5, "9:40"),
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
    created_at: daysAgo(8),
  },
  {
    id: "req-apr-1058",
    order_number: "APR-1058",
    post: {
      id: "post-asooke-set",
      caption: "Little senator",
      thumb_url: "/demo/outfit-w13.jpg",
    },
    customer: {
      id: "acc-kiki",
      username: "kiki.adeyemi",
      avatar_url: AVATARS.kiki,
    },
    designer: {
      id: "des-bisi",
      username: "maisonbisi",
      avatar_url: AVATARS.bisi,
    },
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
      created_at: daysAgo(40),
    },
    events: [
      {
        id: "evt-1058-1",
        request_id: "req-apr-1058",
        kind: "requested",
        actor: "customer",
        created_at: daysAgoAt(40, "10:12"),
      },
      {
        id: "evt-1058-2",
        request_id: "req-apr-1058",
        kind: "quoted",
        actor: "designer",
        created_at: daysAgoAt(38, "15:37"),
      },
      {
        id: "evt-1058-3",
        request_id: "req-apr-1058",
        kind: "paid",
        actor: "customer",
        created_at: daysAgoAt(36, "11:48"),
      },
      {
        id: "evt-1058-4",
        request_id: "req-apr-1058",
        kind: "in_progress",
        actor: "designer",
        created_at: daysAgoAt(30, "9:05"),
      },
      {
        id: "evt-1058-5",
        request_id: "req-apr-1058",
        kind: "shipped",
        actor: "designer",
        created_at: daysAgoAt(10, "14:56"),
      },
      {
        id: "evt-1058-6",
        request_id: "req-apr-1058",
        kind: "delivered",
        actor: "customer",
        created_at: daysAgoAt(7, "17:23"),
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
    created_at: daysAgo(40),
  },
  makeOrder({
    num: 1031,
    postId: "post-agbada",
    status: "requested",
    createdDaysAgo: 1,
    budget: 6_000_000,
    notes: "Need it for my brother's wedding in August.",
    events: [{ kind: "requested", actor: "customer", at: 1 }],
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
      { kind: "requested", actor: "customer", at: 3 },
      // 0.25d = 6h — matches the unread "quoted ₦40,000" notification.
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
      { kind: "requested", actor: "customer", at: 6 },
      { kind: "quoted", actor: "designer", at: 5 },
      { kind: "paid", actor: "customer", at: 4 },
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
      { kind: "requested", actor: "customer", at: 20 },
      { kind: "quoted", actor: "designer", at: 19 },
      { kind: "paid", actor: "customer", at: 18 },
      { kind: "in_progress", actor: "designer", at: 15 },
      { kind: "shipped", actor: "designer", at: 3 },
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
      { kind: "requested", actor: "customer", at: 25 },
      { kind: "quoted", actor: "designer", at: 24 },
      { kind: "paid", actor: "customer", at: 22 },
      { kind: "in_progress", actor: "designer", at: 20 },
      { kind: "disputed", actor: "customer", at: 2 },
    ],
  }),
  makeOrder({
    num: 1012,
    postId: "post-fabric-drop",
    status: "declined",
    createdDaysAgo: 30,
    decline: "workload",
    events: [
      { kind: "requested", actor: "customer", at: 30 },
      { kind: "declined", actor: "designer", at: 29 },
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
      { kind: "requested", actor: "customer", at: 60 },
      { kind: "quoted", actor: "designer", at: 58 },
      { kind: "paid", actor: "customer", at: 55 },
      { kind: "refunded", actor: "system", at: 41 },
    ],
  }),
  makeOrder({
    num: 1005,
    postId: "post-chromat-look",
    status: "cancelled",
    createdDaysAgo: 45,
    events: [
      { kind: "requested", actor: "customer", at: 45 },
      { kind: "cancelled", actor: "customer", at: 44 },
    ],
  }),
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
    body: "Colour scheme: royal blue and white, please — same as the post.",
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
  // The helper-built orders carry short, state-appropriate exchanges so
  // every thread reads like a real buyer–designer conversation.
  {
    id: "msg-1031-1",
    request_id: "req-apr-1031",
    author_id: "acc-kiki",
    body: "Sent the request — it's for my brother's wedding on Aug 22. Can you match the fabric in your post?",
    image_url: null,
    created_at: daysAgo(1),
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
    created_at: daysAgo(0.25),
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
    created_at: daysAgo(3),
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
    created_at: daysAgo(29),
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
    actor: { username: "amara.designs", avatar_url: AVATARS.amara },
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
    actor: { username: "maisonbisi", avatar_url: AVATARS.bisi },
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
    actor: { username: "kiki.adeyemi", avatar_url: AVATARS.kiki },
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
    actor: { username: "kiki.adeyemi", avatar_url: AVATARS.kiki },
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
    actor: { username: "amara.designs", avatar_url: AVATARS.amara },
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
    actor: { username: "maisonbisi", avatar_url: AVATARS.bisi },
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
    actor: { username: "maisonbisi", avatar_url: AVATARS.bisi },
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
    actor: { username: "ada.eze", avatar_url: AVATARS.ada },
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
    actor: { username: "funmi.b", avatar_url: AVATARS.funmi },
    thumb_url: null,
    read_at: daysAgo(2),
    created_at: daysAgo(3),
  },
];

/**
 * B7a moderation queue anatomy from boot (audit #19): an open reported
 * POST, an open reported comment, and an ACTIONED exemplar with its audit
 * line. Reporters and the moderator are seed personas (kiki is the staff
 * account); the reported-content authors are deliberately off-graph bad
 * actors — spam/harassment comes from outside the healthy social graph,
 * so the queue never maligns a core persona.
 */
export const seedReports: Report[] = [
  {
    id: "rep-post-spam",
    reporter: { id: "acc-tunde", username: "tunde.o" },
    subject_kind: "post",
    subject_id: "post-bulk-knockoffs",
    subject_preview: {
      text: "Bulk ankara sets — 90% off, DM for catalogue 🔥🔥",
      thumb_url: "/demo/outfit-w14.jpg",
      author_username: "lagos.bulk.wears",
    },
    reason: "spam",
    detail: null,
    status: "open",
    action: null,
    actioned_by: null,
    actioned_at: null,
    created_at: hoursAgo(2),
  },
  {
    id: "rep-1",
    reporter: { id: "acc-amara", username: "amara.designs" },
    subject_kind: "comment",
    subject_id: "cmt-spam-1",
    subject_preview: {
      text: "🔥🔥 Buy followers cheap — link in bio",
      thumb_url: null,
      author_username: "fitfluence.ng",
    },
    reason: "spam",
    detail: null,
    status: "open",
    action: null,
    actioned_by: null,
    actioned_at: null,
    created_at: hoursAgo(4),
  },
  {
    id: "rep-actioned",
    reporter: { id: "acc-funmi", username: "funmi.b" },
    subject_kind: "comment",
    subject_id: "cmt-hidden-1",
    subject_preview: {
      text: "Your “designs” are traced from other people’s work — everyone knows.",
      thumb_url: null,
      author_username: "no.filter.lagos",
    },
    reason: "harassment",
    detail: null,
    status: "actioned",
    action: "hide_post",
    actioned_by: "kiki.adeyemi",
    actioned_at: daysAgoAt(1, "09:12"),
    created_at: daysAgoAt(2, "17:40"),
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
