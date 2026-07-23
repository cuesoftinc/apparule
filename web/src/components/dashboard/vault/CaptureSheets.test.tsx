// B4 capture sheets — options (photo upload / manual entry + the M-12
// mobile-app hint) and manual entry (no height row — input_height_cm is
// null for method: manual; out-of-range advisory per flows/vault.md §2;
// inches are the default display unit per A-9, storage stays cm).
import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import {
  CaptureOptionsSheet,
  ManualEntrySheet,
  MANUAL_METRICS,
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

describe("ManualEntrySheet (MI-13)", () => {
  it("advisory table matches the canonical flows/vault.md §2 ranges (waist 150)", () => {
    expect(MANUAL_METRICS).toEqual([
      { name: "shoulder_width", min: 25, max: 75 },
      { name: "hip_width", min: 20, max: 70 },
      { name: "chest_girth", min: 50, max: 160 },
      { name: "waist_girth", min: 40, max: 150 },
    ]);
  });

  it("out-of-range values prompt the double-check advisory, never a block", () => {
    // The DEFAULT display unit is inches (A-9) — the canonical cm range
    // converts for display so it matches what the user typed.
    expect(manualAdvisory(155, 40, 150)).toBe(
      "Double-check this one — outside the usual 15.7–59.1 in.",
    );
    // cm stays available via the toggle — the range reads canonical cm.
    expect(manualAdvisory(155, 40, 150, "cm")).toBe(
      "Double-check this one — outside the usual 40–150 cm.",
    );
    expect(manualAdvisory(78, 40, 150)).toBeUndefined();
    expect(manualAdvisory(null, 40, 150)).toBeUndefined();
  });

  it("collects no height and saves inches-entered values as canonical cm", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(<ManualEntrySheet open onOpenChange={() => {}} onSave={onSave} />);

    // No height field — manual sessions carry input_height_cm: null
    // (flows/vault.md §2; the fabricated 168 default is gone).
    expect(screen.queryByLabelText(/height/i)).not.toBeInTheDocument();

    const save = screen.getByRole("button", { name: "Save to vault" });
    expect(save).toBeDisabled();

    // Entry is in inches by default (A-9): 61 in = 154.94 cm — over the
    // 150 cm waist ceiling, so the advisory renders in inches.
    const waist = screen.getByLabelText("Waist Girth value");
    await userEvent.clear(waist);
    await userEvent.type(waist, "61");
    // The advisory renders inline and saving stays possible (non-blocking).
    expect(
      screen.getByText(
        "Double-check this one — outside the usual 15.7–59.1 in.",
      ),
    ).toBeInTheDocument();
    expect(save).toBeEnabled();
    await userEvent.click(save);
    // The payload stays canonical cm whatever the display unit.
    expect(onSave).toHaveBeenCalledWith([
      { name: "waist_girth", value_cm: expect.closeTo(154.94, 2) },
    ]);
  });

  it("defaults the MI-13 toggle to inches; cm stays one flip away (A-9)", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(<ManualEntrySheet open onOpenChange={() => {}} onSave={onSave} />);

    // Every row renders the toggle with "in" active by default.
    const toggles = screen.getAllByRole("button", {
      name: "Switch units (currently in)",
    });
    expect(toggles).toHaveLength(MANUAL_METRICS.length);

    // One shared unit state drives all rows: flip once, all flip.
    await userEvent.click(toggles[0]);
    expect(
      screen.getAllByRole("button", { name: "Switch units (currently cm)" }),
    ).toHaveLength(MANUAL_METRICS.length);

    // cm entry passes through unconverted (storage is canonical cm) and
    // the advisory reads the canonical cm range.
    const waist = screen.getByLabelText("Waist Girth value");
    await userEvent.type(waist, "155");
    expect(
      screen.getByText("Double-check this one — outside the usual 40–150 cm."),
    ).toBeInTheDocument();
    await userEvent.click(
      screen.getByRole("button", { name: "Save to vault" }),
    );
    expect(onSave).toHaveBeenCalledWith([
      { name: "waist_girth", value_cm: 155 },
    ]);
  });
});
