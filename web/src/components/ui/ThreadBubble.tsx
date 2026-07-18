"use client";

// ThreadBubble — design.md §8.2b (as built): side sent / received ·
// content text / image / typing (MI-17 three-dot "responding…" pulse) ·
// state sending / sent / failed (send-state axis doesn't apply to typing).
import clsx from "clsx";
import Image from "next/image";

export type ThreadBubbleContent = "text" | "image" | "typing";
export type ThreadBubbleState = "sending" | "sent" | "failed";

export interface ThreadBubbleProps {
  side: "sent" | "received";
  content?: ThreadBubbleContent;
  state?: ThreadBubbleState;
  text?: string;
  imageUrl?: string;
  onRetry?: () => void;
  className?: string;
}

export function ThreadBubble({
  side,
  content = "text",
  state = "sent",
  text,
  imageUrl,
  onRetry,
  className,
}: ThreadBubbleProps) {
  const sent = side === "sent";
  return (
    <div
      data-side={side}
      data-content={content}
      data-state={content === "typing" ? undefined : state}
      className={clsx(
        "flex w-full flex-col",
        sent ? "items-end" : "items-start",
        className,
      )}
    >
      <div
        className={clsx(
          "max-w-[75%] overflow-hidden rounded-card text-body",
          content !== "image" && "px-4 py-2.5",
          sent
            ? "bg-accent-gradient text-on-accent"
            : "border border-border bg-bg-elev text-text",
          state === "sending" && content !== "typing" && "opacity-60",
        )}
      >
        {content === "typing" ? (
          <span
            data-testid="typing-dots"
            aria-label="responding…"
            className="flex items-center gap-1 py-1"
          >
            {[0, 1, 2].map((i) => (
              <span
                key={i}
                className="size-1.5 rounded-pill bg-text-2 animate-[typing-pulse_1.2s_ease-in-out_infinite] motion-reduce:animate-none"
                style={{ animationDelay: `${i * 150}ms` }}
              />
            ))}
          </span>
        ) : content === "image" && imageUrl ? (
          <span className="relative block h-48 w-56">
            <Image src={imageUrl} alt="" fill sizes="224px" className="object-cover" />
          </span>
        ) : (
          text
        )}
      </div>
      {state === "failed" && content !== "typing" ? (
        <button
          type="button"
          onClick={onRetry}
          className="mt-1 text-micro font-semibold text-error"
        >
          Failed — tap to retry
        </button>
      ) : null}
    </div>
  );
}
