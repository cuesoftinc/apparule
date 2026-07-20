// Shared test fixtures for the component unit tests — mirrors the mock-seed
// narrative so tests and gallery read the same story.
import type {
  Comment,
  CommissionRequest,
  Earnings,
  MeasurementSession,
  Notification,
  Post,
  Report,
} from "@/models";

export function daysAgo(days: number): string {
  return new Date(Date.now() - days * 86_400_000).toISOString();
}

export const fixturePost: Post = {
  id: "post-ankara-gown",
  designer: {
    id: "des-amara",
    username: "amara.designs",
    display_name: "Amara Designs",
    avatar_url: null,
    verified: true,
  },
  caption:
    "Ankara midi gown with structured shoulders — made to your exact measurements. DM slots open for June.",
  style_tags: ["ankara", "gown"],
  base_price_cents: 4_500_000,
  currency: "NGN",
  turnaround_days: 14,
  media: [
    {
      id: "m0",
      post_id: "post-ankara-gown",
      url: "/demo/outfit-w00.jpg",
      position: 0,
      alt_text: "Model in a vibrant ankara gown",
      width: 1024,
      height: 1280,
    },
    {
      id: "m1",
      post_id: "post-ankara-gown",
      url: "/demo/outfit-w01.jpg",
      position: 1,
      alt_text: "Ankara look, full-length",
      width: 1024,
      height: 1280,
    },
  ],
  like_count: 214,
  comment_count: 3,
  liked: false,
  saved: false,
  created_at: daysAgo(2),
};

export const fixtureOrder: CommissionRequest = {
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
    id: "snap",
    request_id: "req-apr-1042",
    values: {
      method: "mediapipe_2d_v2",
      measured_at: daysAgo(12),
      measurements: [{ name: "shoulder_width", value_cm: 42.5 }],
    },
    created_at: daysAgo(8),
  },
  events: [],
  payment: null,
  created_at: daysAgo(8),
};

export const fixtureComment: Comment = {
  id: "c1",
  post_id: "post-ankara-gown",
  author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
  body: "Obsessed with the shoulders",
  like_count: 12,
  liked: false,
  hidden_by_moderation: false,
  created_at: daysAgo(1),
};

export const fixtureSession: MeasurementSession = {
  id: "sess-1",
  customer_id: "acc-kiki",
  method: "mediapipe_2d_v2",
  input_height_cm: 168,
  status: "complete",
  measurements: [
    {
      id: "m1",
      session_id: "sess-1",
      name: "shoulder_width",
      value_cm: 42.5,
      source: "pipeline",
      confidence: 0.92,
    },
    {
      id: "m2",
      session_id: "sess-1",
      name: "hip_width",
      value_cm: 36.8,
      source: "pipeline",
      confidence: 0.88,
    },
  ],
  pipeline_meta: {},
  created_at: daysAgo(12),
};

export const fixtureNotification: Notification = {
  id: "n1",
  account_id: "acc-kiki",
  kind: "status_change",
  payload_ref: "req-apr-1042",
  text: "amara.designs started work on your order #APR-1042",
  actor: { username: "amara.designs", avatar_url: null },
  thumb_url: "/demo/outfit-w00.jpg",
  read_at: null,
  created_at: daysAgo(0.2),
};

export const fixtureReport: Report = {
  id: "rep-1",
  reporter: { id: "acc-tunde", username: "tunde.o" },
  subject_kind: "comment",
  subject_id: "cmt-spam-1",
  subject_preview: {
    text: "Buy followers cheap — link in bio",
    thumb_url: null,
    author_username: "fitfluence.ng",
  },
  reason: "spam",
  detail: null,
  status: "open",
  action: null,
  actioned_by: null,
  actioned_at: null,
  created_at: daysAgo(1),
};

export const fixtureEarnings: Earnings = {
  balance_cents: 5_580_000,
  pending_cents: 4_050_000,
  currency: "NGN",
  transactions: [
    {
      id: "t1",
      kind: "payout",
      amount_cents: 5_580_000,
      currency: "NGN",
      order_number: "#APR-1058",
      provider_ref: "PSTK-TRF-1058",
      created_at: daysAgo(7),
    },
    {
      id: "t2",
      kind: "fee_line",
      amount_cents: -620_000,
      currency: "NGN",
      order_number: "#APR-1058",
      provider_ref: null,
      created_at: daysAgo(7),
    },
    {
      id: "t3",
      kind: "escrow_held",
      amount_cents: 4_050_000,
      currency: "NGN",
      order_number: "#APR-1042",
      provider_ref: null,
      created_at: daysAgo(6),
    },
  ],
};
