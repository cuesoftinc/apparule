import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import { ManualMeasureRow, humanizeMeasureName } from "./ManualMeasureRow";

describe("ManualMeasureRow (§8.2, MI-13)", () => {
  it.each([
    ["default", {}],
    ["active", { active: true }],
    ["error", { error: "Out of range" }],
  ] as const)("renders state=%s", (state, props) => {
    const { container } = render(
      <ManualMeasureRow
        name="shoulder_width"
        valueCm={42.5}
        onChange={() => {}}
        unit="cm"
        onUnitChange={() => {}}
        {...props}
      />,
    );
    expect(container.querySelector(`[data-state="${state}"]`)).not.toBeNull();
  });

  it("humanizes measurement names", () => {
    expect(humanizeMeasureName("shoulder_width")).toBe("Shoulder Width");
  });

  it("slider drives the cm value", () => {
    const onChange = vi.fn();
    render(
      <ManualMeasureRow
        name="shoulder_width"
        valueCm={42.5}
        onChange={onChange}
        unit="cm"
        onUnitChange={() => {}}
        min={30}
        max={60}
      />,
    );
    fireEvent.change(screen.getByRole("slider"), { target: { value: "45" } });
    expect(onChange).toHaveBeenCalledWith(45);
  });

  it("numeric field converts inches back to cm", () => {
    const onChange = vi.fn();
    render(
      <ManualMeasureRow
        name="shoulder_width"
        valueCm={42.5}
        onChange={onChange}
        unit="in"
        onUnitChange={() => {}}
      />,
    );
    fireEvent.change(screen.getByLabelText("Shoulder Width value"), {
      target: { value: "10" },
    });
    expect(onChange).toHaveBeenCalledWith(25.4);
  });
});
