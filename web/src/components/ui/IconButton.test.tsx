import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { Heart } from "lucide-react";
import { IconButton } from "./IconButton";

describe("IconButton (§8.2 as built)", () => {
  it.each(["md", "sm"] as const)("renders size=%s", (size) => {
    render(
      <IconButton size={size} aria-label="Like">
        <Heart size={24} />
      </IconButton>,
    );
    expect(screen.getByRole("button", { name: "Like" })).toHaveAttribute(
      "data-size",
      size,
    );
  });

  it("supports the disabled state", () => {
    render(
      <IconButton aria-label="Like" disabled>
        <Heart size={24} />
      </IconButton>,
    );
    expect(screen.getByRole("button", { name: "Like" })).toBeDisabled();
  });
});
