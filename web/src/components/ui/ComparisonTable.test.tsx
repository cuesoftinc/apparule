import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ComparisonTable } from "./ComparisonTable";

describe("ComparisonTable (§8.2b marketing, pages.md A9)", () => {
  it("renders Cloud and Self-host columns", () => {
    render(<ComparisonTable />);
    expect(
      screen.getByRole("columnheader", { name: "Cloud" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("columnheader", { name: "Self-host" }),
    ).toBeInTheDocument();
  });

  it("CTA row: Cloud → Start on Cloud, OSS → Self-host it (Stage 5 master)", async () => {
    const onTryCloud = vi.fn();
    const onSelfHost = vi.fn();
    render(<ComparisonTable onTryCloud={onTryCloud} onSelfHost={onSelfHost} />);
    const ctaRow = screen.getByTestId("cta-row");
    expect(ctaRow).toBeInTheDocument();
    await userEvent.click(
      screen.getByRole("button", { name: "Start on Cloud" }),
    );
    await userEvent.click(screen.getByRole("button", { name: "Self-host it" }));
    expect(onTryCloud).toHaveBeenCalledOnce();
    expect(onSelfHost).toHaveBeenCalledOnce();
  });

  it("boolean cells render accessible included/not-included marks", () => {
    render(<ComparisonTable />);
    expect(screen.getAllByLabelText("Included").length).toBeGreaterThan(0);
    expect(screen.getAllByLabelText("Not included").length).toBeGreaterThan(0);
  });
});
