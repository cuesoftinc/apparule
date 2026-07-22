import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CommentRow } from "./CommentRow";
import { fixtureComment } from "./fixtures";

describe("CommentRow (§8.2b)", () => {
  it("renders avatar, username, body, timestamp, like heart", () => {
    render(<CommentRow comment={fixtureComment} />);
    expect(screen.getByText("kiki.adeyemi")).toBeInTheDocument();
    expect(screen.getByText(/Obsessed with the shoulders/)).toBeInTheDocument();
    expect(screen.getByText("12 likes")).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Like comment" }),
    ).toBeInTheDocument();
  });

  it("liked state fills the heart + flips the label", () => {
    const { container } = render(
      <CommentRow comment={{ ...fixtureComment, liked: true }} />,
    );
    expect(container.querySelector("[data-liked]")).not.toBeNull();
    expect(
      screen.getByRole("button", { name: "Unlike comment" }),
    ).toBeInTheDocument();
  });

  it("posting-optimistic dims + locks the row (MI-18)", () => {
    const { container } = render(
      <CommentRow comment={fixtureComment} posting />,
    );
    expect(container.querySelector("[data-posting]")).not.toBeNull();
    expect(screen.getByRole("button", { name: "Like comment" })).toBeDisabled();
  });

  it("reply-indent shifts the row; Reply fires", async () => {
    const onReply = vi.fn();
    const { container } = render(
      <CommentRow comment={fixtureComment} replyIndent onReply={onReply} />,
    );
    expect(container.firstElementChild!.className).toContain("pl-11");
    await userEvent.click(screen.getByRole("button", { name: "Reply" }));
    expect(onReply).toHaveBeenCalledOnce();
  });

  it("authorHref links avatar + username to the profile (entity-nav rule)", () => {
    render(
      <CommentRow
        comment={fixtureComment}
        authorHref="/dashboard/kiki.adeyemi"
      />,
    );
    expect(screen.getByTestId("comment-author-avatar")).toHaveAttribute(
      "href",
      "/dashboard/kiki.adeyemi",
    );
    expect(screen.getByRole("link", { name: "kiki.adeyemi" })).toHaveAttribute(
      "href",
      "/dashboard/kiki.adeyemi",
    );
  });

  it("without authorHref the row stays inert (gallery renders)", () => {
    render(<CommentRow comment={fixtureComment} />);
    expect(screen.queryByRole("link")).not.toBeInTheDocument();
  });
});
