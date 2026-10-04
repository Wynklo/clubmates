import Link from "next/link";
import { Logo } from "@/components/Logo";

export function Footer() {
  return (
    <footer className="bg-ink px-5 py-14 text-paper sm:px-8">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-10 md:flex-row md:items-end md:justify-between">
        <div>
          <Logo onDark />
          <p className="mt-4 max-w-xs text-sm leading-6 text-blush">
            Find Your People. Own the Night.
          </p>
        </div>
        <nav className="flex flex-wrap gap-x-6 gap-y-3 text-sm text-paper/75" aria-label="Footer">
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
          <Link href="/early-access" className="hover:text-paper">
            Early Access
          </Link>
          <Link href="/login" className="hover:text-paper">
            Sign In
          </Link>
        </nav>
      </div>
      <div className="mx-auto mt-12 w-full max-w-6xl text-sm text-paper/50">
        © 2026 Clubmates
      </div>
    </footer>
  );
}
