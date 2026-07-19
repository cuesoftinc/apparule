// Interactive home sections — hero CTAs, walkthrough engagement, FAQ
// accordion + deep links, comparison/final-CTA handoffs, nav theme toggle,
// hero phone-mock scene loop.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { act, fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import {
  setAnalyticsTransport,
  type AnalyticsEvent,
} from "@/controllers/use-analytics";
import { ThemeProvider } from "@/design/ThemeProvider";

const push = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push }),
}));

const stars = vi.fn<() => Promise<number | null>>(() =>
  Promise.resolve(null),
);
vi.mock("@/models/repositories/github-repo", async (importOriginal) => {
  const original =
    await importOriginal<typeof import("@/models/repositories/github-repo")>();
  return {
    ...original,
    githubRepo: { stars: () => stars() },
  };
});

import { ComparisonSection } from "./ComparisonSection";
import { DevelopersSection } from "./DevelopersSection";
import { FaqSection } from "./FaqSection";
import { FinalCtaBand } from "./FinalCtaBand";
import { HeroPhoneMock } from "./HeroPhoneMock";
import { HeroSection } from "./HeroSection";
import { HomeNavBar } from "./HomeNavBar";
import { WalkthroughSection } from "./WalkthroughSection";

let events: AnalyticsEvent[] = [];

beforeEach(() => {
  events = [];
  setAnalyticsTransport({ send: (e) => events.push(e) });
  push.mockClear();
  window.HTMLElement.prototype.scrollBy ??= () => {};
  window.location.hash = "";
});

afterEach(() => {
  setAnalyticsTransport(null);
  document.documentElement.removeAttribute("data-theme");
  window.localStorage.clear();
  vi.useRealTimers(); // safety net — a timed-out test must not leak fake timers
});

const names = () => events.map((e) => e.name);

describe("HeroSection (A2)", () => {
  it("renders the canvas H1, subcopy and open-source microcopy", () => {
    render(<HeroSection />);
    expect(
      screen.getByRole("heading", { name: "Two photos. A perfect fit." }),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/two phone photos into a complete, private/i),
    ).toBeInTheDocument();
    expect(
      screen.getByText("Open-source · Self-host in one line"),
    ).toBeInTheDocument();
  });

  it("Try Cloud tracks and hands off to /signin", async () => {
    render(<HeroSection />);
    await userEvent.click(screen.getAllByRole("button", { name: "Try Cloud" })[0]);
    expect(names()).toContain("try_cloud_click");
    expect(push).toHaveBeenCalledWith("/signin");
  });

  it("Self Host tracks self_host_click", async () => {
    render(<HeroSection />);
    await userEvent.click(screen.getByRole("button", { name: "Self Host" }));
    expect(names()).toContain("self_host_click");
  });
});

describe("HeroPhoneMock loop (A2)", () => {
  it("starts on the feed scene rendering the demo posts through the controller", () => {
    render(<HeroPhoneMock />);
    expect(screen.getByTestId("hero-phone")).toHaveAttribute(
      "data-scene",
      "feed",
    );
    expect(screen.getByText("amara.designs")).toBeInTheDocument();
    expect(screen.getByText("kikithreads")).toBeInTheDocument();
    expect(screen.getAllByText("Request this outfit").length).toBeGreaterThan(0);
  });

  it("advances feed → capture on the loop timer and pauses on hover", () => {
    vi.useFakeTimers();
    render(<HeroPhoneMock />);
    const phone = screen.getByTestId("hero-phone");
    act(() => {
      vi.advanceTimersByTime(4000);
    });
    expect(phone).toHaveAttribute("data-scene", "capture");

    fireEvent.mouseEnter(phone);
    act(() => {
      vi.advanceTimersByTime(8000);
    });
    expect(phone).toHaveAttribute("data-scene", "capture"); // paused

    fireEvent.mouseLeave(phone);
    act(() => {
      vi.advanceTimersByTime(4000);
    });
    expect(phone).toHaveAttribute("data-scene", "request"); // resumed
  });
});

describe("WalkthroughSection (A4)", () => {
  it("renders the four steps with per-instance active dots", () => {
    render(<WalkthroughSection />);
    // getAllByText: step titles can recur inside the composed previews
    for (const title of ["Capture", "Vault", "Discover", "Commission"]) {
      expect(screen.getAllByText(title).length).toBeGreaterThan(0);
    }
    expect(screen.getAllByTestId("step-dots")).toHaveLength(4);
  });

  it("keyboard arrows engage the walkthrough — demo_start fires once", async () => {
    render(<WalkthroughSection />);
    const rail = screen.getByTestId("walkthrough-rail");
    rail.focus();
    await userEvent.keyboard("{ArrowRight}{ArrowRight}{ArrowLeft}");
    expect(names().filter((n) => n === "demo_start")).toHaveLength(1);
  });
});

describe("FaqSection (A9b)", () => {
  it("keeps the first row expanded by default, one open at a time", async () => {
    render(<FaqSection />);
    const first = screen.getByRole("button", {
      name: "How accurate are camera measurements?",
    });
    expect(first).toHaveAttribute("aria-expanded", "true");

    const second = screen.getByRole("button", {
      name: "What happens to my photos?",
    });
    await userEvent.click(second);
    expect(second).toHaveAttribute("aria-expanded", "true");
    expect(first).toHaveAttribute("aria-expanded", "false");
    expect(names()).toContain("faq_open");
  });

  it("renders all five product questions with honest answers", () => {
    render(<FaqSection />);
    expect(
      screen.getByText(/±2 cm of a professional tape measure/),
    ).toBeInTheDocument();
    for (const q of [
      "How accurate are camera measurements?",
      "What happens to my photos?",
      "How do payments and escrow work?",
      "What do I need to self-host?",
      "What license is Apparule under?",
    ]) {
      expect(screen.getByText(q)).toBeInTheDocument();
    }
  });

  it("deep-links open the matching row (#faq-n)", async () => {
    window.location.hash = "#faq-4";
    render(<FaqSection />);
    const linked = await screen.findByRole("button", {
      name: "What do I need to self-host?",
    });
    expect(linked).toHaveAttribute("aria-expanded", "true");
  });
});

describe("ComparisonSection (A9)", () => {
  it("Start on Cloud hands off to /signin with try_cloud_click", async () => {
    render(<ComparisonSection />);
    await userEvent.click(
      screen.getByRole("button", { name: "Start on Cloud" }),
    );
    expect(names()).toContain("try_cloud_click");
    expect(push).toHaveBeenCalledWith("/signin");
  });

  it("Self-host it opens the docs quickstart with self_host_click", async () => {
    const open = vi.spyOn(window, "open").mockImplementation(() => null);
    render(<ComparisonSection />);
    await userEvent.click(screen.getByRole("button", { name: "Self-host it" }));
    expect(names()).toContain("self_host_click");
    expect(open).toHaveBeenCalledWith(
      "https://cuesoft.gitbook.io/apparule/system/deployment",
      "_blank",
      "noopener",
    );
    open.mockRestore();
  });
});

describe("FinalCtaBand (A9c)", () => {
  it("repeats the CTA pair with the MIT microcopy and fires the events", async () => {
    render(<FinalCtaBand />);
    expect(
      screen.getByText(
        "Get measured once. Dress like it was always made for you.",
      ),
    ).toBeInTheDocument();
    expect(
      screen.getByText("Open-source · MIT licensed · Self-host in one line"),
    ).toBeInTheDocument();

    await userEvent.click(screen.getAllByRole("button", { name: "Try Cloud" })[0]);
    expect(names()).toContain("try_cloud_click");
    expect(push).toHaveBeenCalledWith("/signin");

    await userEvent.click(screen.getByRole("button", { name: "Self Host" }));
    expect(names()).toContain("self_host_click");
  });
});

describe("DevelopersSection (A7b)", () => {
  it("renders the three interesting-problem cards and the contribute links", () => {
    render(<DevelopersSection />);
    expect(screen.getAllByTestId("dev-topic-card")).toHaveLength(3);
    expect(screen.getByText("MediaPipe pose QC")).toBeInTheDocument();
    expect(screen.getByText("SMPL body modeling")).toBeInTheDocument();
    expect(screen.getByText("Escrow order lifecycle")).toBeInTheDocument();
    // neutral star badge — no invented count
    expect(screen.getByTestId("dev-star-badge")).toHaveTextContent(
      "Star on GitHub",
    );
  });

  it("fires github_click / contribute_click on the links", async () => {
    render(<DevelopersSection />);
    const link = screen.getByRole("link", { name: /good first issues/i });
    link.addEventListener("click", (e) => e.preventDefault());
    await userEvent.click(link);
    expect(names()).toContain("github_click");
    expect(names()).toContain("contribute_click");
  });
});

describe("HomeNavBar (A1)", () => {
  it("toggles the theme (light ↔ dark) from the nav", async () => {
    render(
      <ThemeProvider>
        <HomeNavBar />
      </ThemeProvider>,
    );
    const toggle = screen.getByRole("button", { name: /switch to dark theme/i });
    await userEvent.click(toggle);
    expect(document.documentElement).toHaveAttribute("data-theme", "dark");
    await userEvent.click(
      screen.getByRole("button", { name: /switch to light theme/i }),
    );
    expect(document.documentElement).toHaveAttribute("data-theme", "light");
  });

  it("nav: Sign in text link + Try Cloud CTA hands off with try_cloud_click", async () => {
    render(
      <ThemeProvider>
        <HomeNavBar />
      </ThemeProvider>,
    );
    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/signin",
    );
    await userEvent.click(screen.getAllByRole("button", { name: "Try Cloud" })[0]);
    expect(names()).toContain("try_cloud_click");
    expect(push).toHaveBeenCalledWith("/signin");
  });

  it("nav star badge keeps the neutral label while no live count exists", () => {
    render(
      <ThemeProvider>
        <HomeNavBar />
      </ThemeProvider>,
    );
    expect(screen.getByTestId("star-badge")).toHaveTextContent("Star");
  });

  it("nav GitHub star badge fires github_click", async () => {
    render(
      <ThemeProvider>
        <HomeNavBar />
      </ThemeProvider>,
    );
    const github = screen.getByTestId("star-badge");
    expect(github).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    await userEvent.click(github);
    expect(names()).toContain("github_click");
  });
});
