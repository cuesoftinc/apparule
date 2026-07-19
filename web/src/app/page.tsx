// Public home page `/` — pages.md Part A (A1–A10 + A4b/A7b/A7c/A9b/A9c),
// composed from registry component instances against the enriched Figma
// landing (frame 186:2). Views render-only: demo data flows from
// controllers/home-demo, the star count from the github repository, and
// analytics through the controller transport.
import type { Metadata } from "next";
import { HomeFooter } from "@/components/ui/HomeFooter";
import { CommunitySection } from "@/components/home/CommunitySection";
import { ComparisonSection } from "@/components/home/ComparisonSection";
import { DesignersSection } from "@/components/home/DesignersSection";
import { DevelopersSection } from "@/components/home/DevelopersSection";
import { FaqSection } from "@/components/home/FaqSection";
import { FeatureDeepDives } from "@/components/home/FeatureDeepDives";
import { FinalCtaBand } from "@/components/home/FinalCtaBand";
import { HeroSection } from "@/components/home/HeroSection";
import { HomeNavBar } from "@/components/home/HomeNavBar";
import { PageViewTracker } from "@/components/home/PageViewTracker";
import { SelfHostSection } from "@/components/home/SelfHostSection";
import { SmplSection } from "@/components/home/SmplSection";
import { StatBand } from "@/components/home/StatBand";
import { WalkthroughSection } from "@/components/home/WalkthroughSection";

// Hero copy is the canonical description (canvas 186:18/186:19).
const DESCRIPTION =
  "Apparule turns two phone photos into a complete, private body-measurement profile. Commission Lagos designers who sew to your measurements — no size charts, no guesswork.";

export const metadata: Metadata = {
  title: "Apparule — Two photos. A perfect fit.",
  description: DESCRIPTION,
  openGraph: {
    title: "Apparule — Two photos. A perfect fit.",
    description: DESCRIPTION,
    url: "https://apparule.cuesoft.io",
    siteName: "Apparule",
    type: "website",
  },
  twitter: {
    card: "summary",
    title: "Apparule — Two photos. A perfect fit.",
    description: DESCRIPTION,
  },
};

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-bg text-text">
      <PageViewTracker path="/" />
      <HomeNavBar />
      <main className="flex-1">
        <HeroSection />
        <StatBand />
        <WalkthroughSection />
        <FeatureDeepDives />
        <SmplSection />
        <DesignersSection />
        <DevelopersSection />
        <SelfHostSection />
        <ComparisonSection />
        <FaqSection />
        <CommunitySection />
        <FinalCtaBand />
      </main>
      <HomeFooter />
    </div>
  );
}
