// B4 capture sheets — options (photo upload / manual entry + the M-12
// mobile-app hint) and manual entry (no height row — input_height_cm is
// null for method: manual; out-of-range advisory per flows/vault.md §2).
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
    expect(manualAdvisory(155, 40, 150)).toBe(
      "Double-check this one — outside the usual 40–150 cm.",
    );
    expect(manualAdvisory(78, 40, 150)).toBeUndefined();
    expect(manualAdvisory(null, 40, 150)).toBeUndefined();
  });

  it("collects no height and saves measurements only", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(<ManualEntrySheet open onOpenChange={() => {}} onSave={onSave} />);

    // No height field — manual sessions carry input_height_cm: null
    // (flows/vault.md §2; the fabricated 168 default is gone).
    expect(screen.queryByLabelText(/height/i)).not.toBeInTheDocument();

    const save = screen.getByRole("button", { name: "Save to vault" });
    expect(save).toBeDisabled();

    const waist = screen.getByLabelText("Waist Girth value");
    await userEvent.clear(waist);
    await userEvent.type(waist, "155");
    // The advisory renders inline and saving stays possible (non-blocking).
    expect(
      screen.getByText("Double-check this one — outside the usual 40–150 cm."),
    ).toBeInTheDocument();
    expect(save).toBeEnabled();
    await userEvent.click(save);
    expect(onSave).toHaveBeenCalledWith([
      { name: "waist_girth", value_cm: 155 },
    ]);
  });
});
