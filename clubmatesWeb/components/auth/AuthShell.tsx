import type { ReactNode } from "react";

type AuthShellProps = {
  title: string;
  lede?: string;
  children: ReactNode;
  footer?: ReactNode;
};

export function AuthShell({ title, lede, children, footer }: AuthShellProps) {
  return (
    <section className="px-5 py-16 sm:px-8 sm:py-24">
      <div className="mx-auto w-full max-w-md">
        <h1 className="text-4xl font-medium tracking-[-0.04em] sm:text-5xl">{title}</h1>
        {lede ? <p className="mt-4 text-base leading-7 text-stone">{lede}</p> : null}
        <div className="mt-10">{children}</div>
        {footer ? <div className="mt-8 text-sm leading-6 text-stone">{footer}</div> : null}
      </div>
    </section>
  );
}
