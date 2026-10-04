"use client";

import { MotionConfig } from "framer-motion";
import type { ReactNode } from "react";
import { EarlyAccessModal } from "@/components/EarlyAccessModal";
import { EarlyAccessProvider } from "@/components/EarlyAccessProvider";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <MotionConfig reducedMotion="user">
      <EarlyAccessProvider>
        <div id="site">{children}</div>
        <EarlyAccessModal />
      </EarlyAccessProvider>
    </MotionConfig>
  );
}
