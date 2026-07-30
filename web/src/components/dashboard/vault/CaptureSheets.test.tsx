// B4 capture sheets — options (photo upload / manual entry + the M-12
// mobile-app hint) and manual entry (no height row — input_height_cm is
// null for method: manual; out-of-range advisory per flows/vault.md §2;
// inches are the default display unit per A-9, storage stays cm; the
// A-10 tailor templates select the field set, with a one-time chooser
// when the account has none).
import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MANUAL_TEMPLATES } from "@/models/entities/measurement";
import {
  CaptureOptionsSheet,
  ManualEntrySheet,
  manualAdvisory,
} from "./CaptureSheets";

describe("CaptureOptionsSheet (B4, M-12)", () => {
  it("offers photo upload + manual entry and carries the app hint", async () => {
    const onPick = vi.fn();
    render(
      <CaptureOptionsSheet open onOpenChange={() => {}} onPick={onPick} />,
    );
    expect(
      screen.getByText("Best experience: guided capture on the Apparule app."),
    ).toBeInTheDocument();
    await userEvent.click(
      screen.getByRole("button", { name: /Upload photos/ }),
    );
    expect(onPick).toHaveBeenCalledWith("photo-upload");
    await userEvent.click(
      screen.getByRole("button", { name: /Enter manually/ }),
    );
    expect(onPick).toHaveBeenCalledWith("manual-entry");
  });
});

describe("ManualEntrySheet (MI-13, A-10)", () => {
  it("templates match the canonical flows/vault.md §2 tables", () => {
    // The A-10 tailor templates [Decided 2026-07-25] — any drift from the
    // docs tables is a parity break, and the 7 shared measures must carry
    // identical ranges in both.
    expect(MANUAL_TEMPLATES.women).toEqual([
      { name: "shoulder", min: 30, max: 60 },
      { name: "bust", min: 60, max: 160 },
      { name: "under_bust", min: 55, max: 140 },
      { name: "bust_span", min: 12, max: 30 },
      { name: "waist", min: 50, max: 150 },
      { name: "shoulder_to_bust_point", min: 18, max: 40 },
      { name: "shoulder_to_under_bust", min: 25, max: 50 },
      { name: "shoulder_to_waist", min: 30, max: 60 },
      { name: "half_length", min: 30, max: 70 },
      { name: "waist_to_knee", min: 40, max: 75 },
      { name: "gown_length", min: 90, max: 170 },
      { name: "skirt_length", min: 40, max: 120 },
      { name: "trouser_length", min: 80, max: 120 },
      { name: "thigh", min: 40, max: 90 },
      { name: "knee", min: 25, max: 60 },
      { name: "sleeve_length", min: 15, max: 70 },
      { name: "sleeve_width", min: 20, max: 50 },
    ]);
    expect(MANUAL_TEMPLATES.men).toEqual([
      { name: "shoulder", min: 30, max: 60 },
      { name: "chest", min: 70, max: 160 },
      { name: "waist", min: 50, max: 150 },
      { name: "top_length", min: 55, max: 100 },
      { name: "thigh", min: 40, max: 90 },
      { name: "hip", min: 70, max: 160 },
      { name: "knee", min: 25, max: 60 },
      { name: "shin", min: 20, max: 50 },
      { name: "waist_to_knee", min: 40, max: 75 },
      { name: "trouser_length", min: 80, max: 120 },
      { name: "trouser_inseam", min: 60, max: 95 },
      { name: "biceps", min: 20, max: 50 },
      { name: "sleeve_length", min: 15, max: 70 },
      { name: "neck", min: 25, max: 55 },
    ]);
    const women = new Map(MANUAL_TEMPLATES.women.map((m) => [m.name, m]));
    const shared = MANUAL_TEMPLATES.men.filter((m) => women.has(m.name));
    expect(shared.map((m) => m.name)).toEqual([
      "shoulder",
      "waist",
      "thigh",
      "knee",
      "waist_to_knee",
      "trouser_length",
      "sleeve_length",
    ]);
    for (const m of shared) expect(women.get(m.name)).toEqual(m);
  });

  it("out-of-range values prompt the double-check advisory, never a block", () => {
    // The DEFAULT display unit is inches (A-9) — the canonical cm range
    // converts for display so it matches what the user typed.
    expect(manualAdvisory(155, 50, 150)).toBe(
      "Double-check this one — outside the usual 19.7–59.1 in.",
    );
    // cm stays available via the toggle — the range reads canonical cm.
    expect(manualAdvisory(155, 50, 150, "cm")).toBe(
      "Double-check this one — outside the usual 50–150 cm.",
    );
    expect(manualAdvisory(78, 50, 150)).toBeUndefined();
    expect(manualAdvisory(null, 50, 150)).toBeUndefined();
  });

  it("interposes the one-time Women/Men chooser when the account has no template", async () => {
    const onTemplateChange = vi.fn().mockResolvedValue(undefined);
    render(
      <ManualEntrySheet
        open
        onOpenChange={() => {}}
        onSave={vi.fn()}
        template={null}
        onTemplateChange={onTemplateChange}
      />,
    );
    // Chooser replaces the rows entirely — no inputs yet, no save CTA.
    expect(
      screen.queryByRole("button", { name: "Save to vault" }),
    ).not.toBeInTheDocument();
    await userEvent.click(
      screen.getByRole("button", { name: "Women’s measurements" }),
    );
    expect(onTemplateChange).toHaveBeenCalledWith("women");
  });

  it("collects no height and saves inches-entered values as canonical cm", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(
      <ManualEntrySheet
        open
        onOpenChange={() => {}}
        onSave={onSave}
        template="women"
        onTemplateChange={vi.fn()}
      />,
    );

    // No height field — manual sessions carry input_height_cm: null
    // (flows/vault.md §2; the fabricated 168 default is gone).
    expect(screen.queryByLabelText(/height/i)).not.toBeInTheDocument();

    const save = screen.getByRole("button", { name: "Save to vault" });
    expect(save).toBeDisabled();

    // Entry is in inches by default (A-9): 61 in = 154.94 cm — over the
    // 150 cm waist ceiling, so the advisory renders in inches.
    const waist = screen.getByLabelText("Waist value");
    await userEvent.clear(waist);
    await userEvent.type(waist, "61");
    // The advisory renders inline and saving stays possible (non-blocking).
    expect(
      screen.getByText(
        "Double-check this one — outside the usual 19.7–59.1 in.",
      ),
    ).toBeInTheDocument();
    expect(save).toBeEnabled();
    await userEvent.click(save);
    // The payload stays canonical cm whatever the display unit.
    expect(onSave).toHaveBeenCalledWith([
      { name: "waist", value_cm: expect.closeTo(154.94, 2) },
    ]);
  });

  it("defaults the MI-13 toggle to inches; cm stays one flip away (A-9)", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(
      <ManualEntrySheet
        open
        onOpenChange={() => {}}
        onSave={onSave}
        template="men"
        onTemplateChange={vi.fn()}
      />,
    );

    // Every row of the men template renders the toggle, "in" active.
    const toggles = screen.getAllByRole("button", {
      name: "Switch units (currently in)",
    });
    expect(toggles).toHaveLength(MANUAL_TEMPLATES.men.length);

    // One shared unit state drives all rows: flip once, all flip.
    await userEvent.click(toggles[0]);
    expect(
      screen.getAllByRole("button", { name: "Switch units (currently cm)" }),
    ).toHaveLength(MANUAL_TEMPLATES.men.length);

    // cm entry passes through unconverted (storage is canonical cm) and
    // the advisory reads the canonical cm range.
    const waist = screen.getByLabelText("Waist value");
    await userEvent.type(waist, "155");
    expect(
      screen.getByText("Double-check this one — outside the usual 50–150 cm."),
    ).toBeInTheDocument();
    await userEvent.click(
      screen.getByRole("button", { name: "Save to vault" }),
    );
    expect(onSave).toHaveBeenCalledWith([{ name: "waist", value_cm: 155 }]);
  });
});
