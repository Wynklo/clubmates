"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import { buttonClasses } from "@/components/ui/button";

const item = {
  hidden: { opacity: 0, y: 18 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.55, ease: [0.22, 1, 0.36, 1] as const },
  },
};

export function Hero() {
  const { open } = useEarlyAccess();

  return (
    <section className="hero-glow px-5 pb-20 pt-14 sm:px-8 sm:pt-20 lg:pb-32 lg:pt-28">
      <div className="mx-auto grid w-full max-w-6xl items-end gap-16 lg:grid-cols-[minmax(0,1.2fr)_minmax(16rem,0.7fr)]">
        <motion.div
          initial="hidden"
          animate="show"
          variants={{ show: { transition: { staggerChildren: 0.08 } } }}
        >
          <motion.p variants={item} className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">
            Nightlife, together
          </motion.p>
          <motion.h1
            variants={item}
            className="mt-6 max-w-[12em] text-[2rem] leading-[0.98] font-medium tracking-[-0.045em] min-[375px]:text-[2.35rem] min-[430px]:text-[2.75rem] sm:max-w-none sm:text-6xl lg:text-7xl xl:text-[5.4rem]"
          >
            <span className="block">Find Your People.</span>
            <span className="block">Own the Night.</span>
          </motion.h1>
          <motion.p variants={item} className="mt-8 max-w-xl text-base leading-7 text-stone sm:text-lg sm:leading-8">
            Going out shouldn&apos;t depend on who&apos;s free.
          </motion.p>
          <motion.p variants={item} className="mt-3 max-w-xl text-base leading-7 text-stone sm:text-lg sm:leading-8">
            Find people heading out, make plans together and turn a solo night into a shared one.
          </motion.p>
          <motion.div variants={item} className="mt-10 flex flex-col gap-3 sm:flex-row">
            <button type="button" className={`${buttonClasses("primary")} w-full sm:w-auto`} onClick={open}>
              Get Early Access
            </button>
            <Link href="/#how-it-works" className={`${buttonClasses("secondary")} w-full sm:w-auto`}>
              See How It Works
            </Link>
          </motion.div>
        </motion.div>

        <motion.div
          className="hidden border-t border-ink/15 pt-8 lg:block"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.25 }}
        >
          <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">The night</p>
          <ol className="mt-6">
            {["Discover", "Connect", "Go Out"].map((step, index) => (
              <li
                key={step}
                className="flex items-baseline justify-between gap-6 border-b border-ink/10 py-5"
              >
                <span className="font-serif text-3xl font-medium tracking-tight">{step}</span>
                <span className="text-sm text-mute">0{index + 1}</span>
              </li>
            ))}
          </ol>
        </motion.div>
      </div>
    </section>
  );
}
