import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { Avatar, freshnessRing } from "./Avatar";

describe("Avatar (§8.2)", () => {
  it.each([32, 44, 56, 64, 96] as const)("renders size=%s", (size) => {
    const { container } = render(<Avatar size={size} name="Kiki Adeyemi" />);
    expect(container.querySelector(`[data-size="${size}"]`)).not.toBeNull();
  });

  it.each(["none", "gradient", "amber", "gray"] as const)(
    "renders ring=%s (MI-8/MI-11)",
    (ring) => {
      const { container } = render(<Avatar ring={ring} name="Kiki Adeyemi" />);
      expect(container.querySelector(`[data-ring="${ring}"]`)).not.toBeNull();
    },
  );

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
