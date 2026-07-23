// AuthContext restore net — flows/auth.md §2: a failed restore reads as
// signed out (never a stranded aria-busy gate). Providers contract to
// resolve null; this exercises the second net against a rejecting one.
import { describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";

const restore = vi.fn();
vi.mock("./test-mode-provider", () => ({
  TestModeAuthProvider: class {
    name = "test-mode" as const;
    restore = (...a: unknown[]) => restore(...a);
    signInWithGoogle = vi.fn();
    signOut = vi.fn();
  },
}));
vi.mock("@/config/env", () => ({ env: { testMode: true } }));

import { AuthProvider, useAuth } from "./AuthContext";

function Probe() {
  const { status } = useAuth();
  return <p data-testid="status">{status}</p>;
}

describe("AuthContext session restore (flows/auth.md §2)", () => {
  it("a rejecting restore reads as signed_out, not a permanent loading gate", async () => {
    restore.mockRejectedValue(new Error("firebase exploded"));
    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    await waitFor(() =>
      expect(screen.getByTestId("status")).toHaveTextContent("signed_out"),
    );
  });

  it("a null restore reads as signed_out", async () => {
    restore.mockResolvedValue(null);
    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    await waitFor(() =>
      expect(screen.getByTestId("status")).toHaveTextContent("signed_out"),
    );
  });
});
