import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { Avatar, freshnessRing } from "./Avatar";

describe("Avatar (§8.2)", () => {
  it("falls back to initials when there is no image", () => {
    render(<Avatar name="Kiki Adeyemi" />);
    expect(screen.getByRole("img", { name: "Kiki Adeyemi" })).toHaveTextContent(
      "KA",
    );
  });

  it("shows the designer-verified badge", () => {
    render(<Avatar name="Amara Designs" verified />);
    expect(screen.getByTestId("verified-badge")).toBeInTheDocument();
  });

  it("freshnessRing maps the MI-11 bands (gradient/amber/gray, gray when empty)", () => {
    expect(freshnessRing("fresh")).toBe("gradient");
    expect(freshnessRing("aging")).toBe("amber");
    expect(freshnessRing("stale")).toBe("gray");
    expect(freshnessRing(null)).toBe("gray");
  });
});
