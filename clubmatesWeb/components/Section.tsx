import type { ReactNode } from "react";

type SectionProps = {
  id?: string;
  children: ReactNode;
  className?: string;
  headerTone?: "dark";
};

export function Section({ id, children, className = "", headerTone }: SectionProps) {
  return (
    <section
      id={id}
      data-header={headerTone}
      className={`border-t border-ink/10 px-5 py-20 sm:px-8 md:py-28 ${className}`}
    >
      <div className="mx-auto w-full max-w-6xl">{children}</div>
    </section>
  );
}
