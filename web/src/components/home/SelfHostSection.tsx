"use client";

// A7c Self-host (canvas 186:160–186:170, 198:6492/6493, 264:8529; tabbed
// proposal 415:2) — data-ownership pitch · the Docker Compose | Helm
// tabbed snippet with copy-✓ morph (mirrored two-line commands; compose =
// `make up`, helm chart at deploy/helm) · "what ships" line · architecture
// mini-diagram · docs quickstart link. `self_host_click` fires on the docs
// handoff.
import { CodeSnippetTabs } from "@/components/ui/CodeSnippetTabs";
import { track } from "@/controllers/use-analytics";
import { ArchitectureDiagram } from "./ArchitectureDiagram";

export function SelfHostSection() {
  return (
    <section
      id="self-host"
      aria-labelledby="self-host-heading"
      className="mx-auto w-full max-w-[1128px] scroll-mt-20 px-6 py-12"
    >
      <div className="flex flex-col items-start gap-10 md:flex-row md:gap-16">
        {/* min-w-0: the snippet's nowrap command lines must not widen the
            flex item past the viewport at 390 — they scroll inside the
            block's own overflow-x rail instead (container canon) */}
        <div className="w-full min-w-0 max-w-[560px] flex-1">
          <h2
            id="self-host-heading"
            className="text-title-lg font-bold text-text"
          >
            Self-host — own your data
          </h2>
          <p className="mt-4 text-body text-text-2">
            Run Apparule for your atelier, your fashion school, or your
            city&apos;s designer community. One command brings up every service
            — API, CV pipeline, dashboard — on your own Postgres and
            S3-compatible storage. Your customers&apos; measurements never leave
            your box.
          </p>
          <div className="mt-6 max-w-[460px]" data-testid="selfhost-snippet">
            <CodeSnippetTabs
              label="Install method"
              tabs={[
                {
                  label: "Docker Compose",
                  code: "git clone https://github.com/cuesoftinc/apparule\ncd apparule && docker compose up --build -d",
                },
                {
                  label: "Helm",
                  code: "git clone https://github.com/cuesoftinc/apparule\ncd apparule && helm install apparule deploy/helm",
                },
              ]}
            />
          </div>
          <p className="mt-3 text-caption text-text-2">
            All services, your storage, no lock-in.
          </p>
          <p className="mt-1 text-caption text-text-2">
            Ships <code className="font-mono">api-common</code> ·{" "}
            <code className="font-mono">api-measure</code> ·{" "}
            <code className="font-mono">web</code>
          </p>
          <a
            href="https://cuesoft.gitbook.io/apparule/system/deployment"
            target="_blank"
            rel="noopener noreferrer"
            onClick={() => track("self_host_click", { section: "self-host" })}
            className="mt-4 inline-block text-body font-semibold text-link hover:underline"
          >
            Read the self-host guide →
          </a>
        </div>
        <div className="w-full max-w-[300px] shrink-0 md:pt-4">
          <ArchitectureDiagram />
        </div>
      </div>
    </section>
  );
}
