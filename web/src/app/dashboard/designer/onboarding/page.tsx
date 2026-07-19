// B8 — Designer onboarding & KYC (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { OnboardingView } from "@/components/dashboard/onboarding/OnboardingView";

export const metadata: Metadata = {
  title: "Become a designer — Apparule",
};

export default function DesignerOnboardingPage() {
  return <OnboardingView />;
}
