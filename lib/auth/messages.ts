export const AUTH_GENERIC_ERROR = "Something went wrong. Please try again.";

export const AUTH_INVALID_LOGIN = "Email or password is incorrect.";

export const AUTH_EMAIL_UNCONFIRMED =
  "Confirm your email before signing in. Check your inbox for the link.";

export const AUTH_ALREADY_REGISTERED =
  "An account with this email already exists. Try signing in.";

export const AUTH_RATE_LIMIT =
  "Too many attempts. Please wait a moment and try again.";

export const AUTH_WEAK_PASSWORD = "Please choose a stronger password.";

export const AUTH_LINK_EXPIRED =
  "That link is invalid or has expired. Try again.";

export function mapAuthError(message: string) {
  const normalized = message.toLowerCase();

  if (
    normalized.includes("invalid login") ||
    normalized.includes("invalid credentials")
  ) {
    return AUTH_INVALID_LOGIN;
  }

  if (normalized.includes("email not confirmed")) {
    return AUTH_EMAIL_UNCONFIRMED;
  }

  if (
    normalized.includes("already registered") ||
    normalized.includes("already been registered") ||
    normalized.includes("user already")
  ) {
    return AUTH_ALREADY_REGISTERED;
  }

  if (normalized.includes("rate limit") || normalized.includes("too many")) {
    return AUTH_RATE_LIMIT;
  }

  if (normalized.includes("password")) {
    return AUTH_WEAK_PASSWORD;
  }

  return AUTH_GENERIC_ERROR;
}
