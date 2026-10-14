import type { ReactNode } from "react";

function AppleMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="size-5 shrink-0">
      <path
        fill="currentColor"
        d="M16.4 12.6c0-2.2 1.8-3.3 1.9-3.3-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.6.8-3.3.8-.7 0-1.7-.8-2.9-.8-1.5 0-2.8.9-3.6 2.2-1.5 2.7-.4 6.6 1.1 8.8.7 1.1 1.6 2.3 2.7 2.2 1.1 0 1.5-.7 2.8-.7s1.7.7 2.9.7 1.9-1.1 2.6-2.2c.8-1.2 1.2-2.4 1.2-2.5s-2.2-.8-2.2-3.5zM14.6 6.5c.6-.7 1-1.7.9-2.7-.9.1-1.9.6-2.5 1.3-.6.7-1.1 1.7-.9 2.6 1 .1 1.9-.5 2.5-1.2z"
      />
    </svg>
  );
}

function PlayMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="size-5 shrink-0">
      <path
        fill="currentColor"
        d="M4.5 3.4v17.2c0 .7.8 1.1 1.4.7l13.2-8.6c.6-.4.6-1.1 0-1.5L5.9 2.7c-.6-.4-1.4 0-1.4.7z"
      />
    </svg>
  );
}

function StoreMark({
  name,
  icon,
}: {
  name: string;
  icon: ReactNode;
}) {
  return (
    <span className="inline-flex items-center gap-2.5 rounded-2xl border border-ink/15 bg-white px-3 py-2 text-ink">
      {icon}
      <span className="text-left leading-tight">
        <span className="block text-[10px] font-medium tracking-wide text-stone uppercase">
          Available soon
        </span>
        <span className="block text-sm font-semibold">{name}</span>
      </span>
    </span>
  );
}

export function StoreSoon({ onDark = false }: { onDark?: boolean }) {
  return (
    <div className={onDark ? "mt-8" : "mt-6"}>
      <p className={onDark ? "text-sm leading-5 text-paper/70" : "text-sm leading-5 text-stone"}>
        Android and iOS apps will be available soon.
      </p>
      <div className="mt-3 flex flex-wrap gap-2">
        <StoreMark name="Google Play" icon={<PlayMark />} />
        <StoreMark name="App Store" icon={<AppleMark />} />
      </div>
    </div>
  );
}
