import { z } from "zod";

const EMAIL_MESSAGE = "Enter a valid email address.";
const AGE_MESSAGE = "Please confirm that you are 18 or older.";

const emailField = z
  .string()
  .trim()
  .toLowerCase()
  .max(254, EMAIL_MESSAGE)
  .email(EMAIL_MESSAGE);

const passwordField = z
  .string()
  .min(8, "Use at least 8 characters.")
  .max(72, "Use a password of 72 characters or fewer.");

export const loginSchema = z.object({
  email: emailField,
  password: z.string().min(1, "Enter your password.").max(72, "Enter your password."),
});

export const signupSchema = z
  .object({
    fullName: z
      .string()
      .trim()
      .min(2, "Please enter your name.")
      .max(100, "Name must be 100 characters or fewer."),
    email: emailField,
    password: passwordField,
    confirmPassword: z.string().min(1, "Confirm your password."),
    is18Plus: z.boolean().refine((value) => value === true, {
      message: AGE_MESSAGE,
    }),
  })
  .refine((value) => value.password === value.confirmPassword, {
    message: "Passwords do not match.",
    path: ["confirmPassword"],
  });

export const forgotPasswordSchema = z.object({
  email: emailField,
});

export const updatePasswordSchema = z
  .object({
    password: passwordField,
    confirmPassword: z.string().min(1, "Confirm your password."),
  })
  .refine((value) => value.password === value.confirmPassword, {
    message: "Passwords do not match.",
    path: ["confirmPassword"],
  });

export type LoginInput = z.input<typeof loginSchema>;
export type SignupInput = z.input<typeof signupSchema>;
export type ForgotPasswordInput = z.input<typeof forgotPasswordSchema>;
export type UpdatePasswordInput = z.input<typeof updatePasswordSchema>;
