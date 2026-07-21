// Home marketing demo data — the docs-coherent Figma dataset the enriched
// landing renders (canvas 186:2): the hero phone-mock feed, the walkthrough
// and deep-dive mini previews, and the A6 earnings figures. This is the
// controller-owned data source for the public page (views render-only; no
// network on the marketing surface — same narrative as the mock-server
// seed, demo content only, never product claims).
import type { CommissionRequest, Earnings, OrderStatus, Post } from "@/models";

function hoursAgo(hours: number): string {
  return new Date(Date.now() - hours * 3_600_000).toISOString();
}

function daysAgo(days: number): string {
  return hoursAgo(days * 24);
}

// ---- Hero phone mock (A2) ---------------------------------------------------

export interface DemoStory {
  username: string;
  avatarUrl: string | null;
  state: "unseen" | "seen";
}

/** Story rail per the canvas: amara / tunde.a / kiki unseen, zuri / bisi seen. */
export const heroStories: DemoStory[] = [
  { username: "amara", avatarUrl: "/demo/outfit-w00.jpg", state: "unseen" },
  { username: "tunde.a", avatarUrl: "/demo/outfit-w15.jpg", state: "unseen" },
  { username: "kiki", avatarUrl: "/demo/outfit-w16.jpg", state: "unseen" },
  { username: "zuri", avatarUrl: "/demo/outfit-w05.jpg", state: "seen" },
  { username: "bisi", avatarUrl: "/demo/outfit-w13.jpg", state: "seen" },
];

function makeHeroPost(input: {
  id: string;
  username: string;
  displayName: string;
  avatar: string;
  caption: string;
  media: { file: string; alt: string }[];
  likes: number;
  createdHoursAgo: number;
}): Post {
  return {
    id: input.id,
    designer: {
      id: `des-${input.username}`,
      username: input.username,
      display_name: input.displayName,
      avatar_url: input.avatar,
      verified: false, // canvas post headers carry no verified badge
    },
    caption: input.caption,
    style_tags: [],
    base_price_cents: null,
    currency: "NGN",
    turnaround_days: 14,
    media: input.media.map((m, position) => ({
      id: `${input.id}-m${position}`,
      post_id: input.id,
      url: `/demo/${m.file}`,
      position,
      alt_text: m.alt,
      width: 1024,
      height: 1280,
    })),
    like_count: input.likes,
    comment_count: 0,
    liked: false,
    saved: false,
    created_at: hoursAgo(input.createdHoursAgo),
  };
}

/** The two feed posts on the canvas (186:35/186:36). */
export const heroPosts: Post[] = [
  makeHeroPost({
    id: "demo-ankara-two-piece",
    username: "amara.designs",
    displayName: "Amara Designs",
    avatar: "/demo/outfit-w00.jpg",
    caption:
      "Ankara two-piece with structured shoulders, made to your measurements — DM slots open for June.",
    media: [
      { file: "outfit-w00.jpg", alt: "Model in a vibrant ankara two-piece" },
    ],
    likes: 2_141,
    createdHoursAgo: 2,
  }),
  makeHeroPost({
    id: "demo-asooke-set",
    username: "kikithreads",
    displayName: "Kiki Threads",
    avatar: "/demo/outfit-w16.jpg",
    caption:
      "Matching aso-oke set — hand-loomed in Ilorin, sized from your vault.",
    media: [
      { file: "outfit-w13.jpg", alt: "Matching aso-oke set at a ceremony" },
      { file: "outfit-w14.jpg", alt: "Aso-oke fabric detail" },
      { file: "outfit-w10.jpg", alt: "Designer at the loom" },
      { file: "outfit-w06.jpg", alt: "Aso-oke set worn by dancers" },
      { file: "outfit-w16.jpg", alt: "Couple in matching aso-oke" },
    ],
    likes: 3_872,
    createdHoursAgo: 5,
  }),
];

// ---- Demo orders (hero request scene · walkthrough/deep-dive thumbs) --------

export function makeDemoOrder(
  status: OrderStatus,
  overrides: Partial<CommissionRequest> = {},
): CommissionRequest {
  return {
    id: `demo-req-${status}`,
    order_number: "APR-1042",
    post: {
      id: "demo-ankara-two-piece",
      caption: "Ankara two-piece with structured shoulders",
      thumb_url: "/demo/outfit-w00.jpg",
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: {
      id: "des-amara",
      username: "amara.designs",
      avatar_url: "/demo/outfit-w00.jpg",
    },
    status,
    notes: "",
    budget_cents: 5_000_000,
    quote_cents: 4_500_000,
    currency: "NGN",
    due_at: daysAgo(-10),
    target_date: null,
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
      id: "demo-snap",
      request_id: `demo-req-${status}`,
      values: {
        method: "mediapipe_2d_v2",
        measured_at: daysAgo(12),
        measurements: [
          { name: "shoulder_width", value_cm: 42.5 },
          { name: "hip_width", value_cm: 36.8 },
        ],
      },
      created_at: daysAgo(6),
    },
    events: [],
    payment:
      status === "paid" || status === "in_progress" || status === "shipped"
        ? {
            id: "demo-pay",
            request_id: `demo-req-${status}`,
            provider: "paystack",
            state: "held",
            currency: "NGN",
            amount_cents: 4_500_000,
            platform_fee_cents: 450_000,
          }
        : null,
    created_at: daysAgo(6),
    ...overrides,
  };
}

/** The order the hero's "request" scene and the order-detail thumb show. */
export const heroOrder = makeDemoOrder("in_progress");

/**
 * Orders-list thumbs (canvas 264:8164…): varied outfits/designers across a
 * slice of the ×10 pill set.
 */
export const demoOrders: CommissionRequest[] = [
  makeDemoOrder("quoted", {
    id: "demo-req-quoted",
    order_number: "APR-1046",
    post: {
      id: "demo-asooke-wrap",
      caption: "Aso-oke wrap set",
      thumb_url: "/demo/outfit-w13.jpg",
    },
    designer: {
      id: "des-kiki",
      username: "kikithreads",
      avatar_url: "/demo/outfit-w16.jpg",
    },
    quote_cents: 6_200_000,
  }),
  makeDemoOrder("in_progress", {
    id: "demo-req-in-progress",
    order_number: "APR-1044",
    post: {
      id: "demo-agbada",
      caption: "Agbada jacket — ceremony cut",
      thumb_url: "/demo/outfit-w15.jpg",
    },
    designer: {
      id: "des-tunde",
      username: "tunde.o",
      avatar_url: "/demo/outfit-w15.jpg",
    },
    quote_cents: 8_800_000,
  }),
  makeDemoOrder("shipped", {
    id: "demo-req-shipped",
    order_number: "APR-1042",
  }),
  makeDemoOrder("delivered", {
    id: "demo-req-delivered",
    order_number: "APR-1039",
    post: {
      id: "demo-print-couple",
      caption: "Matching print set for two",
      thumb_url: "/demo/outfit-w16.jpg",
    },
    quote_cents: 3_800_000,
  }),
  makeDemoOrder("declined", {
    id: "demo-req-declined",
    order_number: "APR-1035",
    post: {
      id: "demo-evening",
      caption: "Statement eveningwear",
      thumb_url: "/demo/outfit-w03.jpg",
    },
    designer: {
      id: "des-bisi",
      username: "maisonbisi",
      avatar_url: "/demo/outfit-w03.jpg",
    },
    quote_cents: 8_000_000,
  }),
];

// ---- Vault + explore thumbs -------------------------------------------------

export interface DemoMeasurement {
  name: string;
  valueCm: number;
  source: "scan" | "manual";
  history: number[];
  /** MeasurementCard low-confidence chip (<0.7) — canvas 264:19. */
  confidence?: number;
}

// The canvas vault set (264:14–264:19): shoulder/hip/sleeve · waist/inseam/
// chest, chest carrying the low-confidence 0.62 chip.
export const demoMeasurements: DemoMeasurement[] = [
  {
    name: "Shoulder width",
    valueCm: 42.5,
    source: "scan",
    history: [41.8, 42.1, 42.5],
  },
  {
    name: "Hip circumference",
    valueCm: 96.2,
    source: "scan",
    history: [95.4, 95.9, 96.2],
  },
  {
    name: "Sleeve length",
    valueCm: 58.0,
    source: "manual",
    history: [57.6, 57.8, 58.0],
  },
  { name: "Waist", valueCm: 78.4, source: "scan", history: [79.1, 78.8, 78.4] },
  {
    name: "Inseam",
    valueCm: 81.0,
    source: "manual",
    history: [80.4, 80.7, 81.0],
  },
  {
    name: "Chest circumference",
    valueCm: 101.5,
    source: "scan",
    history: [100.8, 101.2, 101.5],
    confidence: 0.62,
  },
];

export const demoGridImages: { src: string; alt: string }[] = [
  { src: "/demo/outfit-w00.jpg", alt: "Ankara gown" },
  { src: "/demo/outfit-w01.jpg", alt: "Ankara look, full length" },
  { src: "/demo/outfit-w03.jpg", alt: "Statement evening look" },
  { src: "/demo/outfit-w05.jpg", alt: "Orange runway outfit" },
  { src: "/demo/outfit-w06.jpg", alt: "Dancers in traditional dress" },
  { src: "/demo/outfit-w10.jpg", alt: "Designer cutting cloth" },
  { src: "/demo/outfit-w13.jpg", alt: "Aso-oke outfit" },
  { src: "/demo/outfit-w14.jpg", alt: "African print fabrics" },
  { src: "/demo/outfit-w15.jpg", alt: "Matching print shirts" },
];

// Canvas explore filter row (264:8040): "near me" leads selected; the
// dashboard variant appends a removable "Lagos" chip.
export const demoExploreChips = [
  "Near me",
  "Ankara",
  "Aso-oke",
  "Bridal",
  "₦ under 50k",
  "2-week turnaround",
];

// ---- A6 designer earnings (canvas 186:133/140/150) ---------------------------

export interface DemoTransaction {
  entry: Earnings["transactions"][number];
  /** Canvas free-text first line (TransactionRow label override). */
  label: string;
}

export const designerEarningsDemo: {
  earnings: Earnings;
  transactions: DemoTransaction[];
} = {
  earnings: {
    balance_cents: 8_250_000, // ₦82,500 released
    pending_cents: 4_500_000, // ₦45,000 in escrow
    currency: "NGN",
    transactions: [],
  },
  transactions: [
    {
      entry: {
        id: "demo-t1",
        kind: "payout",
        amount_cents: -8_250_000,
        currency: "NGN",
        order_number: "APR-1038",
        provider_ref: "PSK-8843763",
        created_at: daysAgo(4), // Jul 14 on the canvas
      },
      // "••• last4" is the one masked-account idiom (store display,
      // EarningsView payout card, Figma A6/B9 rows) — was a stray "••••".
      label: "Payout to GTBank ••• 4521",
    },
    {
      entry: {
        id: "demo-t2",
        kind: "escrow_held",
        amount_cents: 4_500_000,
        currency: "NGN",
        order_number: "APR-1042",
        provider_ref: "PSK-9841577",
        created_at: daysAgo(6), // Jul 12 on the canvas
      },
      label: "Escrow held · order #APR-1042",
    },
  ],
};
