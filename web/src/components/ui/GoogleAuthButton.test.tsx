// GoogleAuthButton behavior: TEST_MODE routes to /dashboard on success;
// otherwise the button hands the browser to the Google flow.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { GoogleAuthButton } from "./GoogleAuthButton";
import type { SignInResult } from "@/auth/types";

const push = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push }),
}));

const signInWithGoogle = vi.fn<() => Promise<SignInResult>>();
vi.mock("@/auth/AuthContext", () => ({
  useAuth: () => ({
    status: "signed_out",
    account: null,
    providerName: "test-mode",
    signInWithGoogle,
    signOut: vi.fn(),
  }),
}));

beforeEach(() => {
  push.mockClear();
  signInWithGoogle.mockReset();
});

describe("GoogleAuthButton", () => {
  it("renders the single Google CTA (X-1)", () => {
    render(<GoogleAuthButton />);
    expect(
      screen.getByRole("button", { name: /continue with google/i }),
    ).toBeInTheDocument();
  });

  it("routes straight to /dashboard when sign-in succeeds (TEST_MODE)", async () => {
    signInWithGoogle.mockResolvedValue({
      ok: true,
      session: { account: { username: "kiki.adeyemi" } as never },
    });
    render(<GoogleAuthButton />);
    await userEvent.click(screen.getByRole("button"));
    await waitFor(() => expect(push).toHaveBeenCalledWith("/dashboard"));
  });

  it("shows the notice when Google sign-in is unavailable", async () => {
    signInWithGoogle.mockResolvedValue({
      ok: false,
      code: "sso_unavailable",
      message: "Google sign-in is unavailable in this browser.",
    });
    render(<GoogleAuthButton />);
    await userEvent.click(screen.getByRole("button"));
    expect(
      await screen.findByText("Google sign-in is unavailable in this browser."),
    ).toBeInTheDocument();
    expect(push).not.toHaveBeenCalled();
  });

  it("stays silent while the browser redirects to Google", async () => {
    signInWithGoogle.mockResolvedValue({
      ok: false,
      code: "redirecting",
      message: "Continuing to Google…",
    });
    render(<GoogleAuthButton />);
    await userEvent.click(screen.getByRole("button"));
    await waitFor(() => expect(signInWithGoogle).toHaveBeenCalled());
    expect(screen.queryByRole("status")).not.toBeInTheDocument();
    expect(push).not.toHaveBeenCalled();
  });

  it("is disabled when disabled prop is set", async () => {
    render(<GoogleAuthButton disabled />);
    expect(screen.getByRole("button")).toBeDisabled();
    await userEvent.click(screen.getByRole("button"));
    expect(signInWithGoogle).not.toHaveBeenCalled();
  });
});
