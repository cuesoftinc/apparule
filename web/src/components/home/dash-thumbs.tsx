"use client";

// A4b deep-dive thumbs — mini dashboard screens composed from real registry
// components at natural size (1440-wide), scaled 0.42 and clipped to the
// 560×300 panel-thumb box exactly like the Figma thumbs (264:8/264:8037/
// 264:8161/264:8175). Composed previews are the W2 adaptation (pages.md
// A4b real-screen thumbnails arrive with the W3 dashboards).
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { GridTile } from "@/components/ui/GridTile";
import { Input } from "@/components/ui/Input";
import { MeasurementCard } from "@/components/ui/MeasurementCard";
import { NavRail } from "@/components/ui/NavRail";
import { OrderTimelineRow } from "@/components/ui/OrderTimelineRow";
import { PaymentBox } from "@/components/ui/PaymentBox";
import { RequestCard } from "@/components/ui/RequestCard";
import { Tabs } from "@/components/ui/Tabs";
import { ThreadBubble } from "@/components/ui/ThreadBubble";
import {
  demoExploreChips,
  demoGridImages,
  demoMeasurements,
  demoOrders,
  heroOrder,
} from "@/controllers/home-demo";
import { MiniScreen } from "./MiniScreen";

// Figma thumb geometry: dashboard composed at 1440, scaled 0.42, clipped
// to the 560×300 panel-thumb.
const DASH_W = 1440;
const DASH_H = 1024;
const SCALE = 0.42;
const CLIP_W = 560;
const CLIP_H = 300;

/** ISO timestamp n days back (OrderTimelineRow formats real dates). */
function timelineDaysAgo(days: number): string {
  return new Date(Date.now() - days * 86_400_000).toISOString();
}

function DashShell({
  activeKey,
  children,
}: {
  activeKey: string;
  children: React.ReactNode;
}) {
  return (
    <MiniScreen
      width={DASH_W}
      height={DASH_H}
      scale={SCALE}
      clipWidth={CLIP_W}
      clipHeight={CLIP_H}
      fluid
      className="rounded-card border border-border bg-bg"
    >
      <div className="flex h-full bg-bg">
        {/* Decorative thumb (inert MiniScreen), but landmark labels stay
            distinct per instance for DOM-level landmark checks. */}
        <NavRail
          expanded
          activeKey={activeKey}
          ariaLabel={`Primary (${activeKey} thumb)`}
          className="shrink-0"
        />
        <div className="min-w-0 flex-1 px-24 py-8">{children}</div>
      </div>
    </MiniScreen>
  );
}

/** "Capture once, keep it fresh" — B4 vault (264:8). */
export function DashVaultThumb() {
  return (
    <DashShell activeKey="vault">
      <div className="flex items-center gap-5">
        <Avatar
          size={96}
          ring="gradient"
          name="Kiki Adeyemi"
          src="/demo/outfit-w16.jpg"
        />
        <div className="flex flex-col items-start gap-1">
          <span className="text-title font-semibold text-text">
            Measured 12 days ago
          </span>
          <span className="text-caption text-text-2">
            Fresh — 14 measurements on file · vault is private to you
          </span>
          <Button size="sm">Retake</Button>
        </div>
      </div>
      <div className="mt-6 grid w-[728px] grid-cols-3 gap-4">
        {demoMeasurements.map((m) => (
          <MeasurementCard
            key={m.name}
            name={m.name}
            valueCm={m.valueCm}
            source={m.source}
            confidence={m.confidence}
            history={m.history}
          />
        ))}
      </div>
      <p className="mt-4 text-body font-semibold text-link">
        +8 more measurements →
      </p>
      <p className="mt-3 max-w-[600px] text-caption text-text-2">
        Sessions are kept until you delete them. A snapshot is shared only when
        you send a request.
      </p>
      <p className="mt-2 flex gap-6 text-caption font-semibold text-link">
        <span>Download my data</span>
        <span>Delete all measurements</span>
      </p>
    </DashShell>
  );
}

/** "Find designers near you" — B2 explore (264:8037). */
export function DashExploreThumb() {
  return (
    <DashShell activeKey="explore">
      <div className="w-[630px]">
        <Input kind="search" placeholder="Designers, styles, tags" readOnly />
      </div>
      <div className="mt-4 flex w-[720px] gap-2 overflow-hidden">
        {demoExploreChips.map((label, i) => (
          <Chip
            key={label}
            label={label}
            kind={i === 0 ? "selected" : "default"}
          />
        ))}
        {/* canvas 264:8047: trailing removable location chip */}
        <Chip label="Lagos" kind="removable" onRemove={() => {}} />
      </div>
      <div className="mt-4 grid w-[924px] grid-cols-3 gap-2">
        {demoGridImages.slice(0, 9).map((img) => (
          <GridTile key={img.src} src={img.src} alt={img.alt} />
        ))}
      </div>
    </DashShell>
  );
}

/** "Escrow-protected commissions" — B3 orders list (264:8161). */
export function DashOrdersThumb() {
  return (
    <DashShell activeKey="orders">
      <div className="w-[630px]">
        <Tabs
          labels={["As customer", "As designer"]}
          active="first"
          onChange={() => {}}
        />
        <div className="mt-4 flex flex-col gap-4">
          {demoOrders.map((order) => (
            <RequestCard key={order.id} order={order} role="customer" />
          ))}
        </div>
      </div>
    </DashShell>
  );
}

/** "Your measurements ride with every order" — B3 order detail (264:8175). */
export function DashOrderDetailThumb() {
  return (
    <DashShell activeKey="orders">
      <div className="flex gap-10">
        <div className="w-[630px] shrink-0">
          <p className="text-title font-semibold text-text">
            Order #APR-1042 — Ankara two-piece
          </p>
          <div className="mt-4">
            <RequestCard order={heroOrder} role="customer" />
          </div>
          <p className="mt-4 text-caption text-text-2">
            Measurement snapshot — locked to this order · sent Jul 12
          </p>
          <div className="mt-2 flex gap-2">
            {[
              "shoulder 42.5",
              "hip 96.2",
              "sleeve 58.0",
              "waist 78.4",
              "+10 more",
            ].map((v) => (
              <span
                key={v}
                className="tnum rounded-pill border border-border px-3 py-1 text-caption text-text-2"
              >
                {v}
              </span>
            ))}
          </div>
          <div className="mt-4">
            <OrderTimelineRow
              dot="done"
              connector="drawn"
              label="Requested"
              timestamp={timelineDaysAgo(10)}
            />
            <OrderTimelineRow
              dot="done"
              connector="drawn"
              label="Quoted — ₦45,000"
              timestamp={timelineDaysAgo(8)}
            />
            <OrderTimelineRow
              dot="done"
              connector="drawn"
              label="Paid — held in escrow"
              timestamp={timelineDaysAgo(6)}
            />
            <OrderTimelineRow
              dot="current"
              connector="undrawn"
              label="In progress"
              timestamp={timelineDaysAgo(4)}
            />
            <OrderTimelineRow
              dot="pending"
              connector="none"
              label="Delivered"
            />
          </div>
          <div className="mt-4">
            <PaymentBox
              state="escrow-held"
              role="customer"
              quoteCents={4_500_000}
            />
          </div>
        </div>
        <div className="w-[380px] shrink-0 rounded-card border border-border bg-bg-elev p-4">
          <p className="text-caption font-semibold text-text-2">
            Thread — amara.designs
          </p>
          <div className="mt-3 flex flex-col gap-3">
            <ThreadBubble
              side="received"
              text="Sewing started today — shoulders first."
            />
            <ThreadBubble
              side="sent"
              text="Can't wait! The fabric is gorgeous."
            />
            <ThreadBubble
              side="received"
              content="image"
              imageUrl="/demo/outfit-w14.jpg"
            />
          </div>
          <div className="mt-4">
            <Input placeholder="Message amara.designs" readOnly />
          </div>
        </div>
      </div>
    </DashShell>
  );
}
