import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { PostCard } from "./PostCard";
import { fixturePost } from "./fixtures";

describe("PostCard (§3 anatomy + §8.2)", () => {
  it("renders the full anatomy: header, media, actions, count, caption, CTA, timestamp", () => {
    render(<PostCard post={fixturePost} onRequest={() => {}} />);
    expect(screen.getAllByText("amara.designs").length).toBeGreaterThan(0);
    expect(screen.getByTestId("post-media")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Like" })).toBeInTheDocument();
    // visible count + the aria-live announcement both render the count
    expect(screen.getAllByText("214 likes").length).toBeGreaterThan(0);
    expect(
      screen.getByRole("button", { name: "Request this outfit" }),
    ).toBeInTheDocument();
  });

  it("CTA axis: without onRequest there is no request button", () => {
    render(<PostCard post={fixturePost} />);
    expect(
      screen.queryByRole("button", { name: "Request this outfit" }),
    ).not.toBeInTheDocument();
  });

  it("media axis: carousel dots for multi-image posts only", () => {
    const { rerender } = render(<PostCard post={fixturePost} />);
    expect(screen.getByTestId("carousel-dots")).toBeInTheDocument();
    rerender(
      <PostCard
        post={{ ...fixturePost, media: fixturePost.media.slice(0, 1) }}
      />,
    );
    expect(screen.queryByTestId("carousel-dots")).not.toBeInTheDocument();
  });

  it("carousel advances via the chevrons (MI-4)", async () => {
    render(<PostCard post={fixturePost} />);
    expect(
      screen.queryByRole("button", { name: "Previous image" }),
    ).not.toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Next image" }));
    expect(
      screen.getByRole("button", { name: "Previous image" }),
    ).toBeInTheDocument();
  });

  it("skeleton state renders the placeholder card (MI-19)", () => {
    const { container } = render(<PostCard skeleton />);
    expect(container.querySelector('[data-kind="card"]')).not.toBeNull();
    expect(screen.queryByTestId("post-card")).not.toBeInTheDocument();
  });

  it("double-tap on media likes once + bursts the 96px heart (MI-1)", () => {
    const onToggleLike = vi.fn();
    render(<PostCard post={fixturePost} onToggleLike={onToggleLike} />);
    const media = screen.getByTestId("post-media");
    fireEvent.click(media);
    fireEvent.click(media);
    expect(onToggleLike).toHaveBeenCalledOnce();
    expect(screen.getByTestId("big-heart")).toBeInTheDocument();
  });

  it("double-tap never unlikes (MI-1 optimistic like only)", () => {
    const onToggleLike = vi.fn();
    render(
      <PostCard
        post={{ ...fixturePost, liked: true }}
        onToggleLike={onToggleLike}
      />,
    );
    const media = screen.getByTestId("post-media");
    fireEvent.click(media);
    fireEvent.click(media);
    expect(onToggleLike).not.toHaveBeenCalled();
  });

  it("authorHref links the header (avatar + username) and caption username (entity-nav rule)", () => {
    render(
      <PostCard post={fixturePost} authorHref="/dashboard/amara.designs" />,
    );
    const header = screen.getByTestId("post-author-link");
    expect(header).toHaveAttribute("href", "/dashboard/amara.designs");
    expect(header).toHaveTextContent("amara.designs");
    // header link + caption link — both real anchors
    const links = screen
      .getAllByRole("link")
      .filter((a) => a.getAttribute("href") === "/dashboard/amara.designs");
    expect(links.length).toBe(2);
  });

  it("without authorHref the card stays inert (marketing mocks, gallery)", () => {
    render(<PostCard post={fixturePost} />);
    expect(screen.queryByRole("link")).not.toBeInTheDocument();
    expect(screen.queryByTestId("post-author-link")).not.toBeInTheDocument();
  });
});
