"use client";

// A7b For developers — Contribute (canvas 198:225–198:6490): stack line ·
// three "interesting problems" cards · links (good-first-issues,
// CONTRIBUTING.md, Discord) · GitHub star badge reusing the A1 fetch.
// Cards lift 2px on hover; `github_click` / `contribute_click` fire here.
import { Camera, User, Wallet } from "lucide-react";
import { DiscordMark } from "@/components/icons/DiscordMark";
import { GitHubMark } from "@/components/icons/GitHubMark";
import { track } from "@/controllers/analytics";
import { useGithubStars } from "@/controllers/use-github-stars";
import { GITHUB_REPO_URL } from "@/models/repositories/github-repo";

const TOPICS = [
  {
    icon: Camera,
    title: "MediaPipe pose QC",
    body: "Quality gates in Python that reject blur, tilt and partial bodies before they reach the model — 11 failure codes, each with its own retake guidance.",
  },
  {
    icon: User,
    title: "SMPL body modeling",
    body: "Fit a parametric body mesh from two views, then turn vertices into tape-measure girths. CV that ships to real tailors, not a paper demo.",
  },
  {
    icon: Wallet,
    title: "Escrow order lifecycle",
    body: "A Go state machine that moves real money: quotes, escrow holds, auto-refund deadlines, payouts. Every transition tested against fixtures.",
  },
] as const;

const LINK_CLASSES =
  "inline-flex items-center gap-2 text-body font-semibold text-link transition-transform duration-120 ease-standard hover:-translate-y-0.5 hover:underline motion-reduce:transition-none motion-reduce:hover:translate-y-0";

export function DevelopersSection() {
  const stars = useGithubStars();

  return (
    <section
      id="developers"
      aria-labelledby="developers-heading"
      className="mx-auto w-full max-w-[1128px] scroll-mt-20 px-6 py-12"
    >
      <h2 id="developers-heading" className="text-title-lg font-bold text-text">
        For developers — hack on the interesting parts
      </h2>
      <p className="mt-3 text-body text-text-2">
        Flutter · Go · Python CV · Next.js — MIT licensed, api/common +
        function-named services
      </p>
      <div className="mt-8 grid gap-6 md:grid-cols-3">
        {TOPICS.map((topic) => (
          <div
            key={topic.title}
            data-testid="dev-topic-card"
            className="rounded-card border border-border bg-bg-elev p-6 transition-transform duration-120 ease-standard hover:-translate-y-0.5 motion-reduce:transition-none motion-reduce:hover:translate-y-0"
          >
            {/* canvas 198:229…: topic glyphs bind the text token */}
            <topic.icon size={24} className="text-text" aria-hidden />
            <h3 className="mt-3 text-body-lg font-semibold text-text">
              {topic.title}
            </h3>
            <p className="mt-3 text-body text-text-2">{topic.body}</p>
          </div>
        ))}
      </div>
      <div className="mt-10 flex flex-wrap items-center gap-x-8 gap-y-4">
        <a
          href={`${GITHUB_REPO_URL}/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22`}
          target="_blank"
          rel="noopener noreferrer"
          onClick={() => {
            track("github_click", { section: "developers" });
            track("contribute_click", { link: "good_first_issues" });
          }}
          className={LINK_CLASSES}
        >
          <GitHubMark size={18} />
          Good first issues →
        </a>
        <a
          href={`${GITHUB_REPO_URL}/blob/main/CONTRIBUTING.md`}
          target="_blank"
          rel="noopener noreferrer"
          onClick={() => {
            track("github_click", { section: "developers" });
            track("contribute_click", { link: "contributing" });
          }}
          className={LINK_CLASSES}
        >
          CONTRIBUTING.md →
        </a>
        <a
          href="https://discord.gg/cuesoft"
          target="_blank"
          rel="noopener noreferrer"
          onClick={() => track("contribute_click", { link: "discord" })}
          className={LINK_CLASSES}
        >
          <DiscordMark size={18} />
          #apparule-dev on Discord →
        </a>
        <a
          href={GITHUB_REPO_URL}
          target="_blank"
          rel="noopener noreferrer"
          data-testid="dev-star-badge"
          onClick={() => track("github_click", { section: "developers" })}
          className="inline-flex h-9 items-center gap-2 rounded-pill border border-border px-4 text-body font-semibold text-text transition-transform duration-120 ease-standard hover:-translate-y-0.5 hover:bg-border/30 motion-reduce:transition-none motion-reduce:hover:translate-y-0"
        >
          <GitHubMark size={16} />
          Star on GitHub
          {stars !== null ? (
            <span className="tnum text-text-2">
              {stars.toLocaleString("en-NG")}
            </span>
          ) : null}
        </a>
      </div>
    </section>
  );
}
