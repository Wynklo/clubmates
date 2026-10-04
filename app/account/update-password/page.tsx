import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { UpdatePasswordForm } from "@/components/auth/UpdatePasswordForm";
import { getAuthenticatedUser } from "@/lib/auth/session";

export const metadata: Metadata = {
  title: "Update password",
  robots: { index: false, follow: false },
};

export const dynamic = "force-dynamic";

export default async function UpdatePasswordPage() {
  const user = await getAuthenticatedUser();
  if (!user) redirect("/login");

  return <UpdatePasswordForm />;
}
