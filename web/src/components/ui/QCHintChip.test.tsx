import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { QCHintChip, QC_GUIDANCE, type QcFailCode } from "./QCHintChip";

const ALL_CODES = Object.keys(QC_GUIDANCE) as QcFailCode[];

describe("QCHintChip (§8.2b)", () => {
  it("covers the full capture-qc.md §1–2 code set (×11)", () => {
    expect(ALL_CODES).toHaveLength(11);
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
  });
});
