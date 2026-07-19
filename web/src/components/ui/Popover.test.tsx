import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Flag } from "lucide-react";
import { MenuItem, Popover } from "./Popover";

describe("Popover / MenuItem (§8.2b)", () => {
  it("renders items when open", () => {
    render(
      <Popover defaultOpen trigger={<button>⋯</button>}>
        <MenuItem label="Copy link" />
        <MenuItem label="Report post" destructive icon={Flag} />
      </Popover>,
    );
    expect(
      screen.getByRole("menuitem", { name: "Copy link" }),
    ).toBeInTheDocument();
  });

  it("destructive items carry the error tone", () => {
    render(
      <Popover defaultOpen trigger={<button>⋯</button>}>
        <MenuItem label="Report post" destructive />
      </Popover>,
    );
    expect(
      screen.getByRole("menuitem", { name: "Report post" }),
    ).toHaveAttribute("data-destructive", "true");
  });

  it("item selection fires onSelect", async () => {
    const onSelect = vi.fn();
    render(
      <Popover defaultOpen trigger={<button>⋯</button>}>
        <MenuItem label="Copy link" onSelect={onSelect} />
      </Popover>,
    );
    await userEvent.click(screen.getByRole("menuitem", { name: "Copy link" }));
    expect(onSelect).toHaveBeenCalledOnce();
  });
});
