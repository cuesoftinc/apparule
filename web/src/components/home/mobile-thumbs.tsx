"use client";

// A4 walkthrough thumbs — mini mobile screens composed from real registry
// components at natural size (390-wide), scaled 0.4 into the 280×180
// screenshot slot exactly like the Figma thumbs (195:2/195:5/195:6309/
// 195:6333). W2 adaptation per pages.md A4: composed component previews
// stand in for exported Stage-4 raster thumbnails until W3.
import Image from "next/image";
import { AppBar } from "@/components/ui/AppBar";
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { CaptureOptionCard } from "@/components/ui/CaptureOptionCard";
import { CaptureOverlay } from "@/components/ui/CaptureOverlay";
import { Chip } from "@/components/ui/Chip";
import { GridTile } from "@/components/ui/GridTile";
import { Input } from "@/components/ui/Input";
import { MeasurementCard } from "@/components/ui/MeasurementCard";
import { RequestCard } from "@/components/ui/RequestCard";
import { TabBar } from "@/components/ui/TabBar";
import { Tabs } from "@/components/ui/Tabs";
import {
  demoExploreChips,
  demoGridImages,
  demoMeasurements,
  demoOrders,
} from "@/controllers/home-demo";
import { MiniScreen } from "./MiniScreen";

// Figma thumb geometry: phone screens at 156 = 390 × 0.4, top-anchored
// 12px inside the 280×180 slot.
const PHONE_W = 390;
const PHONE_H = 844;
const SCALE = 0.4;

function ThumbShell({ children }: { children: React.ReactNode }) {
  return (
    <span className="absolute inset-0 flex justify-center pt-3">
      <MiniScreen
        width={PHONE_W}
        height={PHONE_H}
        scale={SCALE}
        clipHeight={168}
        className="rounded-lg border border-border bg-bg"
      >
        {children}
      </MiniScreen>
    </span>
  );
}

function StatusBar() {
  return (
    <div className="flex h-11 shrink-0 items-end px-6 pb-1">
      <span className="tnum text-caption font-semibold text-text">9:41</span>
    </div>
  );
}

/** Step 1 — Capture: silhouette guide over the camera viewport (C6). */
export function CaptureThumb() {
  return (
    <ThumbShell>
      <div className="flex h-full flex-col bg-black">
        <CaptureOverlay guide="searching">
          {/* sizes = PHONE_W × SCALE — the 156px the thumb actually renders */}
          <Image
            src="/demo/outfit-w05.jpg"
            alt=""
            fill
            sizes="156px"
            className="object-cover"
          />
        </CaptureOverlay>
      </div>
    </ThumbShell>
  );
}

/** Step 2 — Vault: freshness header + cards + retake sheet (C7). */
export function VaultThumb() {
  return (
    <ThumbShell>
      <div className="relative flex h-full flex-col bg-bg">
        <StatusBar />
        <AppBar kind="sub" title="Measurement vault" onBack={() => {}} />
        <div className="flex items-center gap-4 px-4 py-4">
          <Avatar
            size={96}
            ring="gradient"
            name="Kiki Adeyemi"
            src="/demo/outfit-w16.jpg"
          />
          <div className="flex flex-col items-start gap-1">
            <span className="text-body-lg font-semibold text-text">
              Measured 12 days ago
            </span>
            <span className="text-caption text-text-2">
              Up to date · 14 measurements
            </span>
            <Button size="sm">Retake</Button>
          </div>
        </div>
        <div className="flex flex-col gap-3 px-4">
          {demoMeasurements.slice(0, 2).map((m) => (
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
        <div className="absolute inset-x-0 bottom-0 flex flex-col gap-3 rounded-t-2xl border-t border-border bg-bg-elev px-4 pb-4 pt-2">
          <span className="mx-auto h-1 w-9 rounded-pill bg-border" />
          <span className="text-body-lg font-semibold text-text">
            Retake your measurements
          </span>
          {/* Mobile C7 keeps the live guided camera (M-12) — the thumb
              renders the mobile title over the shared master copy. */}
          <CaptureOptionCard mode="photo-upload" title="Use your camera" />
          <CaptureOptionCard mode="manual-entry" />
        </div>
      </div>
    </ThumbShell>
  );
}

/** Step 3 — Discover: search + filter chips + explore grid (C3). */
export function ExploreThumb() {
  return (
    <ThumbShell>
      <div className="relative flex h-full flex-col bg-bg">
        <StatusBar />
        <div className="px-4 pb-2">
          <Input kind="search" placeholder="Designers, styles, tags" readOnly />
        </div>
        <div className="flex gap-2 overflow-hidden px-4 pb-3">
          {demoExploreChips.map((label, i) => (
            <Chip
              key={label}
              label={label}
              kind={i === 0 ? "selected" : "default"}
            />
          ))}
        </div>
        <div className="grid grid-cols-3 gap-0.5">
          {demoGridImages.slice(0, 9).map((img) => (
            <GridTile key={img.src} src={img.src} alt={img.alt} />
          ))}
        </div>
        <TabBar
          activeKey="explore"
          ariaLabel="Tabs (explore thumb)"
          className="absolute inset-x-0 bottom-0"
        />
      </div>
    </ThumbShell>
  );
}

/** Step 4 — Commission: orders list with the status pills (C8). */
export function OrdersThumb() {
  return (
    <ThumbShell>
      <div className="relative flex h-full flex-col bg-bg">
        <StatusBar />
        <AppBar kind="sub" title="Orders" />
        <div className="px-4 pt-2">
          <Tabs
            labels={["As customer", "As designer"]}
            active="first"
            onChange={() => {}}
          />
        </div>
        <div className="flex flex-col gap-3 px-4 pt-3">
          {demoOrders.slice(0, 4).map((order) => (
            <RequestCard key={order.id} order={order} role="customer" />
          ))}
        </div>
        <TabBar
          activeKey="orders"
          ordersBadge={2}
          ariaLabel="Tabs (orders thumb)"
          className="absolute inset-x-0 bottom-0"
        />
      </div>
    </ThumbShell>
  );
}
