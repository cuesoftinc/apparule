import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Sheet } from "./Sheet";

describe("Sheet (§8.2)", () => {
  it("renders title + body when open", () => {
    render(
      <Sheet open onOpenChange={() => {}} title="Request this outfit">
        <p>Body</p>
      </Sheet>,
    );
    expect(screen.getByRole("dialog")).toBeInTheDocument();
    expect(screen.getByText("Request this outfit")).toBeInTheDocument();
    expect(screen.getByText("Body")).toBeInTheDocument();
  });

  it("stays unmounted when closed", () => {
    render(
      <Sheet open={false} onOpenChange={() => {}} title="Hidden">
        <p>Body</p>
      </Sheet>,
    );
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });

  it("renders the MI-10 stepper header with progress", () => {
    render(
      <Sheet
        open
        onOpenChange={() => {}}
        title="Request"
        stepper={{ steps: ["Measurements", "Notes & budget", "Review"], current: 1 }}
      >
        <p>Body</p>
      </Sheet>,
    );
    // Figma master (50:256): full-bleed progress track + a single centered
    // "Step n of N · Label" caption for the current step.
    const stepper = screen.getByTestId("sheet-stepper");
    expect(stepper).toHaveTextContent("Step 2 of 3 · Notes & budget");
    expect(
      screen.getByText(/Step 2 of 3/),
    ).toHaveAttribute("aria-current", "step");
  });

  it("desktop width follows the size axis (default 480px modal, wide post-detail)", () => {
    const { rerender } = render(
      <Sheet open onOpenChange={() => {}} title="Post">
        <p>Body</p>
      </Sheet>,
    );
    // default: the 480px secondary-flow modal
    expect(screen.getByRole("dialog").className).toContain("md:w-[480px]");
    rerender(
      <Sheet open onOpenChange={() => {}} title="Post" size="wide">
        <p>Body</p>
      </Sheet>,
    );
    // wide: a real md width (not a max-width fighting the base md:w-*),
    // viewport-clamped — the two-column PostDetailView needs the room
    const wide = screen.getByRole("dialog").className;
    expect(wide).not.toContain("md:w-[480px]");
    expect(wide).toContain("md:w-[min(56rem,calc(100vw-4rem))]");
  });

  it("close affordance fires onOpenChange(false)", async () => {
    const onOpenChange = vi.fn();
    render(
      <Sheet open onOpenChange={onOpenChange} title="Request">
        <p>Body</p>
      </Sheet>,
    );
    await userEvent.click(screen.getByRole("button", { name: "Close" }));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });
});
