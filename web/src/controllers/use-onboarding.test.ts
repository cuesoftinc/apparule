// Onboarding controller — B8 Paystack resolution states, the 3-fail support
// link, and the attach → done transition (flows/designer.md §1).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook } from "@testing-library/react";
import { ApiError } from "@/lib/api";

const enable = vi.fn();
const resolveBank = vi.fn();
const attachPayoutAccount = vi.fn();
const getProfile = vi.fn();
vi.mock("@/models/repositories/designer-repo", () => ({
  designerRepo: {
    enable: (...a: unknown[]) => enable(...a),
    resolveBank: (...a: unknown[]) => resolveBank(...a),
    attachPayoutAccount: (...a: unknown[]) => attachPayoutAccount(...a),
  },
}));
vi.mock("@/models/repositories/profiles-repo", () => ({
  profilesRepo: { get: (...a: unknown[]) => getProfile(...a) },
}));

import { MAX_RESOLUTION_FAILS, useOnboarding } from "./use-onboarding";

beforeEach(() => {
  enable.mockReset();
  resolveBank.mockReset();
  attachPayoutAccount.mockReset();
  getProfile.mockReset();
});

describe("useOnboarding", () => {
  it("walks intro → profile → banking → done", async () => {
    enable.mockResolvedValue({ id: "des-1", username: "kiki.adeyemi" });
    resolveBank.mockResolvedValue({
      account_name: "KIKI ADEYEMI",
      bank_code: "058",
      account_number: "0123456789",
    });
    attachPayoutAccount.mockResolvedValue({ kyc_state: "verified" });

    const { result } = renderHook(() => useOnboarding());
    expect(result.current.step).toBe("intro");
    act(() => result.current.begin());
    expect(result.current.step).toBe("profile");
    await act(() => result.current.enable("Kiki Studio", "Bio"));
    expect(result.current.step).toBe("banking");
    await act(() => result.current.resolve("058", "0123456789"));
    expect(result.current.resolution.phase).toBe("resolved");
    await act(() => result.current.attach());
    expect(result.current.step).toBe("done");
    expect(result.current.payout?.kyc_state).toBe("verified");
  });

  it("shows the support link after 3 resolution failures", async () => {
    resolveBank.mockRejectedValue(
      new ApiError("bank_resolution_failed", "Could not resolve", 422),
    );
    const { result } = renderHook(() => useOnboarding());
    for (let i = 0; i < MAX_RESOLUTION_FAILS; i += 1) {
      await act(() => result.current.resolve("058", "0000000000"));
    }
    expect(result.current.resolution.phase).toBe("failed");
    expect(result.current.showSupportLink).toBe(true);
  });

  it("surfaces the existing payout account for returning designers", async () => {
    getProfile.mockResolvedValue({
      kind: "designer",
      designer: {
        payout_account: { kyc_state: "lapsed" },
      },
      viewer_follows: false,
      viewer_is_self: true,
    });
    const { result } = renderHook(() => useOnboarding("kiki.adeyemi"));
    await act(async () => {
      await Promise.resolve();
    });
    expect(result.current.existingPayout?.kyc_state).toBe("lapsed");
  });
});
