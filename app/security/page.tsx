import type { Metadata } from "next";
import { Security } from "@/components/Security";

export const metadata: Metadata = {
  title: "Security",
  description:
    "How Clubmates handles early access and account information: encrypted connections, limited keys, and no public profiles.",
  alternates: { canonical: "https://clubmates.in/security" },
};

export default function SecurityPage() {
  return <Security title="h1" />;
}
