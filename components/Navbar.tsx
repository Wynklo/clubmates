"use client";

import { Menu, X } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { Logo } from "@/components/Logo";
import { useDialogBehavior } from "@/components/useDialogBehavior";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import { buttonClasses } from "@/components/ui/button";

const links = [
  { href: "/#how-it-works", label: "How It Works" },
  { href: "/#why-clubmates", label: "Why Clubmates" },
  { href: "/#safety", label: "Safety" },
  { href: "/#security", label: "Security" },
];

export function Navbar() {
  const pathname = usePathname();
  const { open } = useEarlyAccess();
  const [menuPath, setMenuPath] = useState<string | null>(null);
  const [scrolled, setScrolled] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const menuOpen = menuPath === pathname;

  useDialogBehavior(menuOpen, menuRef, () => setMenuPath(null));

  useEffect(() => {
    const content = document.getElementById("content");
    if (!content) return;
    if (menuOpen) content.setAttribute("inert", "");
    else content.removeAttribute("inert");
    return () => content.removeAttribute("inert");
  }, [menuOpen]);

  useEffect(() => {
    const media = window.matchMedia("(min-width: 1024px)");
    const closeOnDesktop = () => {
      if (media.matches) setMenuPath(null);
    };
    media.addEventListener("change", closeOnDesktop);
    return () => media.removeEventListener("change", closeOnDesktop);
  }, []);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  function openEarlyAccess() {
    setMenuPath(null);
    open();
  }

  return (
    <header
      className={`sticky top-0 z-40 border-b transition-colors ${
        scrolled && !menuOpen
          ? "border-ink/10 bg-paper/90 backdrop-blur-md"
          : "border-transparent bg-transparent"
      }`}
    >
      <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-5 sm:px-8 lg:h-[4.5rem]">
        <Link href="/" className="rounded-md text-ink" aria-label="Clubmates home">
          <Logo priority />
        </Link>

        <nav className="hidden items-center gap-8 lg:flex" aria-label="Primary">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="text-sm text-stone transition-colors hover:text-ink"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-2 lg:flex">
          <Link href="/login" className={buttonClasses("quiet")}>
            Sign In
          </Link>
          <button type="button" className={buttonClasses("primary")} onClick={open}>
            Get Early Access
          </button>
        </div>

        <button
          type="button"
          className="inline-flex h-11 w-11 cursor-pointer items-center justify-center rounded-full text-ink lg:hidden"
          aria-expanded={menuOpen}
          aria-controls="mobile-navigation"
          aria-label={menuOpen ? "Close menu" : "Open menu"}
          onClick={() => setMenuPath((current) => (current === pathname ? null : pathname))}
        >
          {menuOpen ? <X aria-hidden="true" /> : <Menu aria-hidden="true" />}
        </button>
      </div>

      {menuOpen
        ? createPortal(
            <div
              ref={menuRef}
              id="mobile-navigation"
              role="dialog"
              aria-modal="true"
              aria-label="Menu"
              tabIndex={-1}
              className="fixed inset-0 z-[80] flex flex-col overflow-y-auto bg-paper px-5 pt-4 pb-[max(1.25rem,env(safe-area-inset-bottom))] text-ink outline-none"
            >
              <div className="flex h-16 items-center justify-between">
                <Link
                  href="/"
                  className="text-ink"
                  aria-label="Clubmates home"
                  onClick={() => setMenuPath(null)}
                >
                  <Logo />
                </Link>
                <button
                  type="button"
                  data-initial-focus
                  className="inline-flex h-11 w-11 cursor-pointer items-center justify-center rounded-full"
                  aria-label="Close menu"
                  onClick={() => setMenuPath(null)}
                >
                  <X aria-hidden="true" />
                </button>
              </div>
              <nav className="mt-8 flex flex-col" aria-label="Mobile">
                {links.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    className="border-b border-ink/10 py-5 text-3xl font-medium tracking-tight"
                    onClick={() => setMenuPath(null)}
                  >
                    {link.label}
                  </Link>
                ))}
                <Link
                  href="/login"
                  className="border-b border-ink/10 py-5 text-3xl font-medium tracking-tight"
                  onClick={() => setMenuPath(null)}
                >
                  Sign In
                </Link>
              </nav>
              <button
                type="button"
                className={`${buttonClasses("primary")} mt-10 w-full`}
                onClick={openEarlyAccess}
              >
                Get Early Access
              </button>
            </div>,
            document.body,
          )
        : null}
    </header>
  );
}
