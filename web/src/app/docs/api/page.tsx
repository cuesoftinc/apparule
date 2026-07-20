// Public API reference `/docs/api` (F0-8, APP-004) — the Scalar
// interactive reference rendered from the repo's canonical OpenAPI
// document (docs/api/openapi.yaml, served at /docs/api/openapi.yaml).
// Production surface: public, no auth, under the marketing nav chrome
// with a minimal legal footer strip (the full A10 footer stays on `/`).
import type { Metadata } from "next";
import { HomeNavBar } from "@/components/home/HomeNavBar";
import { PageViewTracker } from "@/components/home/PageViewTracker";
import { ScalarApiReference } from "@/components/docs/ScalarApiReference";

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
      <main className="flex-1">
        <ScalarApiReference />
      </main>
      {/* Minimal footer strip — verbatim legal line only (parity canon). */}
      <footer className="border-t border-border px-6 py-4 text-caption text-text-2">
        <div className="mx-auto max-w-[1080px]">
          <span>
            ©{" "}
            <a
              href="https://cuesoft.io"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-text"
            >
              Cuesoft Inc.
            </a>{" "}
            2026. Apparule.{" "}
            <a
              href="https://cuelabs.cuesoft.io"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-text"
            >
              CueLABS™ Division
            </a>
            .{" "}
            <a
              href="https://github.com/cuesoftinc/apparule/blob/main/LICENSE"
              target="_blank"
              rel="noopener noreferrer"
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
