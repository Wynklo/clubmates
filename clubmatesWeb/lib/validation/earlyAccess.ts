import { z } from "zod";

export const EARLY_ACCESS_DUPLICATE_MESSAGE =
  "Looks like you're already on the list.";

export const EARLY_ACCESS_ERROR_MESSAGE =
  "Something went wrong. Please try again.";

export const EARLY_ACCESS_RATE_LIMIT_MESSAGE =
  "Too many attempts from this network. Please wait a little while and try again.";

export const EARLY_ACCESS_CLOSED_MESSAGE =
  "Early access is full for now. We'll open more spots soon.";

const NAME_MESSAGE = "Please enter your name.";
const CITY_MESSAGE = "Please enter your city.";
const EMAIL_MESSAGE = "Enter a valid email address.";
const PHONE_MESSAGE = "Enter a valid phone number.";
const INSTAGRAM_MESSAGE = "Enter a valid Instagram username.";
const AGE_MESSAGE = "Please confirm that you are 18 or older.";
const REFERRAL_MESSAGE = "Please keep this under 200 characters.";

export function normalizePhone(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.replace(/[\s().-]/g, "");
}

export function normalizeInstagram(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) return null;

  const fromUrl = trimmed.match(
    /(?:https?:\/\/)?(?:www\.)?instagram\.com\/([A-Za-z0-9._]+)/i,
  );
  let handle = fromUrl?.[1] ?? trimmed.replace(/^@+/, "");
  handle = handle.split(/[/?#]/)[0]?.trim() ?? "";

  return handle || null;
}

export const earlyAccessSchema = z.object({
  fullName: z
    .string()
    .trim()
    .min(2, NAME_MESSAGE)
    .max(100, "Name must be 100 characters or fewer."),
  email: z
    .string()
    .trim()
    .toLowerCase()
    .max(254, EMAIL_MESSAGE)
    .email(EMAIL_MESSAGE),
  phone: z
    .string()
    .max(32, PHONE_MESSAGE)
    .transform(normalizePhone)
    .refine((value) => value === null || /^\+?[0-9]{8,15}$/.test(value), {
      message: PHONE_MESSAGE,
    }),
  city: z
    .string()
    .trim()
    .min(2, CITY_MESSAGE)
    .max(100, "City must be 100 characters or fewer."),
  instagram: z
    .string()
    .max(120, INSTAGRAM_MESSAGE)
    .transform(normalizeInstagram)
    .refine(
      (value) => value === null || /^[A-Za-z0-9._]{1,30}$/.test(value),
      { message: INSTAGRAM_MESSAGE },
    ),
  referralSource: z
    .string()
    .max(200, REFERRAL_MESSAGE)
    .transform((value) => {
      const trimmed = value.trim();
      return trimmed ? trimmed : null;
    }),
  is18Plus: z.boolean().refine((value) => value === true, {
    message: AGE_MESSAGE,
  }),
});

export type EarlyAccessInput = z.input<typeof earlyAccessSchema>;
export type EarlyAccessData = z.output<typeof earlyAccessSchema>;

export function isDuplicateRegistration(error: {
  code?: string;
  message?: string;
  details?: string;
}) {
  if (error.code === "23505") return true;
  const blob = `${error.message ?? ""} ${error.details ?? ""}`.toLowerCase();
  return blob.includes("duplicate key") || blob.includes("unique constraint");
}
