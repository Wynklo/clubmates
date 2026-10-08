import type { ReactNode } from "react";

export const inputClassName =
  "h-12 w-full rounded-2xl border border-ink/15 bg-paper px-4 text-base text-ink outline-none transition-colors placeholder:text-mute focus:border-aubergine disabled:opacity-60";

type FieldProps = {
  id: string;
  label: string;
  required?: boolean;
  optional?: boolean;
  error?: string;
  children: ReactNode;
};

export function Field({ id, label, required, optional, error, children }: FieldProps) {
  return (
    <div>
      <label htmlFor={id} className="mb-2 block text-sm font-medium text-ink">
        {label}
        {required ? (
          <span aria-hidden="true" className="text-aubergine">
            {" "}
            *
          </span>
        ) : null}
        {optional ? <span className="font-normal text-stone"> (optional)</span> : null}
      </label>
      {children}
      {error ? (
        <p id={`${id}-error`} className="mt-2 text-sm text-error" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}

export function describedBy(id: string, error?: string) {
  return error ? `${id}-error` : undefined;
}
