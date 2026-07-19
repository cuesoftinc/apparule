// A8 Community (canvas 186:171–186:183) — Discord card (live member count
// stays neutral until a real count exists — accuracy standard), roadmap
// link, CueLABS™ note.
import { CommunityCard } from "@/components/ui/CommunityCard";

export function CommunitySection() {
  return (
    <section
      id="community"
      aria-labelledby="community-heading"
      className="mx-auto w-full max-w-[1128px] scroll-mt-20 px-6 py-12"
    >
      <h2 id="community-heading" className="text-title-lg font-bold text-text">
        Community
      </h2>
      <div className="mt-6 flex flex-col items-start gap-8 md:flex-row md:items-center md:gap-10">
        <CommunityCard />
        <div>
          <a
            href="https://cuesoft.gitbook.io/apparule/product/roadmap"
            target="_blank"
            rel="noopener noreferrer"
            className="text-body font-semibold text-link hover:underline"
          >
            Roadmap →
          </a>
          <p className="mt-3 text-caption text-text-2">
            An open-source product by CueLABS™
          </p>
        </div>
      </div>
    </section>
  );
}
