import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { CodeSnippetTabs } from "./CodeSnippetTabs";

const TABS = [
  {
    label: "Docker Compose",
    code: "git clone https://github.com/cuesoftinc/apparule\ncd apparule && docker compose up --build -d",
  },
  {
    label: "Helm",
    code: "git clone https://github.com/cuesoftinc/apparule\ncd apparule && helm install apparule deploy/helm",
  },
];

function mockClipboard() {
  const writeText = vi.fn().mockResolvedValue(undefined);
  Object.defineProperty(navigator, "clipboard", {
    value: { writeText },
    configurable: true,
  });
  return writeText;
}

describe("CodeSnippetTabs (§8.2b marketing, pages.md A7c tabbed — Figma 415:2)", () => {
  it("renders the tablist with Docker Compose active and mirrored two-line commands", () => {
    render(<CodeSnippetTabs tabs={TABS} />);
    expect(
      screen.getByRole("tablist", { name: "Install method" }),
    ).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: "Docker Compose" })).toHaveAttribute(
      "aria-selected",
      "true",
    );
    expect(
      screen.getByText(/git clone https:\/\/github\.com\/cuesoftinc\/apparule/),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/cd apparule && docker compose up --build -d/),
    ).toBeInTheDocument();
    expect(screen.queryByText(/helm install apparule/)).not.toBeInTheDocument();
  });

  it("switches tabs and copies the ACTIVE tab's full block (prompts stay out)", async () => {
    const writeText = mockClipboard();
    render(<CodeSnippetTabs tabs={TABS} />);
    await userEvent.click(screen.getByRole("tab", { name: "Helm" }));
    expect(
      screen.getByText(/cd apparule && helm install apparule deploy\/helm/),
    ).toBeInTheDocument();
    await userEvent.click(
      screen.getByRole("button", { name: "Copy commands" }),
    );
    expect(writeText).toHaveBeenCalledWith(TABS[1].code);
    expect(await screen.findByTestId("copied-check")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Copied" })).toBeInTheDocument();
  });

  it("copies the docker block while Docker Compose is active", async () => {
    const writeText = mockClipboard();
    render(<CodeSnippetTabs tabs={TABS} />);
    await userEvent.click(
      screen.getByRole("button", { name: "Copy commands" }),
    );
    expect(writeText).toHaveBeenCalledWith(TABS[0].code);
  });

  it("roves focus with arrow keys (tablist semantics)", async () => {
    render(<CodeSnippetTabs tabs={TABS} />);
    const docker = screen.getByRole("tab", { name: "Docker Compose" });
    const helm = screen.getByRole("tab", { name: "Helm" });
    expect(docker).toHaveAttribute("tabindex", "0");
    expect(helm).toHaveAttribute("tabindex", "-1");
    docker.focus();
    await userEvent.keyboard("{ArrowRight}");
    expect(helm).toHaveFocus();
    expect(helm).toHaveAttribute("aria-selected", "true");
    await userEvent.keyboard("{ArrowLeft}");
    expect(docker).toHaveFocus();
    expect(docker).toHaveAttribute("aria-selected", "true");
  });

  it("resets the copied morph when the tab switches", async () => {
    mockClipboard();
    render(<CodeSnippetTabs tabs={TABS} />);
    await userEvent.click(
      screen.getByRole("button", { name: "Copy commands" }),
    );
    expect(screen.getByTestId("copied-check")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("tab", { name: "Helm" }));
    expect(screen.queryByTestId("copied-check")).not.toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Copy commands" }),
    ).toBeInTheDocument();
  });
});
