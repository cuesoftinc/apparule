import { describe, expect, it } from "vitest";
import { render } from "@testing-library/react";
import { Skeleton } from "./Skeleton";

describe("Skeleton (§8.2 as built, MI-19)", () => {
  it.each(["line", "avatar", "media", "card"] as const)(
    "renders kind=%s",
    (kind) => {
      const { container } = render(<Skeleton kind={kind} />);
      expect(container.querySelector(`[data-kind="${kind}"]`)).not.toBeNull();
    },
  );

  it("card kind renders the §3 feed anatomy (header + media + action row)", () => {
    const { container } = render(<Skeleton kind="card" />);
    const card = container.querySelector('[data-kind="card"]');
    expect(card).not.toBeNull();
    // header avatar + media + 3 action placeholders
    expect(card!.querySelectorAll("div").length).toBeGreaterThanOrEqual(5);
  });

  it("is aria-hidden (placeholder only)", () => {
    const { container } = render(<Skeleton kind="line" />);
    expect(container.firstElementChild).toHaveAttribute("aria-hidden", "true");
  });
});
