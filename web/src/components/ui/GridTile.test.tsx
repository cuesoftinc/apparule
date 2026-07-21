import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { GridTile } from "./GridTile";

describe("GridTile (§8.2b)", () => {
  it("renders the 1:1 tile with hover-stats overlay", () => {
    render(
      <GridTile
        src="/demo/outfit-w19.jpg"
        alt="Outfit"
        likeCount={519}
        commentCount={6}
      />,
    );
    const stats = screen.getByTestId("hover-stats");
    expect(stats).toHaveTextContent("519");
    expect(stats).toHaveTextContent("6");
  });

  it("corner badge renders only for carousels", () => {
    const { rerender } = render(
      <GridTile src="/demo/outfit-w19.jpg" carousel />,
    );
    expect(screen.getByTestId("carousel-badge")).toBeInTheDocument();
    rerender(<GridTile src="/demo/outfit-w19.jpg" />);
    expect(screen.queryByTestId("carousel-badge")).not.toBeInTheDocument();
  });

  it("skeleton state renders the media placeholder", () => {
    const { container } = render(<GridTile skeleton />);
    expect(container.querySelector('[data-kind="media"]')).not.toBeNull();
  });
});
