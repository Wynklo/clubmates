"use client";

import { ArrowRight } from "lucide-react";
import { motion } from "framer-motion";
import Link from "next/link";
import { HeroNight } from "@/components/HeroNight";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import { buttonClasses } from "@/components/ui/button";

const faces = [
  { name: "Maya", skin: "#E7B89A", hair: "#2A211C", shirt: "#67295F" },
  { name: "Arun", skin: "#C68642", hair: "#1A1A1A", shirt: "#097270" },
  { name: "Leah", skin: "#F1C7A6", hair: "#6B3A2A", shirt: "#D45847" },
  { name: "Noah", skin: "#8D5524", hair: "#24160F", shirt: "#75457D" },
];

const item = {
  hidden: { opacity: 0, y: 18 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.55, ease: [0.22, 1, 0.36, 1] as const },
  },
};

function Portrait({
  person,
  className,
}: {
  person: (typeof faces)[number];
  className?: string;
}) {
  return (
    <svg viewBox="0 0 64 64" aria-hidden="true" className={className}>
      <circle cx="32" cy="32" r="32" fill={person.shirt} />
      <path d="M8 58c4-14 14-20 24-20s20 6 24 20" fill={person.skin} />
      <circle cx="32" cy="26" r="12" fill={person.skin} />
      <path d="M18 24c1-12 8-18 14-18s13 6 14 18c-4-3-8-4-14-4s-10 1-14 4z" fill={person.hair} />
    </svg>
  );
}

export function Hero() {
  const { open } = useEarlyAccess();

  return (
    <section className="hero-glow overflow-hidden px-5 pt-14 pb-16 sm:px-8 sm:pt-16 lg:pt-20 lg:pb-24">
      <div className="mx-auto grid w-full max-w-6xl items-center gap-14 lg:grid-cols-[minmax(0,11fr)_minmax(0,9fr)] lg:gap-10">
        <motion.div
          initial="hidden"
          animate="show"
          variants={{ show: { transition: { staggerChildren: 0.08 } } }}
        >
          <motion.p
            variants={item}
            className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase"
          >
            Nightlife, together
          </motion.p>
          <motion.h1
            variants={item}
            className="mt-5 max-w-[11em] text-[2.35rem] leading-[0.96] font-medium tracking-[-0.045em] sm:text-6xl lg:text-[4.35rem]"
          >
            <span className="block">Your night starts</span>
            <span className="block">with the right people.</span>
          </motion.h1>
          <motion.p variants={item} className="mt-6 max-w-md text-lg leading-8 text-stone">
            Don&apos;t wait for the group chat. Find people who want the same kind of night you do.
          </motion.p>
          <motion.div variants={item} className="mt-8 flex flex-col gap-3 sm:flex-row">
            <button type="button" className={`${buttonClasses("primary")} w-full sm:w-auto`} onClick={open}>
              Get Early Access
            </button>
            <Link href="/#how-it-works" className={`${buttonClasses("secondary")} w-full gap-2 sm:w-auto`}>
              How It Works
              <ArrowRight className="size-4 text-aubergine" aria-hidden="true" />
            </Link>
          </motion.div>
          <motion.div variants={item} className="mt-8 flex items-center gap-3">
            <div className="flex -space-x-2.5">
              {faces.map((person) => (
                <span
                  key={person.name}
                  className="inline-flex size-9 overflow-hidden rounded-full ring-2 ring-paper"
                >
                  <Portrait person={person} className="size-9" />
                </span>
              ))}
            </div>
            <p className="text-sm leading-5 text-stone">
              People heading out,
              <span className="block text-ink">not another group chat.</span>
            </p>
          </motion.div>
        </motion.div>

        <HeroNight />
      </div>
    </section>
  );
}
