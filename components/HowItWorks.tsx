"use client";

import { useEffect, useRef, useState } from "react";
import { AvatarFace } from "@/components/Avatar";
import { arjun, maya } from "@/components/people";
import { Section } from "@/components/Section";
import styles from "./HowItWorks.module.css";

const steps = [
  {
    number: "01",
    title: "Find",
    body: "Find people heading out.",
  },
  {
    number: "02",
    title: "Meet",
    body: "Connect when it makes sense.",
  },
  {
    number: "03",
    title: "Go together",
    body: "Make the night happen.",
  },
] as const;

function StageVisual({ index }: { index: number }) {
  if (index === 0) {
    return (
      <div className="flex items-center gap-14 sm:gap-16">
        <AvatarFace person={maya} className="pointer-events-none size-11" />
        <AvatarFace person={arjun} className="pointer-events-none size-11" />
      </div>
    );
  }

  if (index === 1) {
    return (
      <div className="flex items-center gap-4">
        <AvatarFace person={maya} className="pointer-events-none size-11" />
        <span className="text-xs leading-none text-aubergine" aria-hidden="true">
          ✦
        </span>
        <AvatarFace person={arjun} className="pointer-events-none size-11" />
      </div>
    );
  }

  return (
    <div className="flex -space-x-3">
      <AvatarFace person={maya} className="pointer-events-none size-11" />
      <AvatarFace person={arjun} className="pointer-events-none size-11" />
    </div>
  );
}

export function HowItWorks() {
  const stepsRef = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const node = stepsRef.current;
    if (!node) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        setShown(true);
        observer.disconnect();
      },
      { threshold: 0.3 },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  return (
    <Section id="how-it-works">
      <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">The night</p>
      <h2 className="mt-4 max-w-3xl text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl">
        How it works
      </h2>
      <p className="mt-5 max-w-lg text-base leading-7 text-stone">
        Find someone who wants the same night. From there, it&apos;s simple.
      </p>

      <div ref={stepsRef} className={`mt-16 lg:mt-24 ${shown ? styles.shown : ""}`}>
        <div className="grid gap-y-20 lg:grid-cols-3 lg:gap-x-12">
          {steps.map((step, index) => (
            <article
              key={step.number}
              className={`flex flex-col items-center text-center ${styles.stage}`}
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <p className="text-sm leading-5 font-medium tracking-[0.18em] text-aubergine">{step.number}</p>
              <h3 className="mt-3 text-3xl leading-none font-medium tracking-tight">{step.title}</h3>
              <div className="mt-10 flex h-11 items-center justify-center">
                <StageVisual index={index} />
              </div>
              <p className="mt-10 max-w-[17rem] text-base leading-7 text-stone">{step.body}</p>
            </article>
          ))}
        </div>
      </div>

      <p className="mt-20 text-center font-serif text-2xl leading-snug font-medium tracking-[-0.03em] sm:mt-28 sm:text-3xl">
        Find. Meet. Go together. <span className="text-aubergine">✦</span>
      </p>
    </Section>
  );
}
