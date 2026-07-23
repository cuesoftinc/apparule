// B4 upload view (Figma 549:2, M-10/M-12): header + hint line, labeled
// per-pose dropzones, height prefill (no fabricated default; inches are
// the default display unit per A-9 — the payload stays user_height_cm),
// and the submit gate (both files + valid height). The per-pose QC
// round-trip is e2e-covered (dashboard.spec.ts).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

vi.mock("@/models/repositories/vault-repo", () => ({
  vaultRepo: {
    createCaptureSession: vi.fn(),
    saveSession: vi.fn(),
    deleteSession: vi.fn(),
  },
}));

import { vaultRepo } from "@/models/repositories/vault-repo";
import { UploadMeasurementsView } from "./UploadMeasurementsView";

beforeEach(() => {
  // jsdom lacks createObjectURL
  vi.stubGlobal(
    "URL",
    Object.assign(URL, {
      createObjectURL: () => "blob:mock",
      revokeObjectURL: () => {},
    }),
  );
});

const pickPose = (pose: "front" | "side", name: string) => {
  const input = screen.getByTestId(`capture-file-${pose}`);
  fireEvent.change(input, {
    target: { files: [new File(["x"], name, { type: "image/jpeg" })] },
  });
};

describe("UploadMeasurementsView (B4 upload, 549:2)", () => {
  it("renders the two-photo header, the app hint, and both pose dropzones", () => {
    render(
      <UploadMeasurementsView
        prefillHeightCm={null}
        onBack={() => {}}
        onSaved={() => {}}
      />,
    );
    expect(
      screen.getByRole("heading", { name: "Upload measurements" }),
    ).toBeInTheDocument();
    expect(
      screen.getByText(
        "Two photos — front and side — plus your height. We map 33 landmarks per photo.",
      ),
    ).toBeInTheDocument();
    expect(
      screen.getByText("Best experience: guided capture on the Apparule app"),
    ).toBeInTheDocument();
    expect(screen.getByText("Front photo")).toBeInTheDocument();
    expect(screen.getByText("Side photo")).toBeInTheDocument();
  });

  it("prefills height in inches (A-9 default) — empty when none", () => {
    const { unmount } = render(
      <UploadMeasurementsView
        prefillHeightCm={168}
        onBack={() => {}}
        onSaved={() => {}}
      />,
    );
    // 168 cm canonical renders as 66.1 in — inches are the default
    // display unit; the field is labeled for the active unit.
    expect(screen.getByLabelText("Height in inches")).toHaveValue("66.1");
    expect(screen.getByText("Height (in)")).toBeInTheDocument();
    expect(
      screen.getByText("Used to scale your photos — 39–91 in"),
    ).toBeInTheDocument();
    unmount();
    render(
      <UploadMeasurementsView
        prefillHeightCm={null}
        onBack={() => {}}
        onSaved={() => {}}
      />,
    );
    // Nullable ruling: no fabricated default.
    expect(screen.getByLabelText("Height in inches")).toHaveValue("");
  });

  it("unit toggle round-trips exactly and the payload stays user_height_cm", async () => {
    render(
      <UploadMeasurementsView
        prefillHeightCm={168}
        onBack={() => {}}
        onSaved={() => {}}
      />,
    );

    // Flip to cm: same physical height, canonical figure restored exactly.
    await userEvent.click(
      screen.getByRole("button", { name: "Switch units (currently in)" }),
    );
    expect(screen.getByLabelText("Height in centimeters")).toHaveValue("168");
    expect(screen.getByText("Height (cm)")).toBeInTheDocument();
    expect(
      screen.getByText("Used to scale your photos — 100–230 cm"),
    ).toBeInTheDocument();

    // And back to inches — the display round-trips with no drift.
    await userEvent.click(
      screen.getByRole("button", { name: "Switch units (currently cm)" }),
    );
    expect(screen.getByLabelText("Height in inches")).toHaveValue("66.1");

    // Submitting the untouched prefill sends exactly 168 — the 1-decimal
    // inch display never drifts into the user_height_cm payload.
    pickPose("front", "front.jpg");
    pickPose("side", "side.jpg");
    await userEvent.click(screen.getByTestId("get-measurements"));
    expect(vaultRepo.createCaptureSession).toHaveBeenCalledWith(
      expect.any(File),
      expect.any(File),
      168,
      expect.any(String),
    );
  });

  it("gates the CTA on both poses + a valid height (100–230 cm canonical)", async () => {
    render(
      <UploadMeasurementsView
        prefillHeightCm={null}
        onBack={() => {}}
        onSaved={() => {}}
      />,
    );
    const cta = screen.getByTestId("get-measurements");
    expect(cta).toBeDisabled();

    pickPose("front", "front.jpg");
    pickPose("side", "side.jpg");
    expect(cta).toBeDisabled(); // still no height

    // Entry is in inches by default: 39 in = 99.1 cm (under the 100 cm
    // floor) stays gated; 67 in = 170.2 cm passes.
    const height = screen.getByLabelText("Height in inches");
    await userEvent.type(height, "39");
    expect(cta).toBeDisabled(); // out of range
    await userEvent.clear(height);
    await userEvent.type(height, "67");
    expect(cta).toBeEnabled();

    // Uploaded state shows the file meta + Replace affordance (549:2).
    expect(screen.getByText(/front\.jpg · uploaded/)).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: "Replace" })).toHaveLength(2);
  });

  it("rejects a >10MB photo with an inline error, not a QC state", () => {
    render(
      <UploadMeasurementsView
        prefillHeightCm={null}
        onBack={() => {}}
        onSaved={() => {}}
      />,
    );
    const big = new File([new ArrayBuffer(1)], "big.jpg", {
      type: "image/jpeg",
    });
    Object.defineProperty(big, "size", { value: 11 * 1024 * 1024 });
    fireEvent.change(screen.getByTestId("capture-file-front"), {
      target: { files: [big] },
    });
    expect(
      screen.getByText("That photo is over 10 MB — try a smaller one."),
    ).toBeInTheDocument();
  });

  it("fires onBack from the back link", async () => {
    const onBack = vi.fn();
    render(
      <UploadMeasurementsView
        prefillHeightCm={null}
        onBack={onBack}
        onSaved={() => {}}
      />,
    );
    await userEvent.click(
      screen.getByRole("button", { name: /Back to vault/ }),
    );
    expect(onBack).toHaveBeenCalledOnce();
  });
});
