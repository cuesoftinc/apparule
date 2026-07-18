import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { RequestCard } from "./RequestCard";
import { fixtureOrder } from "./fixtures";

describe("RequestCard (§8.2)", () => {
  it("renders thumb, order number, counterparty, pill, and price", () => {
    render(<RequestCard order={fixtureOrder} role="customer" />);
    expect(screen.getByText(/#APR-1042/)).toBeInTheDocument();
    expect(screen.getByText(/by amara.designs/)).toBeInTheDocument();
    expect(screen.getByText("in progress")).toBeInTheDocument();
    expect(screen.getByText("₦45,000")).toBeInTheDocument();
  });

  it("role axis flips the counterparty", () => {
    render(<RequestCard order={fixtureOrder} role="designer" />);
    expect(screen.getByText(/for kiki.adeyemi/)).toBeInTheDocument();
  });

  it("next-action per role/state: customer pays a quoted order", async () => {
    const onAction = vi.fn();
    render(
      <RequestCard
        order={{ ...fixtureOrder, status: "quoted" }}
        role="customer"
        onAction={onAction}
      />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Pay" }));
    expect(onAction).toHaveBeenCalledWith("Pay");
  });

  it("designer quotes a requested order", () => {
    render(
      <RequestCard
        order={{ ...fixtureOrder, status: "requested", quote_cents: null }}
        role="designer"
      />,
    );
    expect(screen.getByRole("button", { name: "Quote" })).toBeInTheDocument();
    // no quote yet → budget renders instead
    expect(screen.getByText("₦50,000")).toBeInTheDocument();
  });

  it("terminal/no-action states render no action button", () => {
    render(
      <RequestCard order={{ ...fixtureOrder, status: "declined" }} role="designer" />,
    );
    expect(screen.queryByRole("button", { name: /quote|pay|mark/i })).not.toBeInTheDocument();
  });
});
