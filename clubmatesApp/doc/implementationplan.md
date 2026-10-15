# Clubmates — Implementation Plan for Cursor

**Purpose:** Give Cursor a phased, testable plan to implement the first working Clubmates draft without overengineering it.  
**Read first:** `architecture.md`  
**Approach:** Inspect the repository before changing it. Preserve the current framework and design. Do not replace existing working code or apply a large schema blindly.

---

## 0. Cursor operating instructions

1. Inspect the repository and report the existing framework, folder layout, routing, state management, Supabase package/version, environment setup and existing database migrations.
2. Do not assume Flutter or React. Continue with the framework already present. Ask only if the repository genuinely does not identify a stack.
3. Before edits, summarize the implementation approach and list any conflicts between the repository and this plan.
4. Make small, reviewable changes. Do not rewrite the whole application in one pass.
5. Keep visual design aligned with Clubmates: premium, minimal, nightlife/social discovery, not a dating-app clone. Main tabs are **Club, Invites, Mates, Profile**.
6. Never put `service_role` keys, provider secrets or privileged tokens in client code.
7. Do not implement payments, Aadhaar/PAN KYC, face verification, chat, push notifications, Kafka, Redis or a standalone Go server in Phase 1 unless the repository already contains a required implementation and the owner approves retaining it.
8. Use SQL migrations in source control. Do not silently run destructive migrations against a shared/production project.
9. After each phase, run the available formatter, lint, type checks and tests. Report what ran and what could not run.
10. Do not mark a task complete if it is only mocked. Clearly label mock data and TODOs.

## 1. Phase 0 — Repository discovery and plan

### Tasks
- [ ] Inspect repository and identify framework/runtime.
- [ ] Inspect existing screens and current navigation.
- [ ] Locate current Supabase client initialization and environment variables.
- [ ] Inspect current database migrations/schema and existing RLS policies if available.
- [ ] Identify existing UI components, theme/tokens and state management.
- [ ] Identify test setup and build commands.
- [ ] Produce a short report before substantial edits.

### Deliverable
A concise repository assessment and a file-by-file implementation plan that preserves existing work.

### Acceptance criteria
- No code has been needlessly rewritten.
- The actual framework and Supabase SDK version are known.
- Any existing schema conflicts are documented.

## 2. Phase 1 — Minimum secure foundation

### Scope
- Supabase Auth integration.
- Seven core app tables.
- RLS, constraints, indexes and Storage policies.
- Client repository layer.
- Profile onboarding and profile editing.
- Profile photo upload.
- Club discovery, Pass, Invite, Invites tab, Mates and basic blocking.
- Minimal error/loading/empty states.

### 2.1 Database migration

Create versioned migration file(s) in the repository's established migration location. If Supabase CLI is in use, follow its migration conventions.

Initial app tables:
1. `profiles`
2. `user_private`
3. `profile_photos`
4. `passes`
5. `invites`
6. `mates`
7. `user_blocks`

Use Supabase `auth.users` as the identity source. Do not create a custom password/user-auth table.

### Required database behavior
- [ ] `profiles.id` references `auth.users.id` with appropriate delete behavior.
- [ ] `user_private.user_id` references the authenticated user and DOB is private.
- [ ] `profile_photos` stores Storage paths, not image bytes.
- [ ] Unique `(user_id, target_user_id)` for passes.
- [ ] Prevent self-invites and self-passes.
- [ ] Prevent duplicate pending invites in the same direction.
- [ ] Store Mate pairs in canonical order and enforce unique pair.
- [ ] RLS enabled on every client-exposed table.
- [ ] `is_verified`, `account_status`, and photo moderation status are not client-editable.
- [ ] Invite creation/response uses secure RPC functions.
- [ ] All functions that use `SECURITY DEFINER` set a safe `search_path`, verify `auth.uid()`, and have explicit execute grants.
- [ ] Private Storage bucket named `profile-photos`, with user-scoped object paths.
- [ ] Storage read policy matches the intended product behavior. Test approved photos, owner access, blocks and suspended profiles.
- [ ] Do not add preferences, interests, notifications, messages, verification or payment tables in Phase 1 unless a screen genuinely requires one.

### Important schema review before applying
Do not copy the earlier full V1 SQL into an existing project without reviewing it. It is a starting draft, not a certified production migration. In particular:
- Check that `SECURITY DEFINER` RPC functions cannot be used to bypass profile/account restrictions.
- Check table grants as well as RLS.
- Ensure clients cannot alter server-managed fields through updates or inserts.
- Test how a user can create their initial profile and private row without exposing another user's data.
- Make sure photo metadata `storage_path` exactly matches the user's Storage object path.
- Make account deletion clean up Storage objects, not just database rows.
- Add a secure pass RPC if direct inserts cannot enforce all discovery rules needed.
- Add rate limiting before public launch.

### Deliverable
A reviewed migration plus local instructions to apply it to a development Supabase project.

## 3. Phase 1 — Client data layer

Create feature repositories/services using the existing language and conventions. The UI should call these repositories; repositories use the Supabase SDK directly. Do not add an HTTP backend for normal CRUD.

Suggested responsibilities:
- `AuthRepository`: sign in/up/out, session and auth state.
- `ProfileRepository`: fetch/update own profile; fetch safe profile details.
- `PhotoRepository`: upload/delete photo and manage metadata.
- `DiscoveryRepository`: call the discovery query/RPC and save a pass.
- `InviteRepository`: send invite via RPC; read incoming/outgoing invites; accept/decline via RPC.
- `MateRepository`: list Mate connections.
- `BlockRepository`: block/unblock and list own blocks.

Use the current stack's naming conventions; names above are logical examples, not a requirement to create a class for every item.

### Direct client-to-Supabase calls allowed
- Supabase Auth operations.
- Read/update own `profiles`.
- Read/update own `user_private` onboarding fields.
- Upload/delete own photo objects in Storage.
- Insert/update/delete own photo metadata within RLS restrictions; moderation remains server-managed.
- Read safe discovery candidates.
- Create/read own passes, subject to RLS/constraints.
- Read invites where the authenticated user is sender or receiver.
- Read own Mate connections.
- Block/unblock from the current user's account.
- Read/update own non-sensitive settings as implemented.

### Use database RPC rather than direct table writes for
- Sending an invite if validation and notification side effects must be consistent.
- Accepting/declining an invite.
- Creating a Mate connection.
- Any operation that needs multiple database changes to succeed or fail as a single transaction.

The UI may call `supabase.rpc(...)` directly through the SDK. RPC does not mean a separate server is needed.

## 4. Phase 1 — Screen implementation

Preserve the existing visual system and component conventions. Do not generate a new design system unless none exists.

### Authentication/onboarding
- [ ] Auth entry screen and sign-in/sign-up flow supported by the configured Supabase Auth method.
- [ ] Loading, success, invalid input, network error and session-expired states.
- [ ] Create `profiles` and `user_private` after authentication.
- [ ] Handle partial onboarding safely: users can resume if they close the app.
- [ ] Never expose phone number or DOB in public profile responses.

### Profile
- [ ] Edit display name, bio, city and other Phase 1 fields.
- [ ] Upload and reorder photos.
- [ ] Show moderation/pending state if moderation is enabled.
- [ ] Show verified badge only from a trusted server-managed value; in development use an explicitly marked test fixture rather than allowing a client to set the production flag.

### Club (discovery)
- [ ] One profile at a time, matching the current product direction.
- [ ] Display approved photos and safe profile fields only.
- [ ] Pass action.
- [ ] Invite action.
- [ ] Loading, no-more-profiles, retry and error states.
- [ ] Exclude self, passed profiles, blocked pairs, existing Mate connections and invite states according to product rules.
- [ ] Paginate or limit results; do not fetch every profile.

### Invites
- [ ] List incoming pending invites.
- [ ] Allow accept/decline only for the receiver.
- [ ] Refresh the list after a successful response.
- [ ] Empty state for no incoming invites.

### Mates
- [ ] List active Mate connections.
- [ ] Empty state if there are no connections.
- [ ] No chat in Phase 1 unless explicitly approved.

### Profile/settings
- [ ] View/edit own profile.
- [ ] Toggle discoverability if included.
- [ ] Block/unblock user.
- [ ] Sign out.
- [ ] Account deletion entry point must explain what happens; if full deletion is not implemented, do not falsely claim it is complete.

## 5. Phase 1 — Trusted backend boundary

### No separate Go backend for ordinary app CRUD
Do not create a Go service just to forward client requests to Supabase. RLS + direct SDK calls + database RPC are sufficient for the first draft.

### What requires trusted code when introduced
- Payment/boost purchase creation, verification, refunds and payment webhooks.
- Identity verification provider calls, Aadhaar/PAN flows and face/liveness verification.
- Signed provider webhooks and idempotent event processing.
- Admin-only moderation, suspensions and changing server-managed verification status.
- Scheduled data retention, provider deletion and full account-deletion orchestration where required.

### Language choice
- Preferred general backend language: **Go**.
- Phase 1 should not require a Go service unless there is an immediate server-side integration requirement.
- If a Go service becomes necessary, use a small HTTP service deployed to a managed container platform such as Google Cloud Run. Validate the Supabase JWT, authorize every operation, keep secrets in the hosting secret manager, and use a least-privilege database/API design.
- For Supabase-native provider integrations, Supabase Edge Functions (TypeScript/Deno) are also appropriate and require less infrastructure. Choose one trusted execution path per integration; do not build duplicate Go and Edge Function implementations.

## 6. Security test plan — required

Use two separate authenticated test accounts, User A and User B.

- [ ] A cannot read B's `user_private` row.
- [ ] A cannot edit B's profile or photo metadata.
- [ ] A cannot upload, overwrite or delete B's Storage objects.
- [ ] A cannot set `is_verified`, suspend/unsuspend an account or approve a photo.
- [ ] A cannot read an invite unrelated to A.
- [ ] A cannot accept an invite addressed to B.
- [ ] Duplicate pending invite is rejected.
- [ ] Self-invite and self-pass are rejected.
- [ ] A block prevents discovery/invites in both directions.
- [ ] Accepting an invite creates exactly one Mate pair.
- [ ] A non-Mate cannot read conversations/messages if those tables exist; chat is out of Phase 1.
- [ ] Anonymous users cannot read private data.
- [ ] Discovery returns age only, never date of birth or phone.
- [ ] Deleted account's photos are cleaned up by the documented deletion process.
- [ ] No secret appears in source code, client bundles, logs or committed environment files.

## 7. Quality gates

- [ ] Format and lint pass.
- [ ] Static/type checks pass.
- [ ] Existing tests pass.
- [ ] Add tests for repositories and critical UI states where the current test framework supports them.
- [ ] Add SQL/RLS integration tests or a repeatable manual test checklist.
- [ ] No secrets are committed.
- [ ] Build succeeds for the existing target platform.
- [ ] README documents environment setup, migrations, Storage bucket setup and run commands.

## 8. Suggested implementation order

1. Repository assessment.
2. Supabase client/config verification.
3. Database migration and RLS review.
4. Auth + onboarding.
5. Profile read/update.
6. Photo Storage upload and metadata.
7. Discovery query and Pass.
8. Invite RPCs and the Invites tab.
9. Mate list.
10. Blocking and settings.
11. Security tests and cleanup.
12. Document deferred features.

Do not start payment or identity verification integration until the core discovery/invite flow works and the owner explicitly starts that phase.

## 9. Cursor completion report

At the end of each phase, report:
- Files created/changed.
- Database migration(s) added.
- Commands/tests run and their results.
- Manual Supabase dashboard steps still required.
- Security assumptions and known limitations.
- Deferred work.
- Any operation that is mocked rather than implemented.

**Start now with Phase 0 only. Inspect the repository, report what you found, and then proceed in small phases.**
