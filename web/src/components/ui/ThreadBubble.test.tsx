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
