import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ActionRow } from "./ActionRow";

describe("ActionRow (§8.2 as built, MI-1/2/3)", () => {
  it("renders liked/saved axes via data attributes", () => {
    const { container } = render(
      <ActionRow
        liked
        saved={false}
        likeCount={214}
        onToggleLike={() => {}}
        onToggleSave={() => {}}
      />,
    );
    const row = container.firstElementChild!;
    expect(row).toHaveAttribute("data-liked", "true");
    expect(row).toHaveAttribute("data-saved", "false");
  });

  it("like toggles + announces via aria-live (design.md §5)", async () => {
    const onToggleLike = vi.fn();
    render(
      <ActionRow
        liked={false}
        saved={false}
        likeCount={214}
        onToggleLike={onToggleLike}
        onToggleSave={() => {}}
      />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Like" }));
    expect(onToggleLike).toHaveBeenCalledOnce();
    expect(screen.getByText("214 likes")).toBeInTheDocument();
  });

  it("save toggles via the bookmark", async () => {
    const onToggleSave = vi.fn();
    render(
      <ActionRow
        liked={false}
        saved={false}
        likeCount={0}
        onToggleLike={() => {}}
        onToggleSave={onToggleSave}
      />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(onToggleSave).toHaveBeenCalledOnce();
  });

  it("comment + share slots fire", async () => {
    const onComment = vi.fn();
    const onShare = vi.fn();
    render(
      <ActionRow
        liked={false}
        saved={false}
        likeCount={0}
        onToggleLike={() => {}}
        onToggleSave={() => {}}
        onComment={onComment}
        onShare={onShare}
      />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Comments" }));
    await userEvent.click(screen.getByRole("button", { name: "Share" }));
    expect(onComment).toHaveBeenCalledOnce();
    expect(onShare).toHaveBeenCalledOnce();
  });
});
