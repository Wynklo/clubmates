import Link from "next/link";
import { Logo } from "@/components/Logo";

export function Footer() {
  return (
    <footer data-header="dark" className="border-t border-paper/15 bg-ink px-5 py-20 text-paper sm:px-8 md:py-24">
      <div className="mx-auto grid w-full max-w-6xl gap-14 md:grid-cols-[minmax(0,1.5fr)_auto_auto] md:gap-20">
        <div>
          <Logo onDark />
          <p className="mt-5 max-w-xs font-serif text-lg leading-snug">
            Find your people.
            <span className="block text-paper">Own the night.</span>
          </p>
        </div>
        <nav className="flex flex-col gap-3 text-sm leading-6 text-paper/80" aria-label="Footer">
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
            Privacy
          </Link>
        </nav>
        <nav className="flex flex-col gap-3 text-sm leading-6 text-paper/80" aria-label="Join">
          <p className="text-xs font-medium tracking-[0.16em] text-paper/45 uppercase">Join</p>
          <Link href="/early-access" className="hover:text-paper">
            Early Access
          </Link>
        </nav>
      </div>
      <div className="mx-auto mt-16 w-full max-w-6xl border-t border-paper/15 pt-6 text-sm text-paper/55">
        © 2026 Clubmates
      </div>
    </footer>
  );
}
