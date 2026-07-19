import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { NotificationRow } from "./NotificationRow";
import { fixtureNotification } from "./fixtures";

describe("NotificationRow (§8.2b)", () => {
  it("unread rows carry the dot + emphasis", () => {
    render(<NotificationRow notification={fixtureNotification} />);
    expect(screen.getByTestId("unread-dot")).toBeInTheDocument();
  });

  it("read rows drop the dot", () => {
    render(
      <NotificationRow
        notification={{
          ...fixtureNotification,
          read_at: new Date().toISOString(),
        }}
      />,
    );
    expect(screen.queryByTestId("unread-dot")).not.toBeInTheDocument();
  });

  it.each([
    "like",
    "follow",
    "comment",
    "quote",
    "status_change",
    "payout",
  ] as const)("renders kind=%s", (kind) => {
    const { container } = render(
      <NotificationRow notification={{ ...fixtureNotification, kind }} />,
    );
    expect(container.querySelector(`[data-kind="${kind}"]`)).not.toBeNull();
  });

  it("trailing: post thumb for content rows, Follow for follow rows", async () => {
    const onFollowBack = vi.fn();
    const { rerender } = render(
      <NotificationRow notification={fixtureNotification} />,
    );
    expect(document.querySelector("img")).not.toBeNull();
    rerender(
      <NotificationRow
        notification={{
          ...fixtureNotification,
          kind: "follow",
          thumb_url: null,
        }}
        onFollowBack={onFollowBack}
      />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Follow" }));
    expect(onFollowBack).toHaveBeenCalledOnce();
  });
});
