import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { ProcessingConstellation } from "./ProcessingConstellation";

describe("ProcessingConstellation (§8.2b)", () => {
  it.each(["processing", "success", "failed"] as const)(
    "renders state=%s",
    (state) => {
      const { container } = render(<ProcessingConstellation state={state} />);
      expect(container.firstElementChild).toHaveAttribute("data-state", state);
    },
  );

  it("draws the landmark constellation over the photo", () => {
    render(
      <ProcessingConstellation state="processing" imageSrc="/demo/outfit-w00.jpg" />,
    );
    expect(screen.getByRole("img")).toHaveAttribute("src", "/demo/outfit-w00.jpg");
    expect(screen.getAllByTestId("landmark").length).toBeGreaterThanOrEqual(13);
  });

  it("processing: landmarks pulse staggered, reduced-motion safe", () => {
    render(<ProcessingConstellation state="processing" />);
    const dots = screen.getAllByTestId("landmark");
    expect(dots[0].getAttribute("class")).toContain("landmark-pulse");
    expect(dots[0].getAttribute("class")).toContain("motion-reduce:animate-none");
    expect(dots[1].getAttribute("style")).toContain("animation-delay");
  });

  // Figma master (64:748): status caption below the photo.
  it("success / failed announce their status", () => {
    const { rerender } = render(<ProcessingConstellation state="success" />);
    expect(screen.getByRole("status")).toHaveTextContent("Done");
    rerender(<ProcessingConstellation state="failed" />);
    expect(screen.getByRole("status")).toHaveTextContent(
      "Couldn't measure — retake",
    );
  });
});
