import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CaptureOptionCard } from "./CaptureOptionCard";

describe("CaptureOptionCard (§8.2b)", () => {
  it("mode=webcam-upload renders its copy", () => {
    render(<CaptureOptionCard mode="webcam-upload" />);
    const card = screen.getByRole("button");
    expect(card).toHaveAttribute("data-mode", "webcam-upload");
    expect(card).toHaveTextContent("Webcam upload");
    expect(card).toHaveTextContent("Two photos and your height");
  });

  it("mode=manual-entry renders its copy", () => {
    render(<CaptureOptionCard mode="manual-entry" />);
    const card = screen.getByRole("button");
    expect(card).toHaveAttribute("data-mode", "manual-entry");
    expect(card).toHaveTextContent("Manual entry");
  });

  it("fires onClick", async () => {
    const onClick = vi.fn();
    render(<CaptureOptionCard mode="webcam-upload" onClick={onClick} />);
    await userEvent.click(screen.getByRole("button"));
    expect(onClick).toHaveBeenCalledOnce();
  });
});
