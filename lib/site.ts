import type { Metadata } from "next";

export const siteUrl = "https://www.clubmates.in";

export const siteName = "Clubmates";

export const defaultTitle = "Clubmates — Find Your People. Own the Night.";

export const defaultDescription =
  "Don't wait for the group chat. Find people who want the same kind of night you do, then go together. Clubmates is social nightlife, not dating.";

type PageMeta = {
  title?: string;
  description: string;
  path: `/${string}` | "/";
  index?: boolean;
};

export function pageMetadata({ title, description, path, index = true }: PageMeta): Metadata {
  const canonical = path === "/" ? siteUrl : `${siteUrl}${path}`;
  const socialTitle = title ? `${title} | ${siteName}` : defaultTitle;

  return {
    title: title ? title : { absolute: defaultTitle },
    description,
    alternates: { canonical },
    robots: index
      ? { index: true, follow: true }
      : { index: false, follow: false, nocache: true },
    openGraph: {
      title: socialTitle,
      description,
      url: canonical,
      siteName,
      locale: "en_IN",
      type: "website",
      images: [{ url: "/opengraph-image", width: 1200, height: 630, alt: defaultTitle }],
    },
    twitter: {
      card: "summary_large_image",
      title: socialTitle,
      description,
      images: ["/opengraph-image"],
    },
  };
}
