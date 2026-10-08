import type { ZodError } from "zod";

export function fieldErrorsFromZod(error: ZodError): Record<string, string> {
  const flattened = error.flatten().fieldErrors;
  const fieldErrors: Record<string, string> = {};

  for (const [key, messages] of Object.entries(flattened)) {
    const list = Array.isArray(messages) ? messages : [];
    const message = list.find((item) => typeof item === "string" && item.length > 0);
    if (message) fieldErrors[key] = message;
  }

  return fieldErrors;
}
