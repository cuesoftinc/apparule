"use client";

// A9b FAQ (canvas 200:6483/200:6484) — five product Q&As, one open at a
// time, first expanded by default (FAQItem master rule), rows deep-linkable
// via #faq-n. Questions are the canvas copy; the first answer is the canvas
// text and the collapsed rows' answers are composed from the docs claims
// (pages.md A9b topics — the Figma file only renders the expanded row).
// `faq_open` fires on expand.
import { useEffect, useSyncExternalStore } from "react";
import { FAQGroup, FAQItem } from "@/components/ui/FAQItem";
import { track } from "@/controllers/use-analytics";

const FAQS = [
  {
    id: "faq-1",
    question: "How accurate are camera measurements?",
    answer:
      "We target within ±0.8 in of a professional tape measure for most values. Good lighting and a full-body frame matter — the capture guide checks both, and you can correct any value manually.",
  },
  {
    id: "faq-2",
    question: "What happens to my photos?",
    answer:
      "Capture photos are used to compute your measurements, then auto-deleted within 30 days. The measurements live in your private vault — visible to no one, and shared only as a frozen snapshot inside a commission request you choose to send.",
  },
  {
    id: "faq-3",
    question: "How do payments and escrow work?",
    answer:
      "You pay when you accept a designer's quote, and the money is held in escrow — not sent ahead. Funds release to the designer when you confirm delivery; opening a dispute freezes payout until it's resolved. The platform fee is an itemized 10% of the quote.",
  },
  {
    id: "faq-4",
    question: "What do I need to self-host?",
    answer:
      "Docker and one command: docker compose up -d brings up everything that ships — api-common (Go), api-measure (Python CV), and the web app — on your own Postgres and S3-compatible storage. The self-host guide covers sizing and configuration.",
  },
  {
    id: "faq-5",
    question: "What license is Apparule under?",
    answer:
      "MIT. The whole product — mobile app, web, API, and the measurement pipeline — is open-source under the MIT license: fork it, self-host it, build on it.",
  },
] as const;

function subscribeHash(callback: () => void): () => void {
  window.addEventListener("hashchange", callback);
  return () => window.removeEventListener("hashchange", callback);
}

export function FaqSection() {
  // First row open by default (Figma master rule); a #faq-n deep link
  // re-keys the group to open the linked row instead (pages.md A9b).
  const hash = useSyncExternalStore(
    subscribeHash,
    () => window.location.hash.replace("#", ""),
    () => "",
  );
  const deepLink = FAQS.some((f) => f.id === hash) ? hash : null;
  const initialOpenId = deepLink ?? "faq-1";

  useEffect(() => {
    if (deepLink) {
      document.getElementById(deepLink)?.scrollIntoView({ block: "center" });
    }
  }, [deepLink]);

  return (
    <section
      id="faq"
      aria-labelledby="faq-heading"
      className="mx-auto w-full max-w-[1128px] scroll-mt-20 px-6 py-12"
    >
      <h2 id="faq-heading" className="text-title-lg font-bold text-text">
        Frequently asked
      </h2>
      <FAQGroup
        key={initialOpenId}
        defaultOpenId={initialOpenId}
        className="mt-6 max-w-[800px]"
      >
        {FAQS.map((faq) => (
          <FAQItem
            key={faq.id}
            id={faq.id}
            question={faq.question}
            onOpenChange={(open) => {
              if (open) track("faq_open", { faq: faq.id });
            }}
          >
            {faq.answer}
          </FAQItem>
        ))}
      </FAQGroup>
    </section>
  );
}
