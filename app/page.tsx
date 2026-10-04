import type { Metadata } from "next";
import { EarlyAccessSection } from "@/components/EarlyAccessSection";
import { Hero } from "@/components/Hero";
import { HowItWorks } from "@/components/HowItWorks";
import { Positioning } from "@/components/Positioning";
import { Problem } from "@/components/Problem";
import { Safety } from "@/components/Safety";
import { Security } from "@/components/Security";

export const metadata: Metadata = {
  alternates: {
    canonical: "https://clubmates.in",
  },
};

export default function HomePage() {
  return (
    <>
      <Hero />
      <Problem />
      <HowItWorks />
      <Positioning />
      <Safety />
      <Security />
      <EarlyAccessSection />
    </>
  );
}
