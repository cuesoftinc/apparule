import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import {
  QCHintChip,
  QC_GUIDANCE,
  QC_GUIDANCE_SIDE,
  qcGuidance,
  type QcFailCode,
} from "./QCHintChip";

const ALL_CODES = Object.keys(QC_GUIDANCE) as QcFailCode[];

describe("QCHintChip (§8.2b)", () => {
  it("covers the full capture-qc.md §1–2 code set (×12, incl. not_side_profile)", () => {
    expect(ALL_CODES).toHaveLength(12);
    expect(ALL_CODES).toContain("not_side_profile");
  });

  it.each(ALL_CODES)("renders the canonical guidance line for %s", (code) => {
    render(<QCHintChip code={code} />);
    const chip = screen.getByRole("status");
    expect(chip).toHaveAttribute("data-code", code);
    expect(chip).toHaveTextContent(QC_GUIDANCE[code]);
  });

  it("carries the flows/vault.md copy verbatim", () => {
    expect(QC_GUIDANCE.no_body).toBe("Make sure your whole body is visible");
    expect(QC_GUIDANCE.too_far).toBe("Move closer — fill more of the frame");
    expect(QC_GUIDANCE.camera_tilt).toBe("Hold the phone upright");
    expect(QC_GUIDANCE.not_side_profile).toBe(
      "Turn your right side to the camera",
    );
  });

  it("arms_position guidance is per pose (capture-qc.md §2 pose-2 delta)", () => {
    expect(qcGuidance("arms_position", "front")).toBe(
      "Keep arms slightly away from your body",
    );
    expect(qcGuidance("arms_position", "side")).toBe(
      "Let your arms hang relaxed at your sides",
    );
    expect(QC_GUIDANCE_SIDE.arms_position).toBe(
      "Let your arms hang relaxed at your sides",
    );
    render(<QCHintChip code="arms_position" pose="side" />);
    expect(screen.getByRole("status")).toHaveTextContent(
      "Let your arms hang relaxed at your sides",
    );
  });
});
