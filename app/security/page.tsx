import type { Metadata } from "next";
import { Security } from "@/components/Security";
import { pageMetadata } from "@/lib/site";

export const metadata: Metadata = pageMetadata({
  title: "Security",
  description:
    "Early access details travel over an encrypted connection and are stored encrypted at rest. Clubmates does not publish a profile, plans, or location.",
  path: "/security",
});

export default function SecurityPage() {
  return <Security title="h1" />;
}
