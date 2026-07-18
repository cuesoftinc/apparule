import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { CaughtUpDivider } from "./CaughtUpDivider";

describe("CaughtUpDivider (§8.2b, MI-6)", () => {
  it("renders the caught-up line with check glyph + hairline pair", () => {
    const { container } = render(<CaughtUpDivider />);
    expect(screen.getByText(/all caught up/i)).toBeInTheDocument();
    expect(container.querySelectorAll(".bg-border")).toHaveLength(2);
    expect(container.querySelector("svg")).not.toBeNull();
  });
});
