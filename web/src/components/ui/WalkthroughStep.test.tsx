import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { WalkthroughStep } from "./WalkthroughStep";

describe("WalkthroughStep (§8.2b marketing — dots ×4 as built)", () => {
  it("renders screenshot + two lines", () => {
    render(
      <WalkthroughStep
        imageSrc="/demo/outfit-w10.jpg"
        imageAlt="Capture step"
        title="Capture"
        body="Two photos and your height — the AI does the rest."
        step={0}
      />,
    );
    expect(screen.getByAltText("Capture step")).toBeInTheDocument();
    expect(screen.getByText("Capture")).toBeInTheDocument();
    expect(screen.getByText(/Two photos/)).toBeInTheDocument();
  });

  it("renders exactly four step dots with the active one set per instance", () => {
    render(
      <WalkthroughStep
        imageSrc="/demo/outfit-w10.jpg"
        imageAlt=""
        title="Vault"
        body="…"
        step={2}
      />,
    );
    const dots = screen.getByTestId("step-dots");
    expect(dots.children).toHaveLength(4);
    expect(dots.querySelectorAll("[data-active]")).toHaveLength(1);
    expect(dots.children[2]).toHaveAttribute("data-active");
  });
});
