import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { CommunityCard } from "./CommunityCard";

describe("CommunityCard (§8.2b marketing — compact master 144:3724)", () => {
  it("renders the neutral member line with no invented count", () => {
    render(<CommunityCard />);
    expect(screen.getByTestId("member-badge")).toHaveTextContent(
      "Fit checks & dev chat, daily",
    );
    expect(screen.getByTestId("member-badge")).not.toHaveTextContent("members");
  });

  it("renders the live member count when provided at runtime", () => {
    render(<CommunityCard memberCount={412} />);
    expect(screen.getByTestId("member-badge")).toHaveTextContent("412 members");
  });

  it("carries the Join CTA", () => {
    render(<CommunityCard />);
    expect(
      screen.getByRole("button", { name: "Join Discord" }),
    ).toBeInTheDocument();
  });
});
