import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CodeSnippetBlock } from "./CodeSnippetBlock";

describe("CodeSnippetBlock (§8.2b marketing, pages.md A7/A7c)", () => {
  it("renders the compose one-liner by default", () => {
    render(<CodeSnippetBlock />);
    expect(screen.getByText("docker compose up -d")).toBeInTheDocument();
  });

  it("copy button morphs to ✓ and writes the clipboard", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, "clipboard", {
      value: { writeText },
      configurable: true,
    });
    render(<CodeSnippetBlock code="docker compose up" />);
    await userEvent.click(screen.getByRole("button", { name: "Copy command" }));
    expect(writeText).toHaveBeenCalledWith("docker compose up");
    expect(await screen.findByTestId("copied-check")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Copied" })).toBeInTheDocument();
  });
});
