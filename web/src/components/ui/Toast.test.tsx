import { describe, expect, it, vi } from "vitest";
import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Toast } from "./Toast";

describe("Toast (§8.2)", () => {
  it.each(["success", "error", "neutral"] as const)("renders kind=%s", (kind) => {
    render(<Toast kind={kind} message="Saved" autoDismissMs={0} />);
    expect(screen.getByRole("status")).toHaveAttribute("data-kind", kind);
  });

  it("error+retry re-toasts with a Retry action (MI-18)", async () => {
    const onRetry = vi.fn();
    render(
      <Toast kind="error" message="Couldn't like" onRetry={onRetry} autoDismissMs={0} />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Retry" }));
    expect(onRetry).toHaveBeenCalledOnce();
  });

  it("auto-dismisses after 3s by default", () => {
    vi.useFakeTimers();
    const onDismiss = vi.fn();
    render(<Toast message="bye" onDismiss={onDismiss} />);
    act(() => {
      vi.advanceTimersByTime(3000);
    });
    expect(onDismiss).toHaveBeenCalledOnce();
    vi.useRealTimers();
  });
});
