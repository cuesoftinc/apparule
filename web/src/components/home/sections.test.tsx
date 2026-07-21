// Static-composition home sections (A3/A4b/A5/A6/A7c/A8) — render checks
// against the enriched-landing copy + accuracy-standard invariants.
import { afterEach, describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import {
  setAnalyticsTransport,
  type AnalyticsEvent,
} from "@/controllers/use-analytics";
import { ThemeProvider } from "@/design/ThemeProvider";
import { ArchitectureDiagram } from "./ArchitectureDiagram";
import { CommunitySection } from "./CommunitySection";
import { DesignersSection } from "./DesignersSection";
import { FeatureDeepDives } from "./FeatureDeepDives";
import { SelfHostSection } from "./SelfHostSection";
import { SmplSection } from "./SmplSection";
import { StatBand } from "./StatBand";

afterEach(() => setAnalyticsTransport(null));

describe("StatBand (A3)", () => {
  it("renders the three product claims — and only honest ones", () => {
    render(<StatBand />);
    expect(screen.getByText("±2 cm")).toBeInTheDocument();
    expect(screen.getByText("2 photos")).toBeInTheDocument();
    expect(screen.getByText("30 days")).toBeInTheDocument();
    expect(
      screen.getByText(/target accuracy vs a professional tape measure/),
    ).toBeInTheDocument();
  });
});

describe("FeatureDeepDives (A4b)", () => {
  it("renders the four alternating benefit panels with docs links", () => {
    // ThemeProvider: the composed NavRail previews read the theme context
    render(
      <ThemeProvider>
        <FeatureDeepDives />
      </ThemeProvider>,
    );
    const panels = screen.getAllByTestId("deep-dive-panel");
    expect(panels).toHaveLength(4);
    expect(screen.getByText("Capture once, keep it fresh")).toBeInTheDocument();
    expect(screen.getByText("Find designers near you")).toBeInTheDocument();
    expect(
      screen.getByText("Escrow-protected commissions"),
    ).toBeInTheDocument();
    expect(
      screen.getByText("Your measurements ride with every order"),
    ).toBeInTheDocument();
    expect(screen.getAllByRole("link", { name: /read more/i })).toHaveLength(4);
  });

  it("thumbs are composed component previews, decorative to AT", () => {
    render(
      <ThemeProvider>
        <FeatureDeepDives />
      </ThemeProvider>,
    );
    const screens = screen.getAllByTestId("mini-screen");
    expect(screens.length).toBeGreaterThanOrEqual(4);
    for (const node of screens) {
      expect(node).toHaveAttribute("aria-hidden");
      // Real `inert`, not just aria-hidden: the composed component
      // instances are focusable, and without inert they enter the tab
      // order (8× axe aria-hidden-focus, 2026-07-21 audit).
      expect(node).toHaveAttribute("inert");
    }
  });
});

describe("SmplSection (A5)", () => {
  it("renders the AI-modeling explainer with the MI-12 constellation", () => {
    render(<SmplSection />);
    expect(screen.getByText("AI-assisted body modeling")).toBeInTheDocument();
    expect(screen.getByTestId("constellation")).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /read the deep-dive on gitbook/i }),
    ).toBeInTheDocument();
  });
});

describe("DesignersSection (A6)", () => {
  it("renders the earnings composition from the demo controller", () => {
    render(<DesignersSection />);
    expect(
      screen.getByText("Post outfits, get commissioned, get paid"),
    ).toBeInTheDocument();
    expect(screen.getByTestId("balance-card")).toHaveTextContent("₦82,500");
    expect(screen.getByTestId("pending-card")).toHaveTextContent("₦45,000");
    expect(screen.getByText("Payout to GTBank ••• 4521")).toBeInTheDocument();
    expect(
      screen.getByText("Escrow held · order #APR-1042"),
    ).toBeInTheDocument();
  });
});

describe("SelfHostSection (A7c)", () => {
  it("renders pitch, tabbed snippet, what-ships and the docs link", () => {
    render(<SelfHostSection />);
    expect(screen.getByText("Self-host — own your data")).toBeInTheDocument();
    // tabbed snippet (Figma 415:2): Docker Compose active, Helm mirrored
    expect(
      screen.getByRole("tablist", { name: "Install method" }),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/cd apparule && docker compose up --build -d/),
    ).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: "Helm" })).toBeInTheDocument();
    expect(screen.getByText("api-common")).toBeInTheDocument();
    expect(screen.getByText("api-measure")).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /read the self-host guide/i }),
    ).toBeInTheDocument();
  });

  it("fires self_host_click on the docs handoff", async () => {
    const events: AnalyticsEvent[] = [];
    setAnalyticsTransport({ send: (e) => events.push(e) });
    render(<SelfHostSection />);
    const link = screen.getByRole("link", {
      name: /read the self-host guide/i,
    });
    // avoid jsdom navigation noise
    link.addEventListener("click", (e) => e.preventDefault());
    link.click();
    expect(events.map((e) => e.name)).toContain("self_host_click");
  });
});

describe("ArchitectureDiagram (A7)", () => {
  it("names every service tier of the mini-diagram", () => {
    render(<ArchitectureDiagram />);
    for (const label of [
      "Flutter app",
      "Next.js web",
      "Go API · api/common",
      "Python CV · MediaPipe + SMPL",
      "Postgres",
      "S3 media",
    ]) {
      expect(screen.getByText(label)).toBeInTheDocument();
    }
  });
});

describe("CommunitySection (A8)", () => {
  it("renders the Discord card with the neutral member line (no invented count)", () => {
    render(<CommunitySection />);
    expect(screen.getByText("Join the apparule Discord")).toBeInTheDocument();
    expect(screen.getByTestId("member-badge")).not.toHaveTextContent("members");
    expect(screen.getByRole("link", { name: "Roadmap →" })).toBeInTheDocument();
    expect(
      screen.getByText("An open-source product by CueLABS™"),
    ).toBeInTheDocument();
  });
});
