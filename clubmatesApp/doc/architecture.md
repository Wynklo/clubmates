# Clubmates

Nightlife social product. Not a dating app. Two apps, one database.

| Folder | What it is |
|---|---|
| `clubmatesApp` | Flutter phone app. Tabs: Club, Invites, Mates, Profile. |
| `clubmatesWeb` | Next.js marketing site. Early access only. Login and account routes redirect home. |
| `clubmatesApp/supabase/migrations` | The database. Do not re-run the Phase 1 file. Later files are additive. |

`doc/clubmates_supabase_schema_v1.sql` and `doc/implementationplan.md` are the original plan. They are not the live schema. `doc/keys.md` says which key is used where.

## Phone app

```
lib/main.dart                 starts Flutter and Supabase
lib/app/clubmates_app.dart    route switch
lib/state/app_model.dart      screen state (AppModel, AppScope)
lib/data/                     Supabase reads and writes
lib/screens/                  onboarding, club, people, profile
lib/ui/                       shared widgets, icons, glass tab bar
lib/theme/theme.dart          colors and type
design/app-icon/              home-screen icon masters (not shipped in the binary)
assets/photos/                splash mark and sample portraits
ios/Runner/Assets.xcassets    the icons actually installed on the phone
```

`AppModel` is the only place screens change route or call the repository. `ClubmatesRepository` is the only place that talks to Supabase. Screens do not open the database themselves.

When `SUPABASE_URL` and `SUPABASE_ANON_KEY` are compiled in, the app uses the live project. Without those defines it stays on this phone and does not write the database.

## What is real, and what stays on the phone

Real: phone sign-in for the test numbers, profile, photos, discovery, pass, invite, mates, blocks, account deletion, and the signed-in person's coordinates. Club asks for location and stores latitude and longitude on that person's profile. Those columns are not readable by other people.

On this phone only: chat lines, the “Delivered” label, notification toggles, nightlife interest chips, and the further-than-10 km dialog. There is no payment, no push delivery, and no message delivery to the other person.

Deleting an account removes photo files through the Storage API, then deletes the auth user. Related rows cascade. It does not touch early-access registrations.

## Website

```
app/                  pages and the early-access API
components/           page sections
lib/db/postgres.ts    server-only database connection
lib/earlyAccess/      registration, cap, and validation
lib/security/         rate limit and client IP
```

The site does not ship the phone app’s service role or database password. Automatic Vercel deploys are off.
