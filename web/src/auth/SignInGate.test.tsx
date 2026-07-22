// SignInGate — flows/auth.md §2 reverse guard: signed_in replaces to
// /dashboard (never renders the CTA), loading holds the aria-busy gate,
// signed_out renders the auth content.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";

const useAuthMock = vi.fn();
vi.mock("@/auth/AuthContext", () => ({
  useAuth: (...a: unknown[]) => useAuthMock(...a),
}));
const replace = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace, push: vi.fn(), back: vi.fn() }),
}));

import { SignInGate } from "./SignInGate";

beforeEach(() => {
  replace.mockReset();
});

describe("SignInGate (flows/auth.md §2)", () => {
  it("signed_out renders the auth content", () => {
    useAuthMock.mockReturnValue({ status: "signed_out" });
    render(
      <SignInGate>
        <p>CTA</p>
      </SignInGate>,
    );
    expect(screen.getByText("CTA")).toBeInTheDocument();
    expect(screen.queryByTestId("signin-gate")).not.toBeInTheDocument();
    expect(replace).not.toHaveBeenCalled();
  });

  it("loading holds the aria-busy gate — the CTA never paints pre-restore", () => {
    useAuthMock.mockReturnValue({ status: "loading" });
    render(
      <SignInGate>
        <p>CTA</p>
      </SignInGate>,
    );
    expect(screen.getByTestId("signin-gate")).toHaveAttribute(
      "aria-busy",
      "true",
    );
    expect(screen.queryByText("CTA")).not.toBeInTheDocument();
    expect(replace).not.toHaveBeenCalled();
  });

  it("signed_in replaces to /dashboard — a signed-in user never sees /signin", () => {
    useAuthMock.mockReturnValue({ status: "signed_in" });
    render(
      <SignInGate>
        <p>CTA</p>
      </SignInGate>,
    );
    expect(replace).toHaveBeenCalledWith("/dashboard");
    expect(screen.queryByText("CTA")).not.toBeInTheDocument();
  });
});
