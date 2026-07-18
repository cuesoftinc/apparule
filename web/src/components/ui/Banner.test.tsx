import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Banner } from "./Banner";

describe("Banner / InlineAlert (§8.2b)", () => {
  it.each(["info", "warn", "error", "success"] as const)(
    "renders tone=%s",
    (tone) => {
      render(<Banner tone={tone}>KYC lapsed</Banner>);
      const role = tone === "error" ? "alert" : "status";
      expect(screen.getByRole(role)).toHaveAttribute("data-tone", tone);
    },
  );

  it("renders the action-link slot", async () => {
    const onAction = vi.fn();
    render(
      <Banner tone="warn" actionLabel="Re-verify" onAction={onAction}>
        Payouts queue until re-verification
      </Banner>,
    );
    await userEvent.click(screen.getByRole("button", { name: "Re-verify" }));
    expect(onAction).toHaveBeenCalledOnce();
  });

  it("dismissable banners unmount on ✕", async () => {
    const onDismiss = vi.fn();
    render(
      <Banner tone="info" dismissable onDismiss={onDismiss}>
        Notice
      </Banner>,
    );
    await userEvent.click(screen.getByRole("button", { name: "Dismiss" }));
    expect(onDismiss).toHaveBeenCalledOnce();
    expect(screen.queryByText("Notice")).not.toBeInTheDocument();
  });

  it("persistent banners render no dismiss affordance", () => {
    render(<Banner tone="warn">Persistent</Banner>);
    expect(screen.queryByRole("button", { name: "Dismiss" })).not.toBeInTheDocument();
  });
});
