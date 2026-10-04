"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { buttonClasses } from "@/components/ui/button";
import { describedBy, Field, inputClassName } from "@/components/ui/field";
import {
  EARLY_ACCESS_CLOSED_MESSAGE,
  EARLY_ACCESS_DUPLICATE_MESSAGE,
  EARLY_ACCESS_ERROR_MESSAGE,
  EARLY_ACCESS_RATE_LIMIT_MESSAGE,
  earlyAccessSchema,
  type EarlyAccessInput,
} from "@/lib/validation/earlyAccess";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

type Status = "idle" | "submitting" | "success";

type Banner = { tone: "error" | "duplicate"; message: string } | null;

type EarlyAccessResponse =
  | { ok: true }
  | { ok: false; code: "duplicate"; message: string }
  | { ok: false; code: "validation"; fieldErrors?: Record<string, string> }
  | { ok: false; code: "error" | "rate_limited" | "closed"; message?: string };

const emptyValues: EarlyAccessInput = {
  fullName: "",
  email: "",
  phone: "",
  city: "",
  instagram: "",
  referralSource: "",
  is18Plus: false,
};

type EarlyAccessFormProps = {
  idPrefix: string;
  onBack?: () => void;
  onSuccess?: () => void;
};

export function EarlyAccessForm({ idPrefix, onBack, onSuccess }: EarlyAccessFormProps) {
  const [values, setValues] = useState<EarlyAccessInput>(emptyValues);
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [serverFieldErrors, setServerFieldErrors] = useState<Record<string, string>>({});
  const [banner, setBanner] = useState<Banner>(null);
  const [status, setStatus] = useState<Status>("idle");
  const [closed, setClosed] = useState(false);
  const [honeypot, setHoneypot] = useState("");
  const submittingRef = useRef(false);
  const successRef = useRef<HTMLHeadingElement>(null);
  const onSuccessRef = useRef(onSuccess);

  useEffect(() => {
    onSuccessRef.current = onSuccess;
  }, [onSuccess]);

  useEffect(() => {
    let cancelled = false;
    fetch("/api/early-access", { cache: "no-store" })
      .then((response) => response.json())
      .then((payload: { open?: boolean } | null) => {
        if (!cancelled && payload && payload.open === false) setClosed(true);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (status !== "success") return;
    successRef.current?.focus();
    onSuccessRef.current?.();
  }, [status]);

  const parsed = earlyAccessSchema.safeParse(values);
  const clientErrors = parsed.success ? {} : fieldErrorsFromZod(parsed.error);

  function errorFor(field: keyof EarlyAccessInput) {
    if (!touched[field] && !submitAttempted) return undefined;
    return serverFieldErrors[field] || clientErrors[field];
  }

  function update<K extends keyof EarlyAccessInput>(field: K, value: EarlyAccessInput[K]) {
    setValues((current) => ({ ...current, [field]: value }));
    setServerFieldErrors((current) => {
      if (!current[field]) return current;
      const next = { ...current };
      delete next[field];
      return next;
    });
    if (field === "email") setBanner(null);
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submittingRef.current) return;

    setSubmitAttempted(true);
    setBanner(null);

    const result = earlyAccessSchema.safeParse(values);
    if (!result.success) return;

    submittingRef.current = true;
    setStatus("submitting");
    let succeeded = false;

    try {
      const response = await fetch("/api/early-access", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...values, cm_hp: honeypot }),
        cache: "no-store",
      });

      const payload = (await response.json().catch(() => null)) as EarlyAccessResponse | null;

      if (payload && payload.ok) {
        succeeded = true;
        setStatus("success");
        return;
      }

      if (payload && !payload.ok && payload.code === "duplicate") {
        setBanner({ tone: "duplicate", message: payload.message || EARLY_ACCESS_DUPLICATE_MESSAGE });
      } else if (payload && !payload.ok && payload.code === "validation" && payload.fieldErrors) {
        setServerFieldErrors(payload.fieldErrors);
      } else if (payload && !payload.ok && payload.code === "rate_limited") {
        setBanner({ tone: "error", message: payload.message || EARLY_ACCESS_RATE_LIMIT_MESSAGE });
      } else if (payload && !payload.ok && payload.code === "closed") {
        setClosed(true);
      } else {
        setBanner({ tone: "error", message: EARLY_ACCESS_ERROR_MESSAGE });
      }

      setStatus("idle");
    } catch {
      setBanner({ tone: "error", message: EARLY_ACCESS_ERROR_MESSAGE });
      setStatus("idle");
    } finally {
      if (!succeeded) submittingRef.current = false;
    }
  }

  if (closed) {
    return (
      <p role="status" className="text-base leading-7 text-stone">
        {EARLY_ACCESS_CLOSED_MESSAGE}
      </p>
    );
  }

  if (status === "success") {
    return (
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35 }}
        role="status"
      >
        <h2
          ref={successRef}
          tabIndex={-1}
          className="text-4xl font-medium tracking-[-0.04em] outline-none"
        >
          You&apos;re on the list.
        </h2>
        <p className="mt-4 text-lg">Welcome to Clubmates.</p>
        <p className="mt-3 max-w-md text-base leading-7 text-stone">
          We&apos;ll let you know when early access opens in your city.
        </p>
        {onBack ? (
          <button type="button" className={`${buttonClasses("primary")} mt-8`} onClick={onBack}>
            Back to Clubmates
          </button>
        ) : (
          <Link href="/" className={`${buttonClasses("primary")} mt-8`}>
            Back to Clubmates
          </Link>
        )}
      </motion.div>
    );
  }

  const submitting = status === "submitting";
  const nameError = errorFor("fullName");
  const emailError = errorFor("email");
  const phoneError = errorFor("phone");
  const cityError = errorFor("city");
  const instagramError = errorFor("instagram");
  const referralError = errorFor("referralSource");
  const ageError = errorFor("is18Plus");
  const nameId = `${idPrefix}-name`;
  const emailId = `${idPrefix}-email`;
  const phoneId = `${idPrefix}-phone`;
  const cityId = `${idPrefix}-city`;
  const instagramId = `${idPrefix}-instagram`;
  const referralId = `${idPrefix}-referral`;
  const ageId = `${idPrefix}-age`;

  return (
    <form className="relative space-y-5" onSubmit={onSubmit} noValidate aria-busy={submitting}>
      <div aria-hidden="true" className="absolute -left-[9999px] h-px w-px overflow-hidden">
        <label htmlFor={`${idPrefix}-hp`}>Fax</label>
        <input
          id={`${idPrefix}-hp`}
          name="cm_hp"
          type="text"
          tabIndex={-1}
          autoComplete="off"
          value={honeypot}
          onChange={(event) => setHoneypot(event.target.value)}
        />
      </div>
      {banner ? (
        <p
          role={banner.tone === "error" ? "alert" : "status"}
          className={`rounded-2xl border px-4 py-3 text-sm leading-6 ${
            banner.tone === "duplicate"
              ? "border-ink/15 bg-blush text-ink"
              : "border-coral/40 bg-coral/10 text-error"
          }`}
        >
          {banner.message}
        </p>
      ) : null}

      <Field id={nameId} label="Full name" required error={nameError}>
        <input
          id={nameId}
          name="fullName"
          type="text"
          autoComplete="name"
          autoCapitalize="words"
          required
          disabled={submitting}
          value={values.fullName}
          aria-invalid={Boolean(nameError)}
          aria-describedby={describedBy(nameId, nameError)}
          className={inputClassName}
          onBlur={() => setTouched((current) => ({ ...current, fullName: true }))}
          onChange={(event) => update("fullName", event.target.value)}
        />
      </Field>

      <Field id={emailId} label="Email" required error={emailError}>
        <input
          id={emailId}
          name="email"
          type="email"
          inputMode="email"
          autoComplete="email"
          autoCapitalize="none"
          spellCheck={false}
          required
          disabled={submitting}
          value={values.email}
          aria-invalid={Boolean(emailError)}
          aria-describedby={describedBy(emailId, emailError)}
          className={inputClassName}
          onBlur={() => setTouched((current) => ({ ...current, email: true }))}
          onChange={(event) => update("email", event.target.value)}
        />
      </Field>

      <Field id={phoneId} label="Phone" optional error={phoneError}>
        <input
          id={phoneId}
          name="phone"
          type="tel"
          inputMode="tel"
          autoComplete="tel"
          disabled={submitting}
          value={values.phone}
          aria-invalid={Boolean(phoneError)}
          aria-describedby={describedBy(phoneId, phoneError)}
          className={inputClassName}
          onBlur={() => setTouched((current) => ({ ...current, phone: true }))}
          onChange={(event) => update("phone", event.target.value)}
        />
      </Field>

      <Field id={cityId} label="City" required error={cityError}>
        <input
          id={cityId}
          name="city"
          type="text"
          autoComplete="address-level2"
          autoCapitalize="words"
          required
          disabled={submitting}
          value={values.city}
          aria-invalid={Boolean(cityError)}
          aria-describedby={describedBy(cityId, cityError)}
          className={inputClassName}
          onBlur={() => setTouched((current) => ({ ...current, city: true }))}
          onChange={(event) => update("city", event.target.value)}
        />
      </Field>

      <Field id={instagramId} label="Instagram" optional error={instagramError}>
        <input
          id={instagramId}
          name="instagram"
          type="text"
          autoCapitalize="none"
          autoCorrect="off"
          spellCheck={false}
          placeholder="username"
          disabled={submitting}
          value={values.instagram}
          aria-invalid={Boolean(instagramError)}
          aria-describedby={describedBy(instagramId, instagramError)}
          className={inputClassName}
          onBlur={() => setTouched((current) => ({ ...current, instagram: true }))}
          onChange={(event) => update("instagram", event.target.value)}
        />
      </Field>

      <Field id={referralId} label="How did you hear about us?" optional error={referralError}>
        <input
          id={referralId}
          name="referralSource"
          type="text"
          autoComplete="off"
          disabled={submitting}
          value={values.referralSource}
          aria-invalid={Boolean(referralError)}
          aria-describedby={describedBy(referralId, referralError)}
          className={inputClassName}
          onBlur={() => setTouched((current) => ({ ...current, referralSource: true }))}
          onChange={(event) => update("referralSource", event.target.value)}
        />
      </Field>

      <div>
        <label htmlFor={ageId} className="flex items-start gap-3 text-sm leading-6 text-ink">
          <input
            id={ageId}
            name="is18Plus"
            type="checkbox"
            required
            disabled={submitting}
            checked={values.is18Plus}
            aria-invalid={Boolean(ageError)}
            aria-describedby={describedBy(ageId, ageError)}
            className="mt-0.5 h-5 w-5 shrink-0 accent-aubergine"
            onBlur={() => setTouched((current) => ({ ...current, is18Plus: true }))}
            onChange={(event) => update("is18Plus", event.target.checked)}
          />
          <span>I confirm that I am 18 years of age or older.</span>
        </label>
        {ageError ? (
          <p id={`${ageId}-error`} className="mt-2 text-sm text-error" role="alert">
            {ageError}
          </p>
        ) : null}
      </div>

      <button type="submit" className={`${buttonClasses("primary")} w-full`} disabled={submitting}>
        {submitting ? "Joining..." : "Join Early Access"}
      </button>
    </form>
  );
}
