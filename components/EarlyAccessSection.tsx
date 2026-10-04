"use client";

import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import { Section } from "@/components/Section";
import { buttonClasses } from "@/components/ui/button";

export function EarlyAccessSection() {
  const { open } = useEarlyAccess();

  return (
    <Section id="early-access" className="border-ink/10 bg-blush">
      <div className="max-w-2xl">
        <h2 className="text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl">
          Be first when your city opens.
        </h2>
        <p className="mt-6 text-lg leading-8 text-stone">
          Leave your name and email. No password and no account. We&apos;ll tell you when early access
          starts where you are.
        </p>
        <button type="button" className={`${buttonClasses("primary")} mt-10`} onClick={open}>
          Get Early Access
        </button>
      </div>
    </Section>
  );
}
