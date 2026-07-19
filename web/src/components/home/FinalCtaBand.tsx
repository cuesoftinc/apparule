"use client";

// A9c Final CTA band (canvas 201:2) — full-width accent-gradient band:
// one-line close + the A2 CTA pair as on-accent pills (white fill / white
// outline), MIT microcopy. CTA hover lifts 2px (as A2);
// `try_cloud_click` / `self_host_click` fire here.
import { useRouter } from "next/navigation";
import { track } from "@/controllers/analytics";

const PILL_BASE =
  "flex items-center justify-center rounded-pill px-7 py-3.5 text-body-lg font-semibold transition-transform duration-120 ease-standard hover:-translate-y-0.5 active:scale-[0.98] motion-reduce:transition-none motion-reduce:hover:translate-y-0";

export function FinalCtaBand() {
  const router = useRouter();

  return (
    <section
      aria-labelledby="final-cta-heading"
      className="bg-accent-gradient px-6 py-9"
    >
      {/* Canonical 1080 content column (design.md container canon) keeps
          the band's content box flush with sibling sections (W2.1 live-QA). */}
      <div className="mx-auto flex max-w-[1080px] flex-col items-center gap-5 text-center">
        <h2
          id="final-cta-heading"
          className="text-display font-bold tracking-[-0.5px] text-on-accent"
        >
          Get measured once. Dress like it was always made for you.
        </h2>
        <div className="flex flex-wrap justify-center gap-4">
          <button
            type="button"
            className={`${PILL_BASE} bg-on-accent text-accent-start`}
            onClick={() => {
              track("try_cloud_click", { section: "final-cta" });
              router.push("/signin");
            }}
          >
            Try Cloud
          </button>
          <button
            type="button"
            className={`${PILL_BASE} border-[1.5px] border-on-accent text-on-accent`}
            onClick={() => {
              track("self_host_click", { section: "final-cta" });
              document
                .getElementById("self-host")
                ?.scrollIntoView({ behavior: "smooth", block: "start" });
            }}
          >
            Self Host
          </button>
        </div>
        <p className="text-caption text-on-accent">
          Open source · MIT licensed · Self-host in one line
        </p>
      </div>
    </section>
  );
}
