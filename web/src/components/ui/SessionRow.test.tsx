import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SessionRow } from "./SessionRow";
import { daysAgo, fixtureSession } from "./fixtures";

describe("SessionRow (§8.2b)", () => {
  it("history context: date + method chip + values + delete", async () => {
    const onDelete = vi.fn();
    const { container } = render(
      <SessionRow session={fixtureSession} onDelete={onDelete} />,
    );
    expect(container.querySelector('[data-context="history"]')).not.toBeNull();
    expect(screen.getByText("scan")).toBeInTheDocument();
    expect(screen.getByText(/Shoulder Width 42.5 cm/)).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Delete session" }));
    expect(onDelete).toHaveBeenCalledOnce();
  });

  it("picker context: radio + freshness pill, selected state", () => {
    render(
      <SessionRow session={fixtureSession} context="picker" selected />,
    );
    const radio = screen.getByRole("radio");
    expect(radio).toHaveAttribute("aria-checked", "true");
    expect(screen.getByTestId("picker-radio")).toBeInTheDocument();
    expect(screen.getByText("fresh")).toBeInTheDocument();
    expect(screen.queryByTestId("freshness-warning")).not.toBeInTheDocument();
  });

  it("picker warns on aging/stale sessions", () => {
    render(
      <SessionRow
        session={{ ...fixtureSession, created_at: daysAgo(58) }}
        context="picker"
      />,
    );
    expect(screen.getByTestId("freshness-warning")).toHaveTextContent(/retak/i);
  });

  it("picker select fires onSelect", async () => {
    const onSelect = vi.fn();
    render(
      <SessionRow session={fixtureSession} context="picker" onSelect={onSelect} />,
    );
    await userEvent.click(screen.getByRole("radio"));
    expect(onSelect).toHaveBeenCalledOnce();
  });
});
