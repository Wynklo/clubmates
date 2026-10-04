import Link from "next/link";
import { Logo } from "@/components/Logo";

export function Footer() {
  return (
    <footer className="border-t border-ink/10 px-5 py-14 sm:px-8">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-10 md:flex-row md:items-end md:justify-between">
        <div>
          <Logo />
          <p className="mt-4 max-w-xs text-sm leading-6 text-stone">
            Find Your People. Own the Night.
          </p>
        </div>
        <nav className="flex flex-wrap gap-x-6 gap-y-3 text-sm text-stone" aria-label="Footer">
          <Link href="/#how-it-works" className="hover:text-ink">
            How It Works
          </Link>
          <Link href="/#why-clubmates" className="hover:text-ink">
            Why Clubmates
          </Link>
          <Link href="/#safety" className="hover:text-ink">
            Safety
          </Link>
          <Link href="/security" className="hover:text-ink">
            Security
          </Link>
          <Link href="/early-access" className="hover:text-ink">
            Early Access
          </Link>
          <Link href="/login" className="hover:text-ink">
            Sign In
          </Link>
        </nav>
      </div>
      <div className="mx-auto mt-12 w-full max-w-6xl text-sm text-mute">
        © 2026 Clubmates
      </div>
    </footer>
  );
}
