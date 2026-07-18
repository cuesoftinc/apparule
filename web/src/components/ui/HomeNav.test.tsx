import { describe, expect, it } from "vitest";
import { act, fireEvent, render, screen } from "@testing-library/react";
import { HomeNav } from "./HomeNav";

describe("HomeNav (§8.2b marketing)", () => {
  it("renders logo, links, star badge, Sign in, Try Cloud", () => {
    render(<HomeNav />);
    expect(screen.getByText("Apparule")).toBeInTheDocument();
    expect(screen.getByTestId("star-badge")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Sign in" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Try Cloud" })).toBeInTheDocument();
  });

  it("star badge is neutral (no invented number) until the live count arrives", () => {
    const { rerender } = render(<HomeNav starCount={null} />);
    expect(screen.getByTestId("star-badge")).toHaveTextContent("Star");
    rerender(<HomeNav starCount={1234} />);
    expect(screen.getByTestId("star-badge")).toHaveTextContent("1,234");
  });

  it("blurs when stuck (scroll state)", () => {
    render(<HomeNav />);
    const nav = screen.getByRole("navigation", { name: "Home" });
    expect(nav).toHaveAttribute("data-state", "top");
    act(() => {
      window.scrollY = 100;
      fireEvent.scroll(window);
    });
    expect(nav).toHaveAttribute("data-state", "stuck-blurred");
  });
});
