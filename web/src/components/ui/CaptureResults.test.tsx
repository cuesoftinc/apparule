import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CaptureResults } from "./CaptureResults";
import { MeasurementCard } from "./MeasurementCard";

function renderResults(overrides: Partial<Parameters<typeof CaptureResults>[0]> = {}) {
  const onSave = vi.fn();
  const onRetake = vi.fn();
  render(
    <CaptureResults
      confidences={[0.92, 0.62]}
      onSave={onSave}
      onRetake={onRetake}
      {...overrides}
    >
      <MeasurementCard name="shoulder_width" valueCm={42.5} source="scan" confidence={0.92} />
      <MeasurementCard name="hip_width" valueCm={36.8} source="scan" confidence={0.62} />
    </CaptureResults>,
  );
  return { onSave, onRetake };
}

describe("CaptureResults (§8.2b)", () => {
  // Figma master (65:612): the header carries a confidence pill; the full
  // count/mean summary lives in its title attribute.
  it("header summarizes count, mean confidence, and low-confidence flags", () => {
    renderResults();
    const pill = screen.getByTestId("confidence-summary");
    expect(pill).toHaveTextContent("1 low confidence");
    expect(pill).toHaveAttribute(
      "title",
      "2 measurements · 77% average confidence",
    );
  });

  it("omits the low flag when everything clears 0.7", () => {
    renderResults({ confidences: [0.92, 0.88] });
    const pill = screen.getByTestId("confidence-summary");
    expect(pill).toHaveTextContent("High confidence");
    expect(pill).not.toHaveTextContent("low");
  });

  it("staggers the card list 60ms apart (MI-12), reduced-motion safe", () => {
    renderResults();
    const wrappers = screen
      .getAllByRole("button")
      .filter((b) => b.hasAttribute("data-source"))
      .map((card) => card.parentElement!);
    expect(wrappers[0].getAttribute("style")).toContain("animation-delay: 0ms");
    expect(wrappers[1].getAttribute("style")).toContain("animation-delay: 60ms");
    expect(wrappers[0].className).toContain("motion-reduce:animate-none");
  });

  it("Save to vault (gradient) and Retake (quiet) fire", async () => {
    const { onSave, onRetake } = renderResults();
    await userEvent.click(screen.getByRole("button", { name: "Save to vault" }));
    await userEvent.click(screen.getByRole("button", { name: "Retake" }));
    expect(onSave).toHaveBeenCalledOnce();
    expect(onRetake).toHaveBeenCalledOnce();
  });

  it("saving: save shows loading, retake disabled", () => {
    renderResults({ saving: true });
    // Figma Button master: loading swaps the label for a spinner
    const saving = document.querySelector('button[aria-busy="true"]');
    expect(saving).not.toBeNull();
    expect(saving).toBeDisabled();
    expect(screen.getByRole("button", { name: "Retake" })).toBeDisabled();
  });
});
