import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseEnv } from "@/lib/supabase/env";

const pausedAuthPaths = ["/login", "/signup", "/forgot-password", "/auth/callback"];

function isPausedAuthPath(path: string) {
  return (
    pausedAuthPaths.includes(path) ||
    path === "/account" ||
    path.startsWith("/account/")
  );
}

function redirectHome(request: NextRequest) {
  const url = request.nextUrl.clone();
  url.pathname = "/";
  url.search = "";
  return NextResponse.redirect(url);
}

export async function proxy(request: NextRequest) {
  const env = getSupabaseEnv();
  const path = request.nextUrl.pathname;

  if (path === "/robots.txt" || path === "/sitemap.xml") {
    return NextResponse.next();
  }

  if (isPausedAuthPath(path)) {
    return redirectHome(request);
  }

  if (!env) {
    return NextResponse.next();
  }

  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(env.url, env.key, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet, headers) {
        cookiesToSet.forEach(({ name, value }) => {
          request.cookies.set(name, value);
        });
        supabaseResponse = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => {
          supabaseResponse.cookies.set(name, value, options);
        });
        Object.entries(headers).forEach(([key, value]) => {
          supabaseResponse.headers.set(key, value);
        });
      },
    },
  });

  try {
    await supabase.auth.getClaims();
  } catch {
    // Session refresh is best-effort while sign-in is paused.
  }

  return supabaseResponse;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
