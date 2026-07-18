import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { FormRow } from "./FormRow";
import { Input } from "./Input";

describe("FormRow (§8.2)", () => {
  it("renders label + helper", () => {
    render(
      <FormRow label="Username" helper="3–30 chars">
        <Input aria-label="Username" />
      </FormRow>,
    );
    expect(screen.getByText("Username")).toBeInTheDocument();
    expect(screen.getByText("3–30 chars")).toBeInTheDocument();
  });

  it("error replaces helper", () => {
    render(
      <FormRow label="Username" helper="3–30 chars" error="Taken">
        <Input aria-label="Username" />
      </FormRow>,
    );
    expect(screen.getByText("Taken")).toBeInTheDocument();
    expect(screen.queryByText("3–30 chars")).not.toBeInTheDocument();
  });

  it("marks required fields", () => {
    render(
      <FormRow label="Phone" required>
        <Input aria-label="Phone" />
      </FormRow>,
    );
    expect(screen.getByText("*")).toBeInTheDocument();
  });
});
