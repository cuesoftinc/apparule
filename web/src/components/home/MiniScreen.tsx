"use client";

// MiniScreen — scaled mini preview for the home page's walkthrough and
// deep-dive thumbs: real component instances composed at natural size and
// scaled down, exactly how the Figma thumbs are built (mobile screens at
// 0.4 of 390, dashboard screens at 0.42 of 1440 — canvas 195:2…/264:8…).
// Decorative: aria-hidden + inert to pointer/tab order. `fluid` previews
// downscale further to their container below the natural clip width
// (375-wide adaptation — Figma is a fixed 1440 canvas).
import clsx from "clsx";
import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";

export interface MiniScreenProps {
  /** Natural design size the children are composed at. */
  width: number;
  height: number;
  scale: number;
  /** Clip the scaled result to this box (defaults to width×height ×scale). */
  clipWidth?: number;
  clipHeight?: number;
  /** Shrink with the container when narrower than clipWidth. */
  fluid?: boolean;
  className?: string;
  children: ReactNode;
}

export function MiniScreen({
  width,
  height,
  scale,
  clipWidth,
  clipHeight,
  fluid = false,
  className,
  children,
}: MiniScreenProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [factor, setFactor] = useState(1);
  const clipW = clipWidth ?? Math.round(width * scale);
  const clipH = clipHeight ?? Math.round(height * scale);

  useEffect(() => {
    if (!fluid) return;
    const node = ref.current;
    if (!node || typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver((entries) => {
      const w = entries[0]?.contentRect.width ?? clipW;
      setFactor(Math.min(1, w / clipW));
    });
    // Observe the parent so our own fixed height never feeds back.
    observer.observe(node.parentElement ?? node);
    return () => observer.disconnect();
  }, [fluid, clipW]);

  const outer: CSSProperties = fluid
    ? { width: "100%", maxWidth: clipW, height: clipH * factor }
    : { width: clipW, height: clipH };

  return (
    <div
      ref={ref}
      aria-hidden
      data-testid="mini-screen"
      className={clsx(
        "pointer-events-none select-none overflow-hidden",
        className,
      )}
      style={outer}
    >
      <div
        style={{
          width,
          height,
          transform: `scale(${scale * factor})`,
          transformOrigin: "top left",
        }}
      >
        {children}
      </div>
    </div>
  );
}
