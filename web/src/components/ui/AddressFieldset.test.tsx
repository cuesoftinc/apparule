import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AddressFieldset, NG_STATES } from "./AddressFieldset";

describe("AddressFieldset (§8.2)", () => {
  it("delivery context renders the full frozen-per-order address form", () => {
    render(
      <AddressFieldset context="delivery" value={{}} onChange={() => {}} />,
    );
    for (const label of [
      "Recipient name",
      "Phone",
      "Address line 1",
      "City",
      "State",
      "Country",
    ]) {
      expect(screen.getByText(label)).toBeInTheDocument();
    }
  });

  it("profile-location context renders the near-me explainer instead", () => {
    render(
      <AddressFieldset
        context="profile-location"
        value={{}}
        onChange={() => {}}
      />,
    );
    // Figma master copy (74:801)
    expect(
      screen.getByText(/recommend designers near you/i),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/pre-fills from your last order/i),
    ).toBeInTheDocument();
    expect(screen.queryByText("Recipient name")).not.toBeInTheDocument();
  });

  it("carries all 37 NG states in the select", () => {
    expect(NG_STATES).toHaveLength(37);
    expect(NG_STATES).toContain("Lagos");
    expect(NG_STATES).toContain("FCT Abuja");
  });

  it("propagates field edits via onChange", async () => {
    const onChange = vi.fn();
    render(
      <AddressFieldset context="delivery" value={{}} onChange={onChange} />,
    );
    await userEvent.type(screen.getByPlaceholderText("Full name"), "K");
    expect(onChange).toHaveBeenCalledWith(
      expect.objectContaining({ recipient_name: "K" }),
    );
  });

  it("renders field errors", () => {
    render(
      <AddressFieldset
        context="delivery"
        value={{}}
        onChange={() => {}}
        errors={{ phone: "Required" }}
      />,
    );
    expect(screen.getAllByText("Required").length).toBeGreaterThan(0);
  });
});
