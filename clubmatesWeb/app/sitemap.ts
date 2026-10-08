import type { MetadataRoute } from "next";
import { siteUrl } from "@/lib/site";

const paths = ["/", "/early-access", "/security"] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  return paths.map((path) => ({
    url: path === "/" ? siteUrl : `${siteUrl}${path}`,
  }));
}
