import type { Metadata } from "next";
import Link from "next/link";
import { buttonClasses } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Page not found",
  robots: { index: false, follow: false },
};

export default function NotFound() {
  return (
    <section className="px-5 py-24 sm:px-8 sm:py-32">
      <div className="mx-auto w-full max-w-xl">
        <h1 className="text-4xl font-medium tracking-[-0.04em] sm:text-5xl">Page not found</h1>
        <p className="mt-4 text-base leading-7 text-stone">That page is not on Clubmates.</p>
        <Link href="/" className={`${buttonClasses("primary")} mt-8`}>
          Back to Clubmates
        </Link>
      </div>
    </section>
  );
}
