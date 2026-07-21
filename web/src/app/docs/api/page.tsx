// Public API reference `/docs/api` (F0-8, APP-004) — the Scalar
// interactive reference rendered from the repo's canonical OpenAPI
// document (docs/api/openapi.yaml, served at /docs/api/openapi.yaml).
// Production surface: public, no auth, under the marketing nav chrome
// with a minimal legal footer strip (the full A10 footer stays on `/`).
import type { Metadata } from "next";
import { HomeNavBar } from "@/components/home/HomeNavBar";
import { PageViewTracker } from "@/components/home/PageViewTracker";
import { ScalarApiReferenceLazy } from "@/components/docs/ScalarApiReferenceLazy";

const DESCRIPTION =
  "Interactive reference for the Apparule API — every endpoint, schema and error envelope, rendered live from the repo's OpenAPI document.";

export const metadata: Metadata = {
  title: "API reference — Apparule",
  description: DESCRIPTION,
};

export default function ApiReferencePage() {
  return (
    <div className="flex min-h-screen flex-col bg-bg text-text">
      <PageViewTracker path="/docs/api" />
      <HomeNavBar />
      {/* Header-fix construction (2026-07-20): the sticky marketing nav
          (h-16 = 64px) and Scalar's own sticky layout coexist by telling
          Scalar about the header — `--scalar-custom-header-height` offsets
          its sticky sidebar/mobile header below the nav and shrinks its
          viewport math to match (one coherent scroll). `isolate` opens a
          stacking context so no Scalar z-index can paint over the nav. */}
      <main
        id="main"
        tabIndex={-1}
        className="isolate flex-1 [--scalar-custom-header-height:64px]"
      >
        <ScalarApiReferenceLazy />
      </main>
      {/* Minimal footer strip — verbatim legal line only (parity canon). */}
      <footer className="border-t border-border px-6 py-4 text-caption text-text-2">
        <div className="mx-auto max-w-[1080px]">
          <span>
            ©{" "}
            <a
              href="https://cuesoft.io"
              target="_blank"
              rel="noreferrer"
              className="hover:text-text"
            >
              Cuesoft Inc.
            </a>{" "}
            2026. Apparule.{" "}
            <a
              href="https://cuelabs.cuesoft.io"
              target="_blank"
              rel="noreferrer"
              className="hover:text-text"
            >
              CueLABS™ Division
            </a>
            .{" "}
            <a
              href="https://github.com/cuesoftinc/apparule/blob/main/LICENSE"
              target="_blank"
              rel="noreferrer"
              className="hover:text-text"
            >
              MIT License
            </a>
            .
          </span>
        </div>
      </footer>
    </div>
  );
}
