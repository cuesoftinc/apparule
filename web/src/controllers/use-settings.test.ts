// Settings controller — B7: optimistic pref toggles with rollback (MI-18),
// export blob, deletion request.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook, waitFor } from "@testing-library/react";

const me = vi.fn();
const consent = vi.fn();
const updateMe = vi.fn();
const exportData = vi.fn();
const requestDeletion = vi.fn();
vi.mock("@/models/repositories/account-repo", () => ({
  accountRepo: {
    me: (...a: unknown[]) => me(...a),
    consent: (...a: unknown[]) => consent(...a),
    updateMe: (...a: unknown[]) => updateMe(...a),
    exportData: (...a: unknown[]) => exportData(...a),
    requestDeletion: (...a: unknown[]) => requestDeletion(...a),
  },
}));

import { useSettings } from "./use-settings";

const account = {
  id: "acc-kiki",
  username: "kiki.adeyemi",
  display_name: "Kiki Adeyemi",
  deletion_state: "active",
  designer: { enabled: false, kyc_complete: false },
  is_staff: true,
  notification_prefs: {
    quotes: true,
    order_status: true,
    social: true,
    payouts: true,
  },
  consent: [],
};

beforeEach(() => {
  me.mockReset();
  consent.mockReset();
  updateMe.mockReset();
  exportData.mockReset();
  requestDeletion.mockReset();
  me.mockResolvedValue(account);
  consent.mockResolvedValue([
    { document: "tos", version: "1.0", accepted_at: "2026-06-09T00:00:00Z" },
  ]);
});

describe("useSettings", () => {
  it("loads account + consent history", async () => {
    const { result } = renderHook(() => useSettings());
    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.account?.username).toBe("kiki.adeyemi");
    expect(result.current.consent).toHaveLength(1);
  });

  it("persists pref toggles through PATCH /me", async () => {
    updateMe.mockResolvedValue({
      ...account,
      notification_prefs: { ...account.notification_prefs, quotes: false },
    });
    const { result } = renderHook(() => useSettings());
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.setPref("quotes", false));
    expect(updateMe).toHaveBeenCalledWith({
      notification_prefs: { quotes: false },
    });
    expect(result.current.account?.notification_prefs.quotes).toBe(false);
  });

  it("rolls back the optimistic toggle on failure (MI-18)", async () => {
    updateMe.mockRejectedValue(new Error("boom"));
    const { result } = renderHook(() => useSettings());
    await waitFor(() => expect(result.current.loading).toBe(false));
    await expect(
      act(() => result.current.setPref("quotes", false)),
    ).rejects.toThrow("pref_failed");
    expect(result.current.account?.notification_prefs.quotes).toBe(true);
  });

  it("flags deletion_pending after a delete-all request", async () => {
    requestDeletion.mockResolvedValue({
      ...account,
      deletion_state: "deletion_pending",
    });
    const { result } = renderHook(() => useSettings());
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.requestDeletion());
    expect(result.current.account?.deletion_state).toBe("deletion_pending");
  });
});
