"use client";

// The QA-loop gallery body — renders every W1 component in its variant
// axes. Sample data mirrors the mock-server seed narrative.
import { useState, type ReactNode } from "react";
import { MoreHorizontal, Ruler } from "lucide-react";
import type {
  Comment,
  CommissionRequest,
  Earnings,
  MeasurementSession,
  Notification,
  OrderStatus,
  Post,
  Report,
} from "@/models";
import { ActionRow } from "@/components/ui/ActionRow";
import { AddressFieldset } from "@/components/ui/AddressFieldset";
import { AppBar } from "@/components/ui/AppBar";
import { Avatar } from "@/components/ui/Avatar";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { CaptureOptionCard } from "@/components/ui/CaptureOptionCard";
import { CaptureOverlay } from "@/components/ui/CaptureOverlay";
import { CaptureResults } from "@/components/ui/CaptureResults";
import { CaughtUpDivider } from "@/components/ui/CaughtUpDivider";
import { CountdownRing } from "@/components/ui/CountdownRing";
import { Chip } from "@/components/ui/Chip";
import { CodeSnippetBlock } from "@/components/ui/CodeSnippetBlock";
import { CommentRow } from "@/components/ui/CommentRow";
import { CommunityCard } from "@/components/ui/CommunityCard";
import { ComparisonTable } from "@/components/ui/ComparisonTable";
import { DateInput, minDueDate } from "@/components/ui/DateInput";
import {
  EarningsSummary,
  TransactionRow,
} from "@/components/ui/EarningsSummary";
import { EmptyState, type EmptyStateContext } from "@/components/ui/EmptyState";
import { FAQGroup, FAQItem } from "@/components/ui/FAQItem";
import { FormRow } from "@/components/ui/FormRow";
import { GoogleAuthButton } from "@/components/ui/GoogleAuthButton";
import { GridTile } from "@/components/ui/GridTile";
import { MarketingFooter } from "@/components/ui/MarketingFooter";
import { MarketingNav } from "@/components/ui/MarketingNav";
import { IconButton } from "@/components/ui/IconButton";
import { Input } from "@/components/ui/Input";
import { ManualMeasureRow } from "@/components/ui/ManualMeasureRow";
import { MeasurementCard } from "@/components/ui/MeasurementCard";
import { MediaDropzone, MediaUploadTile } from "@/components/ui/MediaDropzone";
import { ModerationQueueRow } from "@/components/ui/ModerationQueueRow";
import { NavRail } from "@/components/ui/NavRail";
import { NotificationRow } from "@/components/ui/NotificationRow";
import { OrderTimelineRow } from "@/components/ui/OrderTimelineRow";
import { PaymentBox, type PaymentBoxState } from "@/components/ui/PaymentBox";
import { Popover, MenuItem } from "@/components/ui/Popover";
import { PostCard } from "@/components/ui/PostCard";
import { ProcessingConstellation } from "@/components/ui/ProcessingConstellation";
import {
  QCHintChip,
  QC_GUIDANCE,
  type QcFailCode,
} from "@/components/ui/QCHintChip";
import { RequestCard } from "@/components/ui/RequestCard";
import { Select } from "@/components/ui/Select";
import { SessionRow } from "@/components/ui/SessionRow";
import { Sheet } from "@/components/ui/Sheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { Spinner } from "@/components/ui/Spinner";
import { StatCard } from "@/components/ui/StatCard";
import { StatusPill } from "@/components/ui/StatusPill";
import { StoryRailItem } from "@/components/ui/StoryRailItem";
import { Switch } from "@/components/ui/Switch";
import { TabBar } from "@/components/ui/TabBar";
import { Tabs } from "@/components/ui/Tabs";
import { ThreadBubble } from "@/components/ui/ThreadBubble";
import { Toast } from "@/components/ui/Toast";
import { Tooltip } from "@/components/ui/Tooltip";
import { UserRow } from "@/components/ui/UserRow";
import { WalkthroughStep } from "@/components/ui/WalkthroughStep";

function daysAgo(days: number): string {
  return new Date(Date.now() - days * 86_400_000).toISOString();
}

const samplePost: Post = {
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

const sampleOrder: CommissionRequest = {
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
      measurements: [],
    },
    created_at: daysAgo(8),
  },
  events: [],
  payment: null,
  created_at: daysAgo(8),
};

const sampleComment: Comment = {
  id: "c1",
  post_id: "post-ankara-gown",
  author: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
  body: "Obsessed with the shoulders 😍",
  like_count: 12,
  liked: false,
  hidden_by_moderation: false,
  created_at: daysAgo(1),
};

const sampleSession: MeasurementSession = {
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

const agingSession: MeasurementSession = {
  ...sampleSession,
  id: "sess-2",
  method: "manual",
  created_at: daysAgo(58),
};

const sampleNotification: Notification = {
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

const sampleReport: Report = {
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
  created_at: daysAgo(1),
};

const sampleEarnings: Earnings = {
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

const ORDER_STATUSES: OrderStatus[] = [
  "requested",
  "quoted",
  "paid",
  "in_progress",
  "shipped",
  "delivered",
  "refunded",
  "declined",
  "disputed",
  "cancelled",
];

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section
      id={title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}
      className="flex flex-col gap-4 border-b border-border py-8"
    >
      <h2 className="text-title font-bold text-text">{title}</h2>
      {children}
    </section>
  );
}

function Row({ label, children }: { label?: string; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      {label ? <span className="text-caption text-text-2">{label}</span> : null}
      <div className="flex flex-wrap items-center gap-4">{children}</div>
    </div>
  );
}

export function ComponentGallery() {
  const [sheetOpen, setSheetOpen] = useState(false);
  const [switchOn, setSwitchOn] = useState(true);
  const [tab, setTab] = useState<"first" | "second">("first");
  const [tabBarKey, setTabBarKey] = useState("home");
  const [countdown, setCountdown] = useState<1 | 2 | 3>(3);
  const [iconTab, setIconTab] = useState<"first" | "second">("first");
  const [unit, setUnit] = useState<"cm" | "in">("cm");
  const [shoulder, setShoulder] = useState<number | null>(42.5);
  const [selectValue, setSelectValue] = useState<string | undefined>();
  const [date, setDate] = useState<Date | null>(null);
  const [address, setAddress] = useState<Record<string, string>>({});
  const [liked, setLiked] = useState(false);
  const [saved, setSaved] = useState(false);
  const [payState, setPayState] = useState<PaymentBoxState>("quoted");

  return (
    <main className="mx-auto flex max-w-4xl flex-col px-6 pb-24">
      <h1 className="pt-10 text-display font-bold text-text">
        Component gallery
      </h1>
      <p className="text-body text-text-2">
        Stage W1 · every §8.2/§8.2b web-relevant set in its variants — the QA
        loop compares these against the Figma masters.
      </p>

      <Section title="Button">
        <Row label="kind × default">
          <Button kind="gradient-primary">Request this outfit</Button>
          <Button kind="quiet">Following</Button>
          <Button kind="destructive">Delete session</Button>
          <Button kind="link">View order</Button>
        </Row>
        <Row label="size sm · loading · disabled">
          <Button kind="gradient-primary" size="sm">
            Follow
          </Button>
          <Button kind="gradient-primary" loading>
            Paying…
          </Button>
          <Button kind="quiet" disabled>
            Unavailable
          </Button>
        </Row>
      </Section>

      <Section title="GoogleAuthButton">
        <div className="max-w-sm">
          <GoogleAuthButton />
        </div>
      </Section>

      <Section title="Input">
        <div className="grid max-w-xl grid-cols-2 gap-4">
          <Input placeholder="Display name" aria-label="Text input" />
          <Input
            kind="search"
            placeholder="Search designers, styles…"
            aria-label="Search"
          />
          <Input
            kind="numeric"
            placeholder="42.5"
            aria-label="Shoulder width"
            unit={unit}
            onUnitChange={setUnit}
          />
          <Input kind="currency" placeholder="45,000" aria-label="Budget" />
          <Input
            placeholder="Username"
            error="That username is taken"
            aria-label="Errored input"
          />
          <Input placeholder="Disabled" disabled aria-label="Disabled input" />
        </div>
        <div className="max-w-xl">
          <Input
            kind="textarea"
            placeholder="Notes for the designer…"
            aria-label="Notes"
            maxLength={500}
          />
        </div>
      </Section>

      <Section title="Chip">
        <Row>
          <Chip label="ankara" />
          <Chip kind="selected" label="aso-oke" />
          <Chip kind="removable" label="near me" onRemove={() => {}} />
        </Row>
      </Section>

      <Section title="IconButton">
        <Row>
          <IconButton aria-label="More options">
            <MoreHorizontal size={24} />
          </IconButton>
          <IconButton aria-label="More options" size="sm">
            <MoreHorizontal size={24} />
          </IconButton>
          <IconButton aria-label="Disabled" disabled>
            <MoreHorizontal size={24} />
          </IconButton>
        </Row>
      </Section>

      <Section title="Toast">
        <div className="flex max-w-sm flex-col gap-3">
          <Toast
            kind="success"
            message="Saved to your looks"
            autoDismissMs={0}
          />
          <Toast
            kind="error"
            message="Couldn't like the post"
            onRetry={() => {}}
            autoDismissMs={0}
          />
          <Toast kind="neutral" message="Link copied" autoDismissMs={0} />
        </div>
      </Section>

      <Section title="Avatar">
        <Row label="sizes">
          <Avatar size={32} name="Kiki Adeyemi" />
          <Avatar size={44} name="Amara Designs" verified />
          <Avatar size={56} name="Tunde Okonkwo" />
          <Avatar size={96} name="Maison Bisi" />
        </Row>
        <Row label="rings — fresh / aging / stale (MI-11)">
          <Avatar size={56} name="Kiki Adeyemi" ring="gradient" />
          <Avatar size={56} name="Kiki Adeyemi" ring="amber" />
          <Avatar size={56} name="Kiki Adeyemi" ring="gray" />
        </Row>
      </Section>

      <Section title="StoryRailItem">
        <Row>
          <StoryRailItem username="amara.designs" state="unseen" />
          <StoryRailItem username="maisonbisi" state="seen" />
          <StoryRailItem username="tunde.o" state="loading" />
        </Row>
      </Section>

      <Section title="ActionRow">
        <div className="max-w-sm">
          <ActionRow
            liked={liked}
            saved={saved}
            likeCount={214 + (liked ? 1 : 0)}
            onToggleLike={() => setLiked((v) => !v)}
            onToggleSave={() => setSaved((v) => !v)}
          />
        </div>
      </Section>

      <Section title="StatusPill">
        <Row label="order states (token mapping, decided 2026-07-16)">
          {ORDER_STATUSES.map((s) => (
            <StatusPill key={s} status={s} />
          ))}
        </Row>
        <Row label="freshness">
          <StatusPill status="fresh" />
          <StatusPill status="aging" />
          <StatusPill status="stale" />
        </Row>
      </Section>

      <Section title="MeasurementCard">
        <div className="grid max-w-xl grid-cols-2 gap-4">
          <MeasurementCard
            name="shoulder_width"
            valueCm={42.5}
            source="scan"
            confidence={0.92}
            history={[41.8, 42.0, 42.5]}
            updatedAt={daysAgo(12)}
          />
          <MeasurementCard
            name="hip_width"
            valueCm={36.8}
            source="manual"
            confidence={0.62}
            updatedAt={daysAgo(12)}
          />
        </div>
      </Section>

      <Section title="Sheet">
        <Button kind="quiet" onClick={() => setSheetOpen(true)}>
          Open sheet (stepper header)
        </Button>
        <Sheet
          open={sheetOpen}
          onOpenChange={setSheetOpen}
          title="Request this outfit"
          stepper={{
            steps: ["Measurements", "Notes & budget", "Review"],
            current: 1,
          }}
        >
          <p className="text-body text-text-2">
            Sheet body — bottom sheet on mobile, centered modal on desktop.
          </p>
        </Sheet>
      </Section>

      <Section title="PostCard">
        <div className="grid gap-8 md:grid-cols-2">
          <PostCard
            post={{ ...samplePost, liked, saved }}
            onToggleLike={() => setLiked((v) => !v)}
            onToggleSave={() => setSaved((v) => !v)}
            onRequest={() => {}}
            onComment={() => {}}
          />
          <PostCard skeleton />
        </div>
      </Section>

      <Section title="RequestCard">
        <div className="flex max-w-xl flex-col gap-3">
          <RequestCard order={sampleOrder} role="customer" />
          <RequestCard
            order={{ ...sampleOrder, status: "quoted" }}
            role="customer"
          />
          <RequestCard
            order={{ ...sampleOrder, status: "requested", quote_cents: null }}
            role="designer"
          />
        </div>
      </Section>

      <Section title="EmptyState">
        <div className="grid gap-4 md:grid-cols-2">
          {(
            [
              "feed",
              "vault",
              "orders",
              "explore",
              "notifications",
              "camera-permission",
            ] as EmptyStateContext[]
          ).map((ctx) => (
            <EmptyState key={ctx} context={ctx} />
          ))}
        </div>
      </Section>

      <Section title="Skeleton">
        <div className="grid max-w-xl grid-cols-2 items-start gap-4">
          <Skeleton kind="line" />
          <Skeleton kind="avatar" />
          <Skeleton kind="media" />
          <Skeleton kind="card" />
        </div>
      </Section>

      <Section title="FormRow + AddressFieldset">
        <div className="max-w-md">
          <FormRow label="Username" helper="3–30 chars · a-z 0-9 . _" required>
            <Input placeholder="kiki.adeyemi" aria-label="Username" />
          </FormRow>
        </div>
        <div className="max-w-md">
          <AddressFieldset
            context="delivery"
            value={address}
            onChange={(v) => setAddress(v as Record<string, string>)}
          />
        </div>
      </Section>

      <Section title="NavRail">
        <div className="flex h-96 gap-6 overflow-hidden rounded-card border border-border">
          <NavRail activeKey="home" />
          <NavRail activeKey="orders" expanded items={undefined} />
        </div>
      </Section>

      <Section title="AppBar">
        <div className="flex max-w-xl flex-col gap-3">
          <div className="overflow-hidden rounded-card border border-border">
            <AppBar
              title="Apparule"
              trailing={
                <IconButton aria-label="More">
                  <MoreHorizontal size={24} />
                </IconButton>
              }
            />
          </div>
          <div className="overflow-hidden rounded-card border border-border">
            <AppBar
              kind="sub"
              title="Order #APR-1042"
              onBack={() => {}}
              trailing={
                <IconButton aria-label="More">
                  <MoreHorizontal size={24} />
                </IconButton>
              }
            />
          </div>
          <div className="overflow-hidden rounded-card bg-black">
            <AppBar kind="over-media" title="Capture" onBack={() => {}} />
          </div>
        </div>
      </Section>

      <Section title="TabBar">
        <div className="max-w-sm overflow-hidden rounded-card border border-border">
          <TabBar activeKey={tabBarKey} ordersBadge={2} />
        </div>
        <Row label="active tab ×5 — click to move; Orders badge: count">
          {(["home", "explore", "create", "orders", "profile"] as const).map(
            (k) => (
              <Button
                key={k}
                kind="quiet"
                size="sm"
                onClick={() => setTabBarKey(k)}
              >
                {k}
              </Button>
            ),
          )}
        </Row>
      </Section>

      <Section title="Tabs">
        <div className="max-w-sm">
          <Tabs active={tab} onChange={setTab} />
        </div>
        <div className="max-w-sm">
          <Tabs kind="icon" active={iconTab} onChange={setIconTab} />
        </div>
      </Section>

      <Section title="GridTile">
        <div className="grid max-w-xl grid-cols-3 gap-1">
          <GridTile
            src="/demo/outfit-w03.jpg"
            alt="Outfit"
            likeCount={519}
            commentCount={6}
          />
          <GridTile
            src="/demo/outfit-w05.jpg"
            alt="Outfit"
            likeCount={128}
            commentCount={2}
            carousel
          />
          <GridTile skeleton />
        </div>
      </Section>

      <Section title="Select">
        <div className="max-w-sm">
          <Select
            aria-label="Decline reason"
            placeholder="Why are you declining?"
            options={[
              { value: "workload", label: "Fully booked right now" },
              { value: "out_of_specialty", label: "Outside my specialty" },
              { value: "budget_too_low", label: "Budget too low" },
              { value: "timeline_too_tight", label: "Timeline too tight" },
              { value: "other", label: "Other" },
            ]}
            value={selectValue}
            onValueChange={setSelectValue}
          />
        </div>
      </Section>

      <Section title="DateInput">
        <div className="max-w-sm">
          <DateInput
            aria-label="Due date"
            value={date}
            onChange={setDate}
            minDate={minDueDate()}
          />
        </div>
      </Section>

      <Section title="OrderTimelineRow">
        <div className="max-w-sm">
          <OrderTimelineRow
            dot="done"
            connector="drawn"
            label="Requested"
            timestamp={daysAgo(8)}
          />
          <OrderTimelineRow
            dot="done"
            connector="drawn"
            label="Quoted"
            timestamp={daysAgo(7)}
          />
          <OrderTimelineRow
            dot="current"
            connector="undrawn"
            label="In progress"
            timestamp={daysAgo(5)}
          />
          <OrderTimelineRow dot="pending" connector="none" label="Shipped" />
        </div>
        <div className="max-w-sm">
          <OrderTimelineRow
            dot="terminal-error"
            connector="none"
            label="Disputed"
            timestamp={daysAgo(1)}
          />
        </div>
      </Section>

      <Section title="PaymentBox">
        <div className="grid max-w-2xl gap-4 md:grid-cols-2">
          <PaymentBox
            state={payState}
            role="customer"
            quoteCents={4_500_000}
            showEscrowExplainer={payState === "escrow-held"}
            onPay={() => {
              setPayState("paying");
              setTimeout(() => setPayState("escrow-held"), 1200);
            }}
          />
          <PaymentBox state="released" role="designer" quoteCents={6_200_000} />
        </div>
        <div className="grid max-w-2xl gap-4 md:grid-cols-2">
          <PaymentBox
            state="dispute-frozen"
            role="designer"
            quoteCents={4_500_000}
          />
          <PaymentBox state="refunded" role="customer" quoteCents={4_500_000} />
        </div>
      </Section>

      <Section title="ThreadBubble">
        <div className="flex max-w-md flex-col gap-2">
          <ThreadBubble
            side="received"
            text="Love it. Quote sent — ready two weeks after payment."
          />
          <ThreadBubble side="sent" text="Hi Amara! Excited about this one." />
          <ThreadBubble
            side="sent"
            content="image"
            imageUrl="/demo/outfit-w14.jpg"
          />
          <ThreadBubble side="sent" text="Sending…" state="sending" />
          <ThreadBubble
            side="sent"
            text="This failed"
            state="failed"
            onRetry={() => {}}
          />
          <ThreadBubble side="received" content="typing" />
        </div>
      </Section>

      <Section title="CommentRow">
        <div className="max-w-md">
          <CommentRow comment={sampleComment} onReply={() => {}} />
          <CommentRow
            comment={{
              ...sampleComment,
              id: "c2",
              liked: true,
              like_count: 13,
            }}
          />
          <CommentRow
            comment={{ ...sampleComment, id: "c3", body: "Posting…" }}
            posting
          />
          <CommentRow
            comment={{ ...sampleComment, id: "c4", body: "Reply row" }}
            replyIndent
          />
        </div>
      </Section>

      <Section title="NotificationRow">
        <div className="max-w-md divide-y divide-border rounded-card border border-border">
          <NotificationRow notification={sampleNotification} />
          <NotificationRow
            notification={{
              ...sampleNotification,
              id: "n2",
              kind: "follow",
              text: "tunde.o started following you",
              thumb_url: null,
              read_at: daysAgo(1),
            }}
            onFollowBack={() => {}}
          />
        </div>
      </Section>

      <Section title="SessionRow">
        <div className="max-w-md">
          <SessionRow session={sampleSession} onDelete={() => {}} />
        </div>
        <div className="flex max-w-md flex-col gap-2">
          <SessionRow session={sampleSession} context="picker" selected />
          <SessionRow session={agingSession} context="picker" />
        </div>
      </Section>

      <Section title="ModerationQueueRow">
        <div className="flex max-w-xl flex-col gap-3">
          <ModerationQueueRow report={sampleReport} />
          <ModerationQueueRow
            report={{
              ...sampleReport,
              id: "rep-2",
              status: "actioned",
              action: "hide_post",
              actioned_by: { id: "acc-staff", username: "staff.ops" },
              actioned_at: daysAgo(0.5),
            }}
          />
        </div>
      </Section>

      <Section title="MediaDropzone">
        <div className="flex max-w-md flex-col gap-4">
          <MediaDropzone onFiles={() => {}} />
          <MediaDropzone state="uploading" progress={0.6} onFiles={() => {}} />
          <MediaDropzone state="error" onFiles={() => {}} />
          <div className="flex gap-2">
            <MediaUploadTile
              src="/demo/outfit-w00.jpg"
              altText="Ankara gown"
              onRemove={() => {}}
            />
            <MediaUploadTile src="/demo/outfit-w01.jpg" onRemove={() => {}} />
          </div>
        </div>
      </Section>

      <Section title="ManualMeasureRow">
        <div className="max-w-md">
          <ManualMeasureRow
            name="shoulder_width"
            valueCm={shoulder}
            onChange={setShoulder}
            unit={unit}
            onUnitChange={setUnit}
            min={30}
            max={60}
          />
        </div>
      </Section>

      <Section title="CaptureOverlay">
        <div className="grid max-w-3xl grid-cols-2 gap-4 md:grid-cols-4">
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">searching</span>
            <CaptureOverlay guide="searching" />
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">aligned</span>
            <CaptureOverlay guide="aligned" />
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">countdown</span>
            <CaptureOverlay guide="countdown" countdownValue={countdown} />
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">qc-hint</span>
            <CaptureOverlay guide="qc-hint" qcCode="arms_position" />
          </div>
        </div>
        <Row label="countdown tick">
          {([3, 2, 1] as const).map((v) => (
            <Button
              key={v}
              kind="quiet"
              size="sm"
              onClick={() => setCountdown(v)}
            >
              {v}
            </Button>
          ))}
        </Row>
      </Section>

      <Section title="CountdownRing">
        <div className="flex max-w-md items-center justify-around rounded-card bg-black p-6">
          <CountdownRing value={3} />
          <CountdownRing value={2} />
          <CountdownRing value={1} />
        </div>
      </Section>

      <Section title="QCHintChip">
        <div className="flex max-w-xl flex-wrap gap-2 rounded-card bg-black p-4">
          {(Object.keys(QC_GUIDANCE) as QcFailCode[]).map((code) => (
            <QCHintChip key={code} code={code} />
          ))}
        </div>
      </Section>

      <Section title="ProcessingConstellation">
        <div className="grid max-w-2xl grid-cols-3 gap-4">
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">processing</span>
            <ProcessingConstellation
              state="processing"
              imageSrc="/demo/outfit-w00.jpg"
            />
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">success</span>
            <ProcessingConstellation
              state="success"
              imageSrc="/demo/outfit-w00.jpg"
            />
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-caption text-text-2">failed</span>
            <ProcessingConstellation
              state="failed"
              imageSrc="/demo/outfit-w00.jpg"
            />
          </div>
        </div>
      </Section>

      <Section title="CaptureResults">
        <div className="max-w-xl">
          <CaptureResults
            confidences={[0.92, 0.62]}
            onSave={() => {}}
            onRetake={() => {}}
          >
            <MeasurementCard
              name="shoulder_width"
              valueCm={42.5}
              source="scan"
              confidence={0.92}
            />
            <MeasurementCard
              name="hip_width"
              valueCm={36.8}
              source="scan"
              confidence={0.62}
            />
          </CaptureResults>
        </div>
      </Section>

      <Section title="CaptureOptionCard">
        <div className="grid max-w-xl gap-3 md:grid-cols-2">
          <CaptureOptionCard mode="webcam-upload" onClick={() => {}} />
          <CaptureOptionCard mode="manual-entry" onClick={() => {}} />
        </div>
      </Section>

      <Section title="Banner">
        <div className="flex max-w-xl flex-col gap-3">
          <Banner tone="info" actionLabel="Learn more">
            Your measurements are private — snapshots are shared only inside a
            request.
          </Banner>
          <Banner tone="warn" actionLabel="Re-verify">
            Your payout verification lapsed — posts can&apos;t accept new
            requests.
          </Banner>
          <Banner tone="error" dismissable actionLabel="Retry">
            Upload failed — check your connection.
          </Banner>
          <Banner tone="success" dismissable>
            Payout account verified.
          </Banner>
        </div>
      </Section>

      <Section title="Switch">
        <Row>
          <Switch
            checked={switchOn}
            onCheckedChange={setSwitchOn}
            aria-label="Order updates"
          />
          <Switch checked={false} onCheckedChange={() => {}} aria-label="Off" />
          <Switch
            checked
            disabled
            onCheckedChange={() => {}}
            aria-label="Disabled on"
          />
        </Row>
      </Section>

      <Section title="Tooltip">
        <Row>
          <Tooltip label="Measured 12 days ago — retake?" placement="top">
            <span className="inline-flex cursor-help items-center gap-1 text-body text-text-2">
              <Ruler size={16} /> freshness
            </span>
          </Tooltip>
          <Tooltip label="Below" placement="bottom">
            <Button kind="quiet" size="sm">
              hover me
            </Button>
          </Tooltip>
        </Row>
      </Section>

      <Section title="Popover + MenuItem">
        <Popover
          trigger={
            <Button kind="quiet" size="sm">
              Post overflow ⋯
            </Button>
          }
        >
          <MenuItem label="Copy link" onSelect={() => {}} />
          <MenuItem label="Share to…" onSelect={() => {}} />
          <MenuItem label="Report post" destructive onSelect={() => {}} />
        </Popover>
      </Section>

      <Section title="Spinner">
        <Row>
          <Spinner size={20} kind="neutral" />
          <Spinner size={28} kind="gradient" />
          <Spinner size={28} kind="gradient" progress={0.65} />
        </Row>
      </Section>

      <Section title="UserRow">
        <div className="max-w-md">
          <UserRow
            username="tunde.o"
            meta="Agbada · Lagos"
            trailing="follow"
            verified
          />
          <UserRow
            username="amara.designs"
            meta="Ankara & contemporary"
            trailing="following"
            verified
          />
          <UserRow username="kiki.adeyemi" trailing="none" avatarSize={32} />
        </div>
      </Section>

      <Section title="CaughtUpDivider">
        <div className="max-w-md">
          <CaughtUpDivider />
        </div>
      </Section>

      <Section title="EarningsSummary + TransactionRow">
        <div className="max-w-xl">
          <EarningsSummary earnings={sampleEarnings} />
          <div className="mt-4">
            {sampleEarnings.transactions.map((t) => (
              <TransactionRow key={t.id} entry={t} />
            ))}
          </div>
        </div>
      </Section>

      <Section title="Marketing — MarketingNav / MarketingFooter">
        <div className="overflow-hidden rounded-card border border-border">
          <MarketingNav />
        </div>
        <div className="overflow-hidden rounded-card border border-border">
          <MarketingFooter />
        </div>
      </Section>

      <Section title="Marketing — StatCard / WalkthroughStep">
        <div className="grid max-w-2xl grid-cols-3 gap-4">
          <StatCard stat="±2 cm" label="target measurement accuracy" />
          <StatCard stat="2" label="photos per capture" />
          <StatCard stat="30 days" label="photo auto-delete" />
        </div>
        <div className="flex gap-6 overflow-x-auto">
          <WalkthroughStep
            imageSrc="/demo/outfit-w10.jpg"
            imageAlt="Capture step"
            title="Capture"
            body="Two photos and your height — the AI does the rest."
            step={0}
          />
          <WalkthroughStep
            imageSrc="/demo/outfit-w14.jpg"
            imageAlt="Vault step"
            title="Vault"
            body="Your measurements, versioned and private."
            step={1}
          />
        </div>
      </Section>

      <Section title="Marketing — ComparisonTable / CodeSnippetBlock / CommunityCard">
        <ComparisonTable />
        <div className="max-w-md">
          <CodeSnippetBlock />
        </div>
        <CommunityCard />
      </Section>

      <Section title="Marketing — FAQItem">
        <FAQGroup defaultOpenId="faq-1">
          <FAQItem id="faq-1" question="How accurate are the measurements?">
            The pipeline targets ±2 cm against tape measurements — and every
            value carries a confidence score, so you know when to re-measure.
          </FAQItem>
          <FAQItem id="faq-2" question="Who can see my measurements?">
            No one. Your vault is private; a designer only ever sees the frozen
            snapshot inside an order you placed.
          </FAQItem>
          <FAQItem id="faq-3" question="Can I self-host?">
            Yes — one `docker compose up -d` brings up the full stack on your
            own metal.
          </FAQItem>
        </FAQGroup>
      </Section>
    </main>
  );
}
