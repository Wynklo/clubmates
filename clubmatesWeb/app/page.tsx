import type { Metadata } from "next";
import { EarlyAccessSection } from "@/components/EarlyAccessSection";
import { Hero } from "@/components/Hero";
import { HowItWorks } from "@/components/HowItWorks";
import { Idea } from "@/components/Idea";
import { Positioning } from "@/components/Positioning";
import { Problem } from "@/components/Problem";
import { Trust } from "@/components/Trust";
import { defaultDescription, pageMetadata } from "@/lib/site";

export const metadata: Metadata = pageMetadata({
  description: defaultDescription,
  path: "/",
});

export default function HomePage() {
  return (
    <>
      <Hero />
      <Problem />
      <HowItWorks />
      <Positioning />
      <Idea />
      <Trust />
      <EarlyAccessSection />
    </>
  );
}
