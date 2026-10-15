# Keys: where they go, and when

Do not commit real values. `clubmatesApp/dart_defines.json` and `clubmatesWeb/.env.local` stay on your machine. Copy the shapes below and paste the values from the Supabase dashboard or Vercel. Never paste the database password or the service-role key into the app, a chat, or GitHub.

The publishable key is the only key the phone app and the website browser are allowed to hold. It is public by design. It is still not a substitute for the secret keys below.

## Phone app

File: `clubmatesApp/dart_defines.json` (gitignored).

Used only when you build or run the app:

```bash
flutter run -d <device> --dart-define-from-file=dart_defines.json
flutter build ios --release --dart-define-from-file=dart_defines.json
```

A build without this file does not talk to the database. Signup then stays on the phone and disappears when the app is reinstalled.

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<publishable key>",
  "DEV_LOGIN_PASSWORD": "<local test password>"
}
```

| Name | Dashboard label | When |
|---|---|---|
| `SUPABASE_URL` | Project URL | Every build that should save profiles. |
| `SUPABASE_ANON_KEY` | Publishable key (`sb_publishable_...`) | Same builds. This is the anon key. |
| `DEV_LOGIN_PASSWORD` | Not in the dashboard. It is the password of the local test accounts only. | Debug builds only (`flutter run`). A tester can then sign in with code `111111`. Release builds ignore it and always use Firebase phone sign-in. |

`String.fromEnvironment` reads these at compile time. Changing the file does nothing until the next full build. Hot reload will not pick them up.

### Firebase files

Phone sign-in and Android push use Firebase. Download both files from the Firebase console (Project settings, Your apps) and keep them out of git:

| File | Goes in | Without it |
|---|---|---|
| `google-services.json` | `clubmatesApp/android/app/` | The app builds and runs, but a release build cannot sign in by phone and gets no pushes. |
| `GoogleService-Info.plist` | `clubmatesApp/ios/Runner/` | Same on iOS. Its `REVERSED_CLIENT_ID` must also be a URL scheme in `Info.plist` for the reCAPTCHA step. |

These files identify the Firebase project. They are not server secrets, but they stay local like the other config.

## Supabase Edge Functions

Code: `clubmatesApp/supabase/functions/`. Both are deployed with JWT checks off because the app uses a publishable key; each checks its own caller.

| Function | Called by | Checks |
|---|---|---|
| `firebase-session` | The app after Firebase accepts the SMS code | The Firebase ID token, against Google's keys and the project ID. Rate-limited per phone and per IP. |
| `notify` | The `invites` trigger through `pg_net` | The `x-notify-secret` header. |

Secrets, set with `npx supabase secrets set` (never in the app or git):

| Name | Value |
|---|---|
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_SERVICE_ACCOUNT` | Full JSON of the Firebase service account key, used only to send pushes |
| `NOTIFY_SECRET` | Same value as the Vault secret `notify_secret` |

Vault (database) holds `notify_url` and `notify_secret` for the trigger. `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided to functions by Supabase.

## Website

File: `clubmatesWeb/.env.local`, created from `clubmatesWeb/.env.example`. On Vercel, set the same names in the project environment. Do not turn on automatic deploys if the site should stay on the last manual release.

| Name | Who can see it | When |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Browser | The site needs the Supabase client. |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Browser | Same moment. Publishable key only. |
| `DATABASE_URL` | Server only | Early-access signup. The server uses it to count rows and stop at 500. Never prefix it with `NEXT_PUBLIC_`. Never put it in the phone app. |
| `GOOGLE_SITE_VERIFICATION` | Server, optional | Only after Google Search Console gives you a token. Leave it empty until then. |

## Never put these in git or in the app

| Key | Where it belongs | When |
|---|---|---|
| Service-role key (`sb_secret_...` or the JWT service role) | Supabase dashboard, or a server secret manager if a trusted backend is added later | Privileged jobs only. The phone app and the website browser must not have it. |
| Database password inside `DATABASE_URL` | `clubmatesWeb/.env.local` and the Vercel server environment | Server-side early access only. |
| Firebase service account JSON | Supabase Edge Function secret `FIREBASE_SERVICE_ACCOUNT` only | Sending pushes. Keep the downloaded file outside the repo and delete it once the secret is set. |

`clubmatesWeb/certs/supabase-root-2021.crt` is a public certificate used to verify the database connection. It is not a private key.

## What was checked

`dart_defines.json`, `.env.local`, the database URL, and the test password are not in git history. Nothing sensitive had to be removed from GitHub.
