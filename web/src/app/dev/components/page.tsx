import { notFound } from "next/navigation";
import { env } from "@/config/env";
import { ComponentGallery } from "./gallery";

// Dev-only component gallery for the stage QA loop — every §8.2/§8.2b
// web-relevant component in its variants. Hidden from production builds
// unless TEST_MODE (the QA loop runs against TEST_MODE builds).
export const metadata = { title: "Component gallery — Apparule dev" };

export default function DevComponentsPage() {
  if (process.env.NODE_ENV === "production" && !env.testMode) {
    notFound();
  }
  return <ComponentGallery />;
}
