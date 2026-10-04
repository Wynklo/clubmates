"use client";

import { AnimatePresence, motion } from "framer-motion";
import { X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { EarlyAccessForm } from "@/components/EarlyAccessForm";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import { useDialogBehavior } from "@/components/useDialogBehavior";

export function EarlyAccessModal() {
  const { isOpen, close } = useEarlyAccess();

  return (
    <AnimatePresence>
      {isOpen ? <EarlyAccessDialog key="early-access" onClose={close} /> : null}
    </AnimatePresence>
  );
}

function EarlyAccessDialog({ onClose }: { onClose: () => void }) {
  const dialogRef = useRef<HTMLDivElement>(null);
  const [completed, setCompleted] = useState(false);
  useDialogBehavior(true, dialogRef, onClose);

  useEffect(() => {
    const site = document.getElementById("site");
    if (!site) return;
    site.setAttribute("inert", "");
    return () => site.removeAttribute("inert");
  }, []);

  return (
    <motion.div
      className="fixed inset-0 z-50 flex bg-black/75 sm:items-center sm:justify-center sm:p-6"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onClick={onClose}
    >
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="early-access-title"
        tabIndex={-1}
        className="relative flex h-full w-full flex-col overflow-hidden bg-paper text-ink outline-none sm:h-auto sm:max-h-[min(88vh,820px)] sm:max-w-lg sm:rounded-[28px] sm:border sm:border-ink/10"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex shrink-0 items-start justify-between gap-4 px-5 pt-5 sm:px-8 sm:pt-8">
          <div>
            {completed ? (
              <h2 id="early-access-title" className="sr-only">
                You&apos;re on the list
              </h2>
            ) : (
              <>
                <h2
                  id="early-access-title"
                  data-initial-focus
                  tabIndex={-1}
                  className="text-3xl font-medium tracking-[-0.04em] outline-none"
                >
                  Get early access
                </h2>
                <p className="mt-2 text-sm leading-6 text-stone">
                  No account required. Confirm you are 18 or older to join the list.
                </p>
              </>
            )}
          </div>
          <button
            type="button"
            className="inline-flex h-11 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full text-ink"
            aria-label="Close early access"
            data-initial-focus={completed ? true : undefined}
            onClick={onClose}
          >
            <X aria-hidden="true" />
          </button>
        </div>
        <div className="mt-6 overflow-y-auto px-5 pb-[max(1.25rem,env(safe-area-inset-bottom))] sm:px-8 sm:pb-8">
          <EarlyAccessForm
            idPrefix="modal"
            onBack={onClose}
            onSuccess={() => setCompleted(true)}
          />
        </div>
      </div>
    </motion.div>
  );
}
