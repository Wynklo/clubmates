import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { SignOutButton } from "@/components/auth/SignOutButton";
import { getAuthenticatedUser } from "@/lib/auth/session";

export const metadata: Metadata = {
  title: "Account",
  robots: { index: false, follow: false },
};

export const dynamic = "force-dynamic";

export default async function AccountPage() {
  const user = await getAuthenticatedUser();
  if (!user) redirect("/login");

  return (
    <section className="px-5 py-20 sm:px-8 sm:py-28">
      <div className="mx-auto w-full max-w-xl">
        <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">Account</p>
        <h1 className="mt-4 text-4xl font-medium tracking-[-0.04em] sm:text-6xl">
          Welcome to Clubmates
        </h1>
        <p className="mt-10 text-sm text-stone">Signed in as:</p>
        <p className="mt-2 text-lg">{user.email ?? "your account"}</p>
        <div className="mt-10">
          <SignOutButton />
        </div>
      </div>
    </section>
  );
}
