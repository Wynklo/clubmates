"use client";

import { useFormStatus } from "react-dom";
import { signOut } from "@/app/auth/actions";
import { buttonClasses } from "@/components/ui/button";

function SignOutSubmit() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" className={buttonClasses("secondary")} disabled={pending}>
      {pending ? "Signing out..." : "Sign Out"}
    </button>
  );
}

export function SignOutButton() {
  return (
    <form action={signOut}>
      <SignOutSubmit />
    </form>
  );
}
