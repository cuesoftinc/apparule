import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ThreadBubble } from "./ThreadBubble";

describe("ThreadBubble (§8.2b as built)", () => {
  it.each(["sent", "received"] as const)("renders side=%s", (side) => {
    const { container } = render(<ThreadBubble side={side} text="hi" />);
    expect(container.querySelector(`[data-side="${side}"]`)).not.toBeNull();
  });

  it("content axis: text / image / typing", () => {
    const { container, rerender } = render(
      <ThreadBubble side="sent" text="hello" />,
    );
    expect(container.querySelector('[data-content="text"]')).not.toBeNull();
    rerender(
      <ThreadBubble
        side="sent"
        content="image"
        imageUrl="/demo/outfit-w14.jpg"
      />,
    );
    expect(container.querySelector('[data-content="image"]')).not.toBeNull();
    rerender(<ThreadBubble side="received" content="typing" />);
    expect(screen.getByTestId("typing-dots")).toBeInTheDocument();
  });

  it("typing has no send-state axis (as built)", () => {
    const { container } = render(
      <ThreadBubble side="received" content="typing" state="failed" />,
    );
    expect(container.querySelector("[data-state]")).toBeNull();
  });

  it("renders a per-bubble timestamp — bare time today, dated when older (B3 frame)", () => {
    const today = new Date();
    today.setHours(14, 5, 0, 0);
    render(
      <ThreadBubble side="sent" text="hi" timestamp={today.toISOString()} />,
    );
    expect(screen.getByText("14:05")).toBeInTheDocument();

    const older = new Date("2026-03-04T13:58:00");
    render(
      <ThreadBubble
        side="received"
        text="ok"
        timestamp={older.toISOString()}
      />,
    );
    expect(screen.getByText("Mar 4, 13:58")).toBeInTheDocument();
  });

  it("timestamp waits for delivery and never applies to typing", () => {
    const iso = new Date().toISOString();
    const { container, rerender } = render(
      <ThreadBubble side="sent" text="…" state="sending" timestamp={iso} />,
    );
    expect(container.querySelector("time")).toBeNull();
    rerender(<ThreadBubble side="received" content="typing" timestamp={iso} />);
    expect(container.querySelector("time")).toBeNull();
    rerender(<ThreadBubble side="sent" text="…" timestamp={iso} />);
    expect(container.querySelector("time")).not.toBeNull();
  });

  it("sending dims; failed offers retry", async () => {
    const onRetry = vi.fn();
    const { rerender, container } = render(
      <ThreadBubble side="sent" text="…" state="sending" />,
    );
    expect(container.querySelector('[data-state="sending"]')).not.toBeNull();
    rerender(
      <ThreadBubble side="sent" text="…" state="failed" onRetry={onRetry} />,
    );
    await userEvent.click(screen.getByRole("button", { name: /retry/i }));
    expect(onRetry).toHaveBeenCalledOnce();
  });
});
