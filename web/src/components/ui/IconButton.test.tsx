import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { Heart } from "lucide-react";
import { IconButton } from "./IconButton";

describe("IconButton (§8.2 as built)", () => {
  it("supports the disabled state", () => {
    render(
      <IconButton aria-label="Like" disabled>
        <Heart size={24} />
      </IconButton>,
    );
    expect(screen.getByRole("button", { name: "Like" })).toBeDisabled();
  });
});
