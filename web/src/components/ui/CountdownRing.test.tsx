import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { CountdownRing } from "./CountdownRing";

describe("CountdownRing (§8.2b)", () => {
  it.each([3, 2, 1] as const)("renders numeral + ring for %s", (value) => {
    render(<CountdownRing value={value} />);
    const ring = screen.getByRole("timer", { name: `Capturing in ${value}` });
    expect(ring).toHaveAttribute("data-value", String(value));
    expect(ring).toHaveTextContent(String(value));
  });

  it("ring progress arc shrinks with the remaining fraction", () => {
    const { container, rerender } = render(<CountdownRing value={3} />);
    const arcAt = () =>
      Number(
        container
          .querySelectorAll("circle")[1]
          ?.getAttribute("stroke-dashoffset"),
      );
    const full = arcAt(); // 3/3 → offset 0
    expect(full).toBeCloseTo(0, 5);
    rerender(<CountdownRing value={1} />);
    expect(arcAt()).toBeGreaterThan(0); // 1/3 → two-thirds unwound
  });

  it("numeral pop respects reduced motion", () => {
    render(<CountdownRing value={2} />);
    const numeral = screen.getByText("2");
    expect(numeral.className).toContain("motion-reduce:animate-none");
  });
});
