// B6 profile header — MI-11: the OWN avatar wears the measurement-
// freshness ring (C9 construction); other people's designer avatars keep
// the B6 story-ring (gradient).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render } from "@testing-library/react";
import type { PublicProfile } from "@/models";
import { ToastProvider } from "../toast-context";

const usePublicProfileMock = vi.fn();
const useVaultMock = vi.fn();

vi.mock("@/controllers/auth/AuthContext", () => ({
  useAuth: () => ({
    status: "signed_in",
    account: { username: "kiki.adeyemi", display_name: "Kiki Adeyemi" },
  }),
}));
vi.mock("@/controllers/use-public-profile", () => ({
  usePublicProfile: (...a: unknown[]) => usePublicProfileMock(...a),
  useFollowList: () => ({
    loading: true,
    rows: [],
    toggleFollow: vi.fn(),
  }),
}));
vi.mock("@/controllers/use-vault", () => ({
  useVault: (...a: unknown[]) => useVaultMock(...a),
}));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn(), replace: vi.fn() }),
}));

import { ProfileView } from "./ProfileView";

function profileResult(profile: PublicProfile) {
  return {
    profile,
    posts: [],
    saved: [],
    loading: false,
    error: null,
    toggleFollow: vi.fn(),
    syncPost: vi.fn(),
  };
}

const ownUserProfile: PublicProfile = {
  kind: "user",
  account: {
    username: "kiki.adeyemi",
    display_name: "Kiki Adeyemi",
    avatar_url: null,
  },
  viewer_is_self: true,
};

function designerProfile(selfViewing: boolean): PublicProfile {
  return {
    kind: "designer",
    designer: {
      id: "des-amara",
      account_id: "acc-amara",
      username: "amara.designs",
      display_name: "Amara Designs",
      bio: "Ankara & contemporary tailoring.",
      avatar_url: null,
      payout_account: {
        provider_ref: null,
        bank_name: null,
        account_last4: null,
        kyc_state: "none",
      },
      verified: true,
      location: { city: "Lagos", state: "Lagos", country: "NG" },
      followers_count: 8,
      following_count: 2,
      posts_count: 0,
    },
    viewer_follows: false,
    viewer_is_self: selfViewing,
  };
}

function renderProfile(profile: PublicProfile, username: string) {
  usePublicProfileMock.mockReturnValue(profileResult(profile));
  return render(
    <ToastProvider>
      <ProfileView username={username} />
    </ToastProvider>,
  );
}

beforeEach(() => {
  usePublicProfileMock.mockReset();
  useVaultMock.mockReset();
  useVaultMock.mockReturnValue({ freshness: "aging", loading: false });
});

describe("ProfileView — own-profile freshness ring (MI-11)", () => {
  it("own regular-user profile wears the freshness ring (aging → amber)", () => {
    const { container } = renderProfile(ownUserProfile, "kiki.adeyemi");
    expect(container.querySelector('[data-ring="amber"]')).not.toBeNull();
  });

  it.each([
    ["fresh", "gradient"],
    ["stale", "gray"],
  ] as const)("freshness %s renders ring=%s", (freshness, ring) => {
    useVaultMock.mockReturnValue({ freshness, loading: false });
    const { container } = renderProfile(ownUserProfile, "kiki.adeyemi");
    expect(container.querySelector(`[data-ring="${ring}"]`)).not.toBeNull();
  });

  it("no ring while the vault is still loading", () => {
    useVaultMock.mockReturnValue({ freshness: null, loading: true });
    const { container } = renderProfile(ownUserProfile, "kiki.adeyemi");
    expect(container.querySelector('[data-ring="none"]')).not.toBeNull();
  });

  it("someone else's regular-user profile never fetches the vault", () => {
    renderProfile(
      {
        ...ownUserProfile,
        account: { ...ownUserProfile.account, username: "ada.eze" },
        viewer_is_self: false,
      },
      "ada.eze",
    );
    expect(useVaultMock).not.toHaveBeenCalled();
  });

  it("own designer profile wears the freshness ring too", () => {
    const { container } = renderProfile(designerProfile(true), "kiki.adeyemi");
    expect(container.querySelector('[data-ring="amber"]')).not.toBeNull();
  });

  it("other designers keep the gradient story ring (B6)", () => {
    const { container } = renderProfile(
      designerProfile(false),
      "amara.designs",
    );
    expect(container.querySelector('[data-ring="gradient"]')).not.toBeNull();
    expect(useVaultMock).not.toHaveBeenCalled();
  });
});
