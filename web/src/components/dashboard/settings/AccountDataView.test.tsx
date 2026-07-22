// B7 Account & data — danger ladder (Decided 2026-07-22): quiet-danger row
// rung; armed confirm = typed DELETE gate + export-first escape + Cancel;
// filled destructive only inside the armed sheet.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const requestDeletion = vi.fn();
const useSettingsMock = vi.fn();
vi.mock("@/controllers/use-settings", () => ({
  useSettings: (...a: unknown[]) => useSettingsMock(...a),
}));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), back: vi.fn() }),
}));

import { AccountDataView } from "./AccountDataView";
import { ToastProvider } from "../toast-context";

beforeEach(() => {
  requestDeletion.mockReset().mockResolvedValue({});
  useSettingsMock.mockReturnValue({
    account: { deletion_state: "active" },
    exporting: false,
    deleting: false,
    exportData: vi.fn().mockResolvedValue("blob:mock"),
    requestDeletion,
  });
});

function renderView() {
  return render(
    <ToastProvider>
      <AccountDataView />
    </ToastProvider>,
  );
}

describe("AccountDataView danger ladder", () => {
  it("row rung renders quiet-danger; filled destructive only in the armed sheet", async () => {
    renderView();
    const row = screen.getByTestId("delete-all");
    expect(row).toHaveAttribute("data-kind", "quiet-danger");
    await userEvent.click(row);
    expect(screen.getByTestId("confirm-delete-all")).toHaveAttribute(
      "data-kind",
      "destructive",
    );
  });

  it("typed DELETE arms the confirm; the export-first escape hatch is present", async () => {
    renderView();
    await userEvent.click(screen.getByTestId("delete-all"));

    const confirm = screen.getByTestId("confirm-delete-all");
    expect(confirm).toBeDisabled();
    expect(screen.getByTestId("export-first")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Cancel" })).toBeInTheDocument();

    await userEvent.type(screen.getByTestId("delete-confirm-input"), "delete");
    expect(confirm).toBeDisabled(); // exact token

    await userEvent.clear(screen.getByTestId("delete-confirm-input"));
    await userEvent.type(screen.getByTestId("delete-confirm-input"), "DELETE");
    expect(confirm).toBeEnabled();
    await userEvent.click(confirm);
    expect(requestDeletion).toHaveBeenCalledOnce();
  });

  it("closing the sheet disarms the typed token", async () => {
    renderView();
    await userEvent.click(screen.getByTestId("delete-all"));
    await userEvent.type(screen.getByTestId("delete-confirm-input"), "DELETE");
    await userEvent.click(screen.getByRole("button", { name: "Cancel" }));
    // re-open: the gate must be armed again from scratch
    await userEvent.click(screen.getByTestId("delete-all"));
    expect(screen.getByTestId("delete-confirm-input")).toHaveValue("");
    expect(screen.getByTestId("confirm-delete-all")).toBeDisabled();
  });
});
