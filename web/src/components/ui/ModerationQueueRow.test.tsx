import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ModerationQueueRow } from "./ModerationQueueRow";
import { fixtureReport } from "./fixtures";

describe("ModerationQueueRow (§8.2b, A-6)", () => {
  it("open state renders preview, reporter context, reason, three actions", () => {
    render(<ModerationQueueRow report={fixtureReport} />);
    expect(screen.getByText(/Buy followers cheap/)).toBeInTheDocument();
    expect(screen.getByText(/reported by tunde.o/)).toBeInTheDocument();
    expect(screen.getByText("spam")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Hide post" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Suspend account" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Dismiss" })).toBeInTheDocument();
  });

  it("actions map to the api enum", async () => {
    const onAction = vi.fn();
    render(<ModerationQueueRow report={fixtureReport} onAction={onAction} />);
    await userEvent.click(screen.getByRole("button", { name: "Hide post" }));
    expect(onAction).toHaveBeenCalledWith("hide_post");
    await userEvent.click(screen.getByRole("button", { name: "Suspend account" }));
    expect(onAction).toHaveBeenCalledWith("suspend_account");
  });

  it("actioned state swaps actions for the audit line", () => {
    render(
      <ModerationQueueRow
        report={{ ...fixtureReport, status: "actioned", actioned_by: "staff.ops" }}
      />,
    );
    expect(screen.getByTestId("audit-line")).toHaveTextContent("staff.ops");
    expect(screen.queryByRole("button", { name: "Hide post" })).not.toBeInTheDocument();
  });
});
