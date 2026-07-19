"use client";

// A9 Cloud vs Self-host (canvas 186:184/186:185) — the ComparisonTable with
// its CTA row: Cloud → Try Cloud handoff (/signin), OSS → docs quickstart.
import { useRouter } from "next/navigation";
import { ComparisonTable } from "@/components/ui/ComparisonTable";
import { track } from "@/controllers/use-analytics";

export function ComparisonSection() {
  const router = useRouter();

  return (
    <section
      id="compare"
      aria-labelledby="compare-heading"
      className="mx-auto flex w-full max-w-[1128px] scroll-mt-20 flex-col items-center px-6 py-12"
    >
      <h2 id="compare-heading" className="self-start text-title-lg font-bold text-text">
        Cloud or self-host — same product
      </h2>
      <div className="mt-6 flex w-full justify-center">
        <ComparisonTable
          onTryCloud={() => {
            track("try_cloud_click", { section: "comparison" });
            router.push("/signin");
          }}
          onSelfHost={() => {
            track("self_host_click", { section: "comparison" });
            window.open(
              "https://docs.apparule.cuesoft.io/self-host",
              "_blank",
              "noopener",
            );
          }}
        />
      </div>
    </section>
  );
}
