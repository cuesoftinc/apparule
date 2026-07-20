import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ModerationQueueRow } from "./ModerationQueueRow";
import { fixtureReport } from "./fixtures";

describe("ModerationQueueRow (§8.2b, A-6)", () => {
  it("open state renders preview, reporter context, reason, three actions", () => {
    render(<ModerationQueueRow report={fixtureReport} />);
    // Figma master (93:1219): "Reported comment" headline + excerpt meta
    expect(screen.getByText("Reported comment")).toBeInTheDocument();
    expect(screen.getByText(/Buy followers cheap/)).toBeInTheDocument();
    expect(screen.getByText(/Reported by @/)).toBeInTheDocument();
    expect(screen.getByText(/tunde.o/)).toBeInTheDocument();
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

  it("headline carries the content author when known (B7a canvas)", () => {
    render(
      <ModerationQueueRow
        report={{
          ...fixtureReport,
          subject_kind: "post",
          subject_preview: {
            text: "New fabric drop",
            thumb_url: "/demo/outfit-w14.jpg",
            author_username: "amara.designs",
          },
        }}
      />,
    );
    expect(
      screen.getByText("Reported post by @amara.designs"),
    ).toBeInTheDocument();
  });

  it("actioned state swaps actions for the audit line (effective action + @moderator + time)", () => {
    render(
      <ModerationQueueRow
        report={{
          ...fixtureReport,
          status: "actioned",
          action: "hide_post", // comment subject → reads hide_comment
          actioned_by: { id: "acc-staff", username: "staff.ops" },
          actioned_at: "2026-07-15T09:12:00",
        }}
      />,
    );
    expect(screen.getByTestId("audit-line")).toHaveTextContent(
      "Actioned · hide_comment by @staff.ops · Jul 15, 09:12",
    );
    expect(
      screen.queryByRole("button", { name: "Hide post" }),
    ).not.toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: "Hide comment" }),
    ).not.toBeInTheDocument();
  });
});
