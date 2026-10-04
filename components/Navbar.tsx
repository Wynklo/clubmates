"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Logo } from "@/components/Logo";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";

const linkClass = "text-sm leading-none transition-colors duration-300 sm:text-[15px]";
const earlyAccessButton =
  "inline-flex h-9 cursor-pointer items-center justify-center rounded-full px-3.5 text-[13px] font-semibold tracking-tight whitespace-nowrap transition-colors duration-300 sm:h-10 sm:px-4 sm:text-sm";

export function Navbar() {
  const { open } = useEarlyAccess();
  const [onDark, setOnDark] = useState(false);

  useEffect(() => {
    const update = () => {
      const header = document.querySelector("header");
      if (!header) return;

      const y = header.getBoundingClientRect().height / 2;
      const hit = document.elementsFromPoint(window.innerWidth / 2, y).find((node) => !header.contains(node));
      let dark = false;
      let node: Element | null = hit ?? null;

      while (node) {
        if (node instanceof HTMLElement && node.dataset.header === "dark") {
          dark = true;
          break;
        }
        node = node.parentElement;
      }

      setOnDark((current) => (current === dark ? current : dark));
    };

    const onScroll = () => update();

    update();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
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
