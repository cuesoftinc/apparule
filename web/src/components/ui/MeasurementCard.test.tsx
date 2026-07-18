import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { MeasurementCard } from "./MeasurementCard";

describe("MeasurementCard (§8.2)", () => {
  it("renders name, tabular value, and source chip", () => {
    render(
      <MeasurementCard name="shoulder_width" valueCm={42.5} source="scan" />,
    );
    expect(screen.getByText("Shoulder Width")).toBeInTheDocument();
    expect(screen.getByText("42.5 cm")).toBeInTheDocument();
    // Figma master (48:208): sentence-case source chip
    expect(screen.getByText("Scan")).toBeInTheDocument();
  });

  it.each(["scan", "manual"] as const)("renders source=%s", (source) => {
    const { container } = render(
      <MeasurementCard name="hip_width" valueCm={36.8} source={source} />,
    );
    expect(container.querySelector(`[data-source="${source}"]`)).not.toBeNull();
  });

  it("shows the low-confidence chip under 0.7", () => {
    render(
      <MeasurementCard
        name="hip_width"
        valueCm={36.8}
        source="scan"
        confidence={0.62}
      />,
    );
    expect(screen.getByTestId("low-confidence")).toBeInTheDocument();
  });

  it("hides the chip at normal confidence", () => {
    render(
      <MeasurementCard
        name="hip_width"
        valueCm={36.8}
        source="scan"
        confidence={0.92}
      />,
    );
    expect(screen.queryByTestId("low-confidence")).not.toBeInTheDocument();
  });

  it("renders a sparkline only with history", () => {
    const { rerender } = render(
      <MeasurementCard
        name="shoulder_width"
        valueCm={42.5}
        source="scan"
        history={[41.8, 42.0, 42.5]}
      />,
    );
    expect(screen.getByTestId("sparkline")).toBeInTheDocument();
    rerender(
      <MeasurementCard name="shoulder_width" valueCm={42.5} source="scan" />,
    );
    expect(screen.queryByTestId("sparkline")).not.toBeInTheDocument();
  });

  it("renders inches when the unit toggle flips", () => {
    render(
      <MeasurementCard name="shoulder_width" valueCm={50.8} unit="in" source="manual" />,
    );
    expect(screen.getByText("20.0 in")).toBeInTheDocument();
  });
});
