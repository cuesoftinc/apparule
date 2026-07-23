import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { StatCard } from "./StatCard";

describe("StatCard (§8.2b marketing, pages.md A3)", () => {
  it("renders the product-claim stat + label", () => {
    render(<StatCard stat="±0.8 in" label="target measurement accuracy" />);
    expect(screen.getByText("±0.8 in")).toBeInTheDocument();
    expect(screen.getByText("target measurement accuracy")).toBeInTheDocument();
  });

  it("fades up once in view (jsdom has no IO → immediately visible)", () => {
    const { container } = render(
      <StatCard stat="2" label="photos per capture" />,
    );
    expect(container.querySelector('[data-visible="true"]')).not.toBeNull();
  });
});
