import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { StoryRailItem } from "./StoryRailItem";

describe("StoryRailItem (§8.2, MI-8)", () => {
  it.each(["unseen", "seen", "loading"] as const)(
    "renders state=%s",
    (state) => {
      render(<StoryRailItem username="amara.designs" state={state} />);
      expect(screen.getByRole("button")).toHaveAttribute("data-state", state);
    },
  );

  it("unseen carries the gradient ring, seen the gray ring", () => {
    const { container, rerender } = render(
      <StoryRailItem username="amara.designs" state="unseen" />,
    );
    expect(container.querySelector('[data-ring="gradient"]')).not.toBeNull();
    rerender(<StoryRailItem username="amara.designs" state="seen" />);
    expect(container.querySelector('[data-ring="gray"]')).not.toBeNull();
  });

  it("shows the username", () => {
    render(<StoryRailItem username="maisonbisi" />);
    expect(screen.getByText("maisonbisi")).toBeInTheDocument();
  });
});
