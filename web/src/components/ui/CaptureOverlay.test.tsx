import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { CaptureOverlay } from "./CaptureOverlay";
import { QC_GUIDANCE } from "./QCHintChip";

describe("CaptureOverlay (§8.2b)", () => {
  it.each(["searching", "aligned", "countdown", "qc-hint"] as const)(
    "renders guide=%s",
    (guide) => {
      const { container } = render(
        <CaptureOverlay guide={guide} qcCode="no_body" />,
      );
      expect(container.firstElementChild).toHaveAttribute("data-guide", guide);
      expect(screen.getByTestId("silhouette")).toBeInTheDocument();
    },
  );

  it("searching: silhouette pulses gently (MI-12), reduced-motion safe", () => {
    render(<CaptureOverlay guide="searching" />);
    const silhouette = screen.getByTestId("silhouette");
    expect(silhouette.getAttribute("class")).toContain("silhouette-pulse");
    expect(silhouette.getAttribute("class")).toContain(
      "motion-reduce:animate-none",
    );
  });

  it("aligned: guide turns success", () => {
    render(<CaptureOverlay guide="aligned" />);
    const group = screen.getByTestId("silhouette").querySelector("g");
    expect(group).toHaveAttribute("stroke", "var(--ap-success)");
  });

  it("countdown: renders the CountdownRing at the current tick", () => {
    render(<CaptureOverlay guide="countdown" countdownValue={2} />);
    expect(
      screen.getByRole("timer", { name: "Capturing in 2" }),
    ).toBeInTheDocument();
  });

  it("qc-hint: chip slot renders the code's guidance", () => {
    render(<CaptureOverlay guide="qc-hint" qcCode="arms_position" />);
    expect(screen.getByRole("status")).toHaveTextContent(
      QC_GUIDANCE.arms_position,
    );
  });

  it("hosts the camera viewport as children", () => {
    render(
      <CaptureOverlay guide="searching">
        <span data-testid="viewport" />
      </CaptureOverlay>,
    );
    expect(screen.getByTestId("viewport")).toBeInTheDocument();
  });
});
