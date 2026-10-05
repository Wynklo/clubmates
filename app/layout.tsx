import type { Metadata } from "next";
import { Inter, Lora } from "next/font/google";
import { Footer } from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { Providers } from "@/components/Providers";
import { SiteJsonLd } from "@/components/SiteJsonLd";
import { defaultDescription, defaultTitle, siteName, siteUrl } from "@/lib/site";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const lora = Lora({
  subsets: ["latin"],
  variable: "--font-lora",
  display: "swap",
});

export const viewport = {
  themeColor: "#FFFEFD",
};

const googleVerification = process.env.GOOGLE_SITE_VERIFICATION?.trim();

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: defaultTitle,
    template: `%s | ${siteName}`,
  },
  description: defaultDescription,
  applicationName: siteName,
  authors: [{ name: siteName, url: siteUrl }],
  creator: siteName,
  robots: { index: true, follow: true },
  openGraph: {
    title: defaultTitle,
    description: defaultDescription,
    url: siteUrl,
    siteName,
    locale: "en_IN",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: defaultTitle,
    description: defaultDescription,
  },
  ...(googleVerification ? { verification: { google: googleVerification } } : {}),
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${lora.variable} h-full antialiased`}
      data-scroll-behavior="smooth"
    >
      <body className="min-h-full overflow-x-clip bg-paper font-sans text-ink">
        <SiteJsonLd />
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
