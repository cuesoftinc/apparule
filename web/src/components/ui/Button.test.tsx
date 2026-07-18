import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Button } from "./Button";

describe("Button (§8.2)", () => {
  it.each(["gradient-primary", "quiet", "destructive", "link"] as const)(
    "renders kind=%s",
    (kind) => {
      render(<Button kind={kind}>Go</Button>);
      expect(screen.getByRole("button")).toHaveAttribute("data-kind", kind);
    },
  );

  it("renders both sizes (md 44 / sm 36)", () => {
    const { rerender } = render(<Button size="md">A</Button>);
    expect(screen.getByRole("button")).toHaveAttribute("data-size", "md");
    rerender(<Button size="sm">A</Button>);
    expect(screen.getByRole("button")).toHaveAttribute("data-size", "sm");
  });

  it("loading state disables the button and shows a spinner", () => {
    render(<Button loading>Pay</Button>);
    const button = screen.getByRole("button");
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute("aria-busy", "true");
    expect(screen.getByLabelText("Loading")).toBeInTheDocument();
  });

  it("disabled state blocks clicks", async () => {
    const onClick = vi.fn();
    render(
      <Button disabled onClick={onClick}>
        Nope
      </Button>,
    );
    await userEvent.click(screen.getByRole("button"));
    expect(onClick).not.toHaveBeenCalled();
  });
});
