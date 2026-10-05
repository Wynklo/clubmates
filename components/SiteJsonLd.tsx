import { defaultDescription, siteName, siteUrl } from "@/lib/site";

const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      name: siteName,
      url: siteUrl,
      logo: `${siteUrl}/icon.png`,
      description: defaultDescription,
    },
    {
      "@type": "WebSite",
      name: siteName,
      url: siteUrl,
      description: defaultDescription,
      inLanguage: "en",
    },
  ],
};

export function SiteJsonLd() {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
    />
  );
}
