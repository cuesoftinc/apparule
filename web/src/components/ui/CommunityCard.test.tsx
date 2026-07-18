import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { CommunityCard } from "./CommunityCard";

describe("CommunityCard (§8.2b marketing)", () => {
  it("renders the neutral badge with no invented member count", () => {
    render(<CommunityCard />);
    expect(screen.getByTestId("member-badge")).toHaveTextContent("Discord");
    expect(screen.getByTestId("member-badge")).not.toHaveTextContent("members");
  });

  it("renders the live member count when provided at runtime", () => {
    render(<CommunityCard memberCount={412} />);
    expect(screen.getByTestId("member-badge")).toHaveTextContent("412 members");
  });

  it("carries the join CTA", () => {
    render(<CommunityCard />);
    expect(screen.getByRole("button", { name: "Join Discord" })).toBeInTheDocument();
  });
});
