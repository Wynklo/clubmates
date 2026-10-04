import type { Metadata } from "next";
import { Manrope } from "next/font/google";
import { Footer } from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { Providers } from "@/components/Providers";
import "./globals.css";

const manrope = Manrope({
  subsets: ["latin"],
  variable: "--font-manrope",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://clubmates.in"),
  title: {
    default: "Clubmates | Find Your People. Own the Night.",
    template: "%s | Clubmates",
  },
  description:
    "Find people heading out, make plans together and experience nightlife with Clubmates.",
  applicationName: "Clubmates",
  openGraph: {
    title: "Clubmates | Find Your People. Own the Night.",
    description:
      "Find people heading out, make plans together and experience nightlife with Clubmates.",
    url: "https://clubmates.in",
    siteName: "Clubmates",
    locale: "en_IN",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Clubmates | Find Your People. Own the Night.",
    description:
      "Find people heading out, make plans together and experience nightlife with Clubmates.",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${manrope.variable} h-full antialiased`} data-scroll-behavior="smooth">
      <body className="min-h-full overflow-x-clip bg-paper font-sans text-ink">
        <Providers>
          <a className="skip-link" href="#main">
            Skip to content
          </a>
          <Navbar />
          <div id="content">
            <main id="main">{children}</main>
            <Footer />
          </div>
        </Providers>
      </body>
    </html>
  );
}
