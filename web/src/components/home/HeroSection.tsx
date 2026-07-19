"use client";

// A2 Hero — H1 + subcopy + dual CTA Try Cloud / Self Host + the phone-mock
// demo loop (canvas 186:18–186:25). CTA hover lifts 2px; Try Cloud hands
// off to /signin (the §8.4 marketing → app flow), Self Host jumps to the
// A7c section.
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { track } from "@/controllers/use-analytics";
import { HeroPhoneMock } from "./HeroPhoneMock";

export function HeroSection() {
  const router = useRouter();

  return (
    <section aria-labelledby="hero-heading" className="mx-auto w-full max-w-[1128px] px-6">
      <div className="flex flex-col items-start gap-12 pb-16 pt-10 md:flex-row md:items-center md:gap-16 md:pb-20 md:pt-16">
        <div className="max-w-[520px]">
          <h1
            id="hero-heading"
            className="text-display font-bold tracking-[-0.5px] text-text"
          >
            Two photos. A perfect fit.
          </h1>
          <p className="mt-6 max-w-[480px] text-body-lg text-text-2">
            Apparule turns two phone photos into a complete, private
            body-measurement profile. Commission Lagos designers who sew to
            your measurements — no size charts, no guesswork.
          </p>
          <div className="mt-8 flex flex-wrap gap-4">
            <Button
              className="h-12 w-[150px] hover:-translate-y-0.5 motion-reduce:hover:translate-y-0"
              onClick={() => {
                track("try_cloud_click", { section: "hero" });
                router.push("/signin");
              }}
            >
              Try Cloud
            </Button>
            <Button
              kind="quiet"
              className="h-12 w-[150px] hover:-translate-y-0.5 motion-reduce:hover:translate-y-0"
              onClick={() => {
                track("self_host_click", { section: "hero" });
                document
                  .getElementById("self-host")
                  ?.scrollIntoView({ behavior: "smooth", block: "start" });
              }}
            >
              Self Host
            </Button>
          </div>
          <p className="mt-4 text-caption text-text-2">
            Open source · Self-host in one line
          </p>
        </div>
        <div className="mx-auto shrink-0 md:mx-0 md:ml-auto">
          <HeroPhoneMock />
        </div>
      </div>
    </section>
  );
}
