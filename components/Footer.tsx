import Link from "next/link";
import { Logo } from "@/components/Logo";

export function Footer() {
  return (
    <footer className="bg-ink px-5 py-16 text-paper sm:px-8">
      <div className="mx-auto grid w-full max-w-6xl gap-12 md:grid-cols-[minmax(0,1.4fr)_auto_auto] md:gap-16">
        <div>
          <Logo onDark />
          <p className="mt-4 max-w-xs text-sm leading-6 text-blush">
            Find Your People. Own the Night.
          </p>
        </div>
        <nav className="flex flex-col gap-3 text-sm text-paper/75" aria-label="Footer">
          <p className="text-xs font-medium tracking-[0.16em] text-paper/45 uppercase">Explore</p>
          <Link href="/#how-it-works" className="hover:text-paper">
            How It Works
          </Link>
          <Link href="/#why-clubmates" className="hover:text-paper">
            Why Clubmates
          </Link>
          <Link href="/#safety" className="hover:text-paper">
            Safety
          </Link>
          <Link href="/security" className="hover:text-paper">
            Security
          </Link>
        </nav>
        <nav className="flex flex-col gap-3 text-sm text-paper/75" aria-label="Join">
          <p className="text-xs font-medium tracking-[0.16em] text-paper/45 uppercase">Join</p>
          <Link href="/early-access" className="hover:text-paper">
            Early Access
          </Link>
        </nav>
      </div>
      <div className="mx-auto mt-14 w-full max-w-6xl border-t border-paper/15 pt-6 text-sm text-paper/50">
        © 2026 Clubmates
      </div>
    </footer>
  );
}
