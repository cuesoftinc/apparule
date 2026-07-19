import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { FAQGroup, FAQItem } from "./FAQItem";

function renderGroup() {
  return render(
    <FAQGroup defaultOpenId="faq-1">
      <FAQItem id="faq-1" question="How accurate are the measurements?">
        ±2 cm target.
      </FAQItem>
      <FAQItem id="faq-2" question="Who can see my measurements?">
        No one.
      </FAQItem>
    </FAQGroup>,
  );
}

describe("FAQItem (§8.2b as built)", () => {
  it("renders collapsed/expanded states with aria-expanded", () => {
    renderGroup();
    expect(
      screen.getByRole("button", {
        name: "How accurate are the measurements?",
      }),
    ).toHaveAttribute("aria-expanded", "true");
    expect(
      screen.getByRole("button", { name: "Who can see my measurements?" }),
    ).toHaveAttribute("aria-expanded", "false");
  });

  it("one-open-at-a-time: opening the second closes the first", async () => {
    renderGroup();
    await userEvent.click(
      screen.getByRole("button", { name: "Who can see my measurements?" }),
    );
    expect(screen.getByText("No one.")).toBeInTheDocument();
    expect(screen.queryByText("±2 cm target.")).not.toBeInTheDocument();
  });

  it("rows are deep-linkable via DOM ids (#faq-n)", () => {
    renderGroup();
    expect(document.getElementById("faq-1")).not.toBeNull();
    expect(document.getElementById("faq-2")).not.toBeNull();
  });

  it("toggling the open row collapses it", async () => {
    renderGroup();
    const first = screen.getByRole("button", {
      name: "How accurate are the measurements?",
    });
    await userEvent.click(first);
    expect(first).toHaveAttribute("aria-expanded", "false");
    expect(screen.queryByText("±2 cm target.")).not.toBeInTheDocument();
  });
});
