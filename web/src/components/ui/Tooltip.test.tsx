import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { Tooltip } from "./Tooltip";

describe("Tooltip (§8.2b)", () => {
  it("renders the single-line label when open", async () => {
    render(
      <Tooltip label="Measured 12 days ago — retake?" defaultOpen>
        <button>ring</button>
      </Tooltip>,
    );
    expect(
      (await screen.findAllByText("Measured 12 days ago — retake?")).length,
    ).toBeGreaterThan(0);
  });

  it("stays hidden until triggered", () => {
    render(
      <Tooltip label="Hidden tip">
        <button>ring</button>
      </Tooltip>,
    );
    expect(screen.queryByText("Hidden tip")).not.toBeInTheDocument();
  });
});
