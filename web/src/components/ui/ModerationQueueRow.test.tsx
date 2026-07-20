import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ModerationQueueRow } from "./ModerationQueueRow";
import { fixtureReport } from "./fixtures";

describe("ModerationQueueRow (§8.2b, A-6)", () => {
  it("open state renders authored title, preview, @reporter, reason, three actions", () => {
    render(<ModerationQueueRow report={fixtureReport} />);
    // B7a frame (audit #19): authored headline + excerpt + "@reporter" meta
    expect(
      screen.getByText("Reported comment by @fitfluence.ng"),
    ).toBeInTheDocument();
    expect(screen.getByText(/Buy followers cheap/)).toBeInTheDocument();
    expect(screen.getByText(/Reported by @tunde.o/)).toBeInTheDocument();
    expect(screen.getByText("spam")).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Hide comment" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Suspend account" }),
    ).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Dismiss" })).toBeInTheDocument();
  });

  it("actions map to the api enum", async () => {
    const onAction = vi.fn();
    render(<ModerationQueueRow report={fixtureReport} onAction={onAction} />);
    await userEvent.click(screen.getByRole("button", { name: "Hide comment" }));
    expect(onAction).toHaveBeenCalledWith("hide_post");
    await userEvent.click(
      screen.getByRole("button", { name: "Suspend account" }),
    );
    expect(onAction).toHaveBeenCalledWith("suspend_account");
  });

  it("actioned state swaps actions for the audit line (action · @mod · when)", () => {
    render(
      <ModerationQueueRow
        report={{
          ...fixtureReport,
          status: "actioned",
          action: "hide_post",
          actioned_by: "staff.ops",
          actioned_at: "2026-07-15T09:12:00",
        }}
      />,
    );
    // hide on a comment subject records as "hide_comment" (B7a frame)
    expect(screen.getByTestId("audit-line")).toHaveTextContent(
      "Actioned · hide_comment by @staff.ops · Jul 15, 09:12",
    );
    expect(
      screen.queryByRole("button", { name: "Hide post" }),
    ).not.toBeInTheDocument();
  });
});
