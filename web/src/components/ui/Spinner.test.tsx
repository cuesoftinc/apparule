import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { Spinner } from "./Spinner";

describe("Spinner (§8.2b)", () => {
  it.each([20, 28] as const)("renders size=%s", (size) => {
    render(<Spinner size={size} />);
    expect(screen.getByRole("status")).toHaveAttribute("width", String(size));
  });

  it("gradient kind strokes the accent gradient (MI-5)", () => {
    const { container } = render(<Spinner kind="gradient" />);
    expect(container.querySelector("linearGradient")).not.toBeNull();
  });

  it("neutral kind uses the text-2 token", () => {
    const { container } = render(<Spinner kind="neutral" />);
    expect(container.querySelector("circle")).toHaveAttribute(
      "stroke",
      "var(--ap-text-2)",
    );
  });

  it("pull progress scales the spinner instead of spinning", () => {
    render(<Spinner kind="gradient" progress={0.5} />);
    const svg = screen.getByRole("status") as unknown as SVGSVGElement;
    expect(svg.style.transform).toBe("scale(0.5)");
    expect(svg.getAttribute("class") ?? "").not.toContain("animate-spin");
  });
});
