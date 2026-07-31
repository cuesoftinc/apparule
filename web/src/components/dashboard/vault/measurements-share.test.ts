// A-11 share text — the WhatsApp-to-tailor flow (decisions.md).
import { describe, expect, it } from "vitest";
import type { Measurement } from "@/models";
import { APPARULE_LINK, measurementsShareText } from "./measurements-share";

const m = (name: string, value_cm: number): Measurement => ({
  id: `m-${name}`,
  session_id: "sess-1",
  name,
  value_cm,
  source: "pipeline",
  confidence: null,
});

describe("measurementsShareText (A-11)", () => {
  it("renders header, one humanized line per value in inches, and the link", () => {
    const text = measurementsShareText([
      m("shoulder", 42.5),
      m("shoulder_to_bust_point", 26.0),
    ]);
    expect(text).toBe(
      [
        "My measurements (Apparule)",
        "Shoulder: 16.7 in",
        "Shoulder to bust point: 10.2 in",
        APPARULE_LINK,
      ].join("\n"),
    );
  });

  it("speaks cm when the display unit is cm", () => {
    expect(measurementsShareText([m("waist", 78.5)], "cm")).toContain(
      "Waist: 78.5 cm",
    );
  });
});
