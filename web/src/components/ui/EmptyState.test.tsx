import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { EmptyState, type EmptyStateContext } from "./EmptyState";

const CONTEXTS: EmptyStateContext[] = [
  "feed",
  "vault",
  "orders",
  "explore",
  "notifications",
];

describe("EmptyState (§8.2 — 5 contexts)", () => {
  it.each(CONTEXTS)("renders context=%s with line + one CTA", (context) => {
    const { container } = render(<EmptyState context={context} />);
    expect(
      container.querySelector(`[data-context="${context}"]`),
    ).not.toBeNull();
    expect(screen.getAllByRole("button")).toHaveLength(1);
  });

  it("feed context carries the B1 empty copy", () => {
    render(<EmptyState context="feed" />);
    expect(
      screen.getByText("Follow designers to fill your feed"),
    ).toBeInTheDocument();
  });

  it("CTA fires + copy overrides apply", async () => {
    const onCta = vi.fn();
    render(
      <EmptyState
        context="vault"
        line="Custom line"
        ctaLabel="Go"
        onCta={onCta}
      />,
    );
    expect(screen.getByText("Custom line")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Go" }));
    expect(onCta).toHaveBeenCalledOnce();
  });
});
