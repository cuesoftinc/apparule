import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CaptureOptionCard } from "./CaptureOptionCard";

describe("CaptureOptionCard (§8.2b)", () => {
  it("mode=photo-upload renders the upload copy (M-12: no webcam mode)", () => {
    render(<CaptureOptionCard mode="photo-upload" />);
    const card = screen.getByRole("button");
    // Figma master (66:721) carries the canonical copy; the title is the
    // web B4 upload phrasing (per-platform override, canvas ledger).
    expect(card).toHaveAttribute("data-mode", "photo-upload");
    expect(card).toHaveTextContent("Upload photos");
    expect(card).toHaveTextContent("Two photos — we measure automatically");
  });

  it("mode=manual-entry renders its copy", () => {
    render(<CaptureOptionCard mode="manual-entry" />);
    const card = screen.getByRole("button");
    expect(card).toHaveAttribute("data-mode", "manual-entry");
    expect(card).toHaveTextContent("Enter manually");
  });

  it("fires onClick", async () => {
    const onClick = vi.fn();
    render(<CaptureOptionCard mode="photo-upload" onClick={onClick} />);
    await userEvent.click(screen.getByRole("button"));
    expect(onClick).toHaveBeenCalledOnce();
  });
});
