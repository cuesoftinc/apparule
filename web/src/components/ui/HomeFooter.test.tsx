import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { HomeFooter } from "./HomeFooter";

describe("HomeFooter (§8.2b marketing, parity canon 2026-07-19)", () => {
  it("renders the four canon link columns", () => {
    render(<HomeFooter />);
    for (const heading of ["Product", "Docs", "Community", "Legal"]) {
      expect(screen.getByRole("heading", { name: heading })).toBeInTheDocument();
    }
  });

  it("Docs and Community columns hit the verified canonical URLs", () => {
    render(<HomeFooter />);
    const canon: [string, string][] = [
      ["Docs", "https://cuesoft.gitbook.io/apparule"],
      ["Quickstart", "https://cuesoft.gitbook.io/apparule/setup"],
      ["API reference", "https://cuesoft.gitbook.io/apparule/system/api-surface"],
      ["Self-host guide", "https://cuesoft.gitbook.io/apparule/system/deployment"],
      ["GitHub", "https://github.com/cuesoftinc/apparule"],
      ["Discord", "https://discord.gg/CDfZxxrxbb"],
      ["Roadmap", "https://cuesoft.gitbook.io/apparule/product/roadmap"],
      ["CueLABS", "https://cuelabs.cuesoft.io"],
    ];
    for (const [name, href] of canon) {
      expect(screen.getByRole("link", { name })).toHaveAttribute("href", href);
    }
    expect(screen.queryByText("Contributing")).not.toBeInTheDocument();
    expect(screen.queryByText("Good first issues")).not.toBeInTheDocument();
  });

  it("renders the Legal column and the verbatim legal bar", () => {
    render(<HomeFooter />);
    expect(screen.getByRole("link", { name: "Privacy" })).toHaveAttribute(
      "href",
      "https://privacy.cuesoft.io",
    );
    expect(screen.getByRole("link", { name: "Terms" })).toHaveAttribute(
      "href",
      "https://terms.cuesoft.io",
    );
    expect(screen.getByRole("link", { name: "Status" })).toHaveAttribute(
      "href",
      "https://status.cuesoft.io",
    );
    // verbatim: © Cuesoft Inc. 2026. Apparule. CueLABS™ Division. MIT License.
    expect(screen.getByRole("link", { name: "Cuesoft Inc." })).toHaveAttribute(
      "href",
      "https://cuesoft.io",
    );
    expect(
      screen.getByRole("link", { name: "CueLABS™ Division" }),
    ).toHaveAttribute("href", "https://cuelabs.cuesoft.io");
    expect(screen.getByRole("link", { name: "MIT License" })).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule/blob/main/LICENSE",
    );
    expect(
      screen.getByRole("link", { name: /Security policy/ }),
    ).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule/blob/main/SECURITY.md",
    );
  });

  it("renders the language selector", () => {
    render(<HomeFooter />);
    expect(screen.getByLabelText("Language")).toBeInTheDocument();
  });
});
