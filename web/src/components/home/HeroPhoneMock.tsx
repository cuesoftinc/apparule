"use client";

// Hero phone mock (pages.md A2): phone frame auto-playing a silent
// feed → capture → request loop, composed from real registry components at
// mobile scale (Figma 186:25: 390-wide feed scaled 0.775 inside an 8px
// text-token bezel). The loop pauses on hover and under reduced motion
// (A2 interaction rule); scenes crossfade on the entrance duration.
import { useEffect, useRef, useState } from "react";
import clsx from "clsx";
import Image from "next/image";
import { Bell, Send } from "lucide-react";
import { AppBar } from "@/components/ui/AppBar";
import { CaptureOverlay } from "@/components/ui/CaptureOverlay";
import { OrderTimelineRow } from "@/components/ui/OrderTimelineRow";
import { PaymentBox } from "@/components/ui/PaymentBox";
import { PostCard } from "@/components/ui/PostCard";
import { RequestCard } from "@/components/ui/RequestCard";
import { StoryRailItem } from "@/components/ui/StoryRailItem";
import { TabBar } from "@/components/ui/TabBar";
import { heroOrder, heroPosts, heroStories } from "@/controllers/home-demo";
import { MiniScreen } from "./MiniScreen";

const SCENES = ["feed", "capture", "request"] as const;
type Scene = (typeof SCENES)[number];

const PHONE_W = 390;
const PHONE_H = 844;
const SCALE = 0.775;
const SCENE_MS = 4000;
// Rendered media width inside the scaled frame (PHONE_W × SCALE) — the
// `sizes` hint that keeps srcset picks at mock scale, not viewport scale.
const MOCK_SIZES = "302px";

function StatusBar() {
  return (
    <div className="flex h-11 shrink-0 items-end px-6 pb-1">
      <span className="tnum text-body font-semibold text-text">9:41</span>
    </div>
  );
}

function FeedScene() {
  return (
    <div className="relative flex h-full flex-col overflow-hidden bg-bg">
      <StatusBar />
      <AppBar
        title="Apparule"
        trailing={
          <span className="flex items-center gap-4 text-text">
            <Bell size={24} />
            <Send size={24} />
          </span>
        }
      />
      <div className="flex shrink-0 gap-3 overflow-hidden px-3 py-2">
        {heroStories.map((story) => (
          <StoryRailItem
            key={story.username}
            username={story.username}
            avatarUrl={story.avatarUrl}
            state={story.state}
          />
        ))}
      </div>
      {/* onRequest shows the "Request this outfit" CTA — decorative here
          (the whole mock is pointer-inert). The first post's media is the
          audited mobile LCP element: it alone carries priority
          (fetchpriority=high, eager); MOCK_SIZES = 390 × 0.775 scale ≈ the
          302px the phone frame actually renders. */}
      <PostCard
        post={heroPosts[0]}
        onRequest={() => {}}
        className="shrink-0"
        mediaPriority
        mediaSizes={MOCK_SIZES}
      />
      <PostCard
        post={heroPosts[1]}
        onRequest={() => {}}
        className="shrink-0"
        mediaSizes={MOCK_SIZES}
      />
      <TabBar
        activeKey="home"
        ordersBadge={3}
        ariaLabel="Tabs (hero feed scene)"
        className="absolute inset-x-0 bottom-0"
      />
    </div>
  );
}

function CaptureScene() {
  return (
    <div className="flex h-full flex-col justify-center bg-black">
      <CaptureOverlay guide="searching">
        <Image
          src="/demo/outfit-w05.jpg"
          alt=""
          fill
          sizes={MOCK_SIZES}
          className="object-cover"
        />
      </CaptureOverlay>
    </div>
  );
}

function RequestScene() {
  return (
    <div className="relative flex h-full flex-col bg-bg">
      <StatusBar />
      <AppBar kind="sub" title="Order #APR-1042" />
      <div className="flex flex-col gap-4 px-3 py-4">
        <RequestCard order={heroOrder} role="customer" />
        <div>
          <OrderTimelineRow dot="done" connector="drawn" label="Requested" />
          <OrderTimelineRow
            dot="done"
            connector="drawn"
            label="Paid — held in escrow"
          />
          <OrderTimelineRow
            dot="current"
            connector="none"
            label="In progress"
          />
        </div>
        <PaymentBox
          state="escrow-held"
          role="customer"
          quoteCents={4_500_000}
        />
      </div>
      <TabBar
        activeKey="orders"
        ariaLabel="Tabs (hero request scene)"
        className="absolute inset-x-0 bottom-0"
      />
    </div>
  );
}

export function HeroPhoneMock({ className }: { className?: string }) {
  const [scene, setScene] = useState<Scene>("feed");
  const [paused, setPaused] = useState(false);
  const reducedRef = useRef(false);

  useEffect(() => {
    if (
      typeof window.matchMedia === "function" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    ) {
      reducedRef.current = true;
      return; // reduced motion: the loop never advances (static feed)
    }
    if (paused) return;
    const id = window.setInterval(() => {
      setScene((s) => SCENES[(SCENES.indexOf(s) + 1) % SCENES.length]);
    }, SCENE_MS);
    return () => window.clearInterval(id);
  }, [paused]);

  return (
    <div
      data-testid="hero-phone"
      data-scene={scene}
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      className={clsx(
        // Figma 186:25: 8px bezel bound to the text token, 48px radius
        "relative overflow-hidden rounded-[48px] border-8 border-text bg-bg",
        className,
      )}
    >
      <MiniScreen width={PHONE_W} height={PHONE_H} scale={SCALE}>
        <div className="relative h-full w-full">
          {SCENES.map((name) => (
            <div
              key={name}
              data-scene-layer={name}
              aria-hidden={name !== scene}
              className={clsx(
                "absolute inset-0 transition-opacity duration-250 ease-standard motion-reduce:transition-none",
                name === scene ? "opacity-100" : "opacity-0",
              )}
            >
              {name === "feed" ? (
                <FeedScene />
              ) : name === "capture" ? (
                <CaptureScene />
              ) : (
                <RequestScene />
              )}
            </div>
          ))}
        </div>
      </MiniScreen>
    </div>
  );
}
