// A5 SMPL/AI section (APP-003) — "AI-assisted body modeling" explainer with
// the looping landmark-constellation animation (same asset as MI-12) and a
// GitBook deep-dive link (canvas 186:83–186:86).
import { ProcessingConstellation } from "@/components/ui/ProcessingConstellation";

export function SmplSection() {
  return (
    <section
      aria-labelledby="smpl-heading"
      className="mx-auto w-full max-w-[1080px] px-6 py-12"
    >
      <div className="flex flex-col items-start gap-10 md:flex-row md:items-center md:gap-16">
        <div className="max-w-[480px] flex-1">
          <h2 id="smpl-heading" className="text-title-lg font-bold text-text">
            AI-assisted body modeling
          </h2>
          <p className="mt-4 text-body-lg text-text-2">
            Two photos become a full measurement set. SMPL landmark detection
            maps your proportions — no tape, no guessing. The constellation
            you see while it works is the real model output.
          </p>
          <a
            href="https://docs.apparule.cuesoft.io/ai-modeling"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-6 inline-block text-body font-semibold text-link hover:underline"
          >
            Read the deep-dive on GitBook →
          </a>
        </div>
        <div className="w-70 shrink-0">
          <ProcessingConstellation
            state="processing"
            imageSrc="/demo/outfit-w05.jpg"
            imageAlt="Full-length photo with pose landmarks drawn over it"
          />
        </div>
      </div>
    </section>
  );
}
