import type { Metadata } from "next";
import { EarlyAccessForm } from "@/components/EarlyAccessForm";
import { pageMetadata } from "@/lib/site";

export const metadata: Metadata = pageMetadata({
  title: "Early access",
  description:
    "Join the Clubmates early access list and hear when nights start coming together in your city. No account or password. You must be 18 or older.",
  path: "/early-access",
});

export default function EarlyAccessPage() {
  return (
    <section className="px-5 py-16 sm:px-8 sm:py-24">
      <div className="mx-auto w-full max-w-md">
        <h1 className="text-4xl font-medium tracking-[-0.04em] sm:text-5xl">Get early access</h1>
        <p className="mt-4 text-base leading-7 text-stone">
          No password and no account. Confirm you are 18 or older to join the list.
        </p>
        <div className="mt-10">
          <EarlyAccessForm idPrefix="page" />
        </div>
      </div>
    </section>
  );
}
