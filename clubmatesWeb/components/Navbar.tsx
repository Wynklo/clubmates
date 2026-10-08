"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Logo } from "@/components/Logo";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";

const linkClass = "text-sm leading-none transition-colors duration-300 sm:text-[15px]";
const earlyAccessButton =
  "inline-flex h-9 cursor-pointer items-center justify-center rounded-full px-3.5 text-[13px] font-semibold tracking-tight whitespace-nowrap transition-colors duration-300 sm:h-10 sm:px-4 sm:text-sm";

let applyTone: ((onDark: boolean) => void) | null = null;
let toneWatch: (() => void) | null = null;

function headerIsOnDark() {
  const header = document.querySelector("header");
  if (!header) return false;
  const edge = header.getBoundingClientRect().bottom;
  return [...document.querySelectorAll<HTMLElement>("[data-header='dark']")].some((section) => {
    const rect = section.getBoundingClientRect();
    return rect.top < edge && rect.bottom > 0;
  });
}

function watchHeaderTone() {
  if (toneWatch || typeof window === "undefined") return;
  const update = () => applyTone?.(headerIsOnDark());
  update();
  window.addEventListener("scroll", update, { passive: true, capture: true });
  window.addEventListener("resize", update);
  toneWatch = () => {
    window.removeEventListener("scroll", update, { capture: true });
    window.removeEventListener("resize", update);
    toneWatch = null;
  };
}

export function Navbar() {
  const { open } = useEarlyAccess();
  const [onDark, setOnDark] = useState(false);

  applyTone = (dark) => setOnDark((current) => (current === dark ? current : dark));
  if (typeof window !== "undefined") watchHeaderTone();

  useEffect(() => {
    watchHeaderTone();
    applyTone?.(headerIsOnDark());
    return () => {
      if (toneWatch) toneWatch();
    };
  }, []);

  return (
    <header
      className={`sticky top-0 z-40 border-b px-5 transition-colors duration-300 sm:px-8 ${
        onDark ? "border-paper/15 bg-ink text-paper" : "border-ink/10 bg-paper text-ink"
      }`}
    >
      <div className="mx-auto grid h-[4.5rem] w-full max-w-6xl grid-cols-[1fr_auto_1fr] items-center gap-x-3">
        <nav aria-label="Primary">
          <Link
            href="/#how-it-works"
            className={`${linkClass} ${onDark ? "text-paper hover:text-blush" : "text-ink hover:text-aubergine"}`}
          >
            How It Works
          </Link>
        </nav>

        <Link href="/" className="rounded-md" aria-label="Clubmates home">
          <Logo priority onDark={onDark} />
        </Link>

        <div className="justify-self-end">
          <button
            type="button"
            className={`${earlyAccessButton} ${
              onDark ? "bg-blush text-ink hover:bg-paper" : "bg-aubergine text-paper hover:bg-ink"
            }`}
            onClick={open}
          >
            Early Access
          </button>
        </div>
      </div>
    </header>
  );
}
