// Create chooser (M-11, 548:9490): two choice cards — measurements primary
// (accent border) → B4 capture options; post designer-gated with the
// become-a-designer subtitle for non-designers.
import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";

const useAuthMock = vi.fn();
vi.mock("@/auth/AuthContext", () => ({
  useAuth: (...a: unknown[]) => useAuthMock(...a),
}));

import { CreateChooserSheet } from "./CreateChooserSheet";

function renderChooser(designerEnabled: boolean) {
  useAuthMock.mockReturnValue({
    status: "signed_in",
    account: {
      username: "kiki.adeyemi",
      designer: { enabled: designerEnabled, kyc_complete: false },
    },
  });
  return render(<CreateChooserSheet open onOpenChange={() => {}} />);
}

describe("CreateChooserSheet (M-11)", () => {
  it("offers Take measurements (primary → vault capture) + Post an outfit", () => {
    renderChooser(false);
    expect(screen.getByRole("dialog", { name: "Create" })).toBeInTheDocument();

    const measure = screen.getByTestId("create-choice-measure");
    expect(measure).toHaveAttribute("href", "/dashboard/vault?capture=1");
    expect(measure).toHaveTextContent("Take measurements");
    expect(measure).toHaveTextContent("Two photos — about a minute");
    // primary card carries the accent border (548:9490)
    expect(measure.className).toContain("border-accent-start");

    const post = screen.getByTestId("create-choice-post");
    expect(post).toHaveAttribute("href", "/dashboard/create");
    expect(post).toHaveTextContent("Post an outfit");
  });

  it("gates the post subtitle on designer status", () => {
    const { unmount } = renderChooser(false);
    expect(screen.getByTestId("create-choice-post")).toHaveTextContent(
      "Become a designer to post",
    );
    unmount();
    renderChooser(true);
    expect(screen.getByTestId("create-choice-post")).toHaveTextContent(
      "Share a look with its fit data",
    );
  });
});
