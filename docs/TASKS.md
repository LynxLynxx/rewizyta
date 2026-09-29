# Rewizyta – Tasks

## Contents

- [M0 – Repository and design (done)](#m0--repository-and-design-done)
- [M1 – Local data layer](#m1--local-data-layer)
- [M2 – Clients](#m2--clients)
- [M3 – Visits and due list](#m3--visits-and-due-list)
- [M4 – Booking and Today](#m4--booking-and-today)
- [M5 – Backend and sync](#m5--backend-and-sync)
- [M6 – SMS reminders](#m6--sms-reminders)
- [M7 – Settings, onboarding and integrations](#m7--settings-onboarding-and-integrations)
- [M8 – Waitlist site and mailing](#m8--waitlist-site-and-mailing)
- [M9 – Product website](#m9--product-website)
- [V1 (after MVP ships)](#v1-after-mvp-ships)
- [Later](#later)

Milestones in build order. Each one is meant to be a working, testable slice.
Tick items as they land; add a short note when a decision changes.

## M0 – Repository and design (done)

- [x] Monorepo with Melos: `apps/mobile`, `packages/rewizyta_*`, `apps/waitlist`, `apps/website`, `supabase/`.
- [x] Stack switched to flutter_bloc + Equatable + manual get_it, layer-first packages (2026-09-28).
- [x] `leancode_lint` through one root `analysis_options.yaml`; `melos run layering` audit.
- [x] First vertical slice (`Client`) in every layer with tests, as the template for M1+.
- [x] Adapter interfaces + no-ops for analytics, crash reporting, push.
- [x] `README.md`, `CLAUDE.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/DATABASE.md`.
- [x] CI skeleton, keepalive workflow + `keepalive()` migration, MIT licence, `CONTRIBUTING.md`, `SECURITY.md`, code of conduct, issue and PR templates, `.env.example`.
- [x] Environments: `supabase/config.toml` committed, `Backend migrations` CI job, `deploy-supabase.yml` (staging on merge, production on `v*` tag with approval), `staging` / `production` GitHub environments, `.coderabbit.yaml` (2026-09-28).
- [x] `main` protected by a ruleset: PR required, the four CI checks required, squash-only, linear history, no force-push; Dependabot for the GitHub Actions (2026-09-28).

## M1 – Local data layer

- [ ] drift tables for every entity in `docs/DATABASE.md` (`trades`, `service_types`, `equipment`, `visits`, `visit_items`, `appointments`, `reminders`, `devices`, `sync_state`, `app_settings`).
- [ ] Equatable models + DTOs + repositories per entity, following the `Client` slice.
- [ ] `DefaultCatalog` in `rewizyta_models` (trades → service types) and the onboarding seed service that copies it into the user's rows with `template_key`.
- [ ] Due-date recompute in the services that touch visits, visit items, equipment and cycles (`nextDue` exists and is tested).
- [ ] Repository tests on `NativeDatabase.memory()`, service tests with mocktail.

## M2 – Clients

- [ ] List with search (name, phone, town), detail, add/edit form with inline validation, soft delete.
- [ ] Equipment on a client, each with a service type from the user's catalogue.
- [ ] Import from phone contacts (`flutter_contacts`), paste a number.
- [ ] Phone formatting (E.164 in, Polish display out – `formatPhone`), call and SMS via `url_launcher`.

## M3 – Visits and due list

- [ ] Record a visit: tick equipment, price, note; recompute due dates.
- [ ] Due list: overdue / next 60 days / later, with "booked" flag.
- [ ] Client history.

## M4 – Booking and Today

- [ ] Book appointment (day + hour), statuses.
- [ ] Today screen (day plan) and week view.
- [ ] `DayPlanService`: capacity from `slots_per_day`/hours, haversine distances with road factor, nearest-neighbour order that keeps `is_time_fixed` stops, `route_position` persistence, drag-and-drop in `manual` mode.
- [ ] Booking proposals: days with a free slot whose stops are closest to the client.
- [ ] Open a stop in maps; show "~km, ~min" between stops.

## M5 – Backend and sync

- [ ] Supabase project in `eu-central-1`; migrations for every table, RLS forced, `sync_push` / `sync_pull` RPCs.
- [ ] Auth (email + password or magic link), custom SMTP (Scaleway TEM), profile.
- [ ] `SyncApi` (Supabase impl + no-op) in the network tier; `SyncService`: outbox push, incremental pull, last-write-wins, connectivity and app-start triggers; `SyncStatusObserver`.
- [ ] `devices` upload from `PushNotificationsService.onTokenRefresh`.
- [ ] Restore-on-new-phone flow.
- [ ] `purge-deleted` nightly cron (30 days) + `tombstones`; `sync_push` rejects tombstoned ids; phone-side purge.
- [ ] `export-account` and `delete-account` functions (cancel reminders, hard delete, `account_deletions`, auth user removal); `account_deletions` table.
- [ ] Self-hosting notes (Docker compose on Hetzner) in `supabase/README.md`.

## M6 – SMS reminders

- [ ] `send-due-reminders` (daily) and `send-pending-sms` (every 5 min) edge functions.
- [ ] `SmsGateway` adapter selected by `SMS_PROVIDER` (smsapi | serwersms | console): SMSAPI implementation, console stub, shared contract test; start on SMSAPI pay-as-you-go.
- [ ] Template editor with placeholders and live preview; offsets in settings.
- [ ] Delivery-report webhook; statuses visible in client history.

## M7 – Settings, onboarding and integrations

- [ ] Profile, sender name, template, offsets, SMS balance.
- [ ] Planner settings: working hours, slots per day, slot length, home location, travel speed, route mode.
- [ ] Settings → "Eksportuj dane" and "Usuń konto" (export first, re-auth, confirmation word, local wipe); "export this client" on the client screen.
- [ ] First-run onboarding: profile → pick trades (seeds service types) → import contacts → promo code → notification permission.
- [ ] Trades and service types editor (rename, cycle, price, archive, add; add a custom trade; restore defaults).
- [ ] Vendor adapters in `apps/mobile/lib/app/integrations/`: `SentryReportingService` (EU DSN), `PosthogAnalyticsService` (EU host), `FcmPushNotificationsService`; chosen from `AppConfig` in `_registerReporting()`.
- [ ] Analytics events as constants in the services that emit them; no strings in cubits.

## M8 – Waitlist site and mailing

- [ ] `apps/waitlist`: one page, Polish, email + optional trade form → `waitlist-signup`, shows the promo code.
- [ ] `EmailGateway` adapter (`functions/_shared/email/`) selected by `EMAIL_PROVIDER` (brevo | scaleway | console): Brevo implementation first (free plan), console stub, contract test; Supabase Auth custom SMTP pointed at the same account.
- [ ] `waitlist-confirm`, `waitlist-unsubscribe` (link + `List-Unsubscribe` one-click), launch-mail function with batching and `last_mailed_at`.
- [ ] `redeem-promo` function and the onboarding step that calls it.
- [ ] Hosting on Bunny.net or Hetzner Object Storage, DNS at OVH.

## M9 – Product website

- [ ] `apps/website`: home, features, pricing, privacy policy (needed for Play review), contact. PL + EN.
- [ ] Privacy policy and terms with the DPA (umowa powierzenia), the sub-processor list (Supabase EU, SMSAPI/SerwerSMS, Scaleway, Sentry EU, PostHog EU, FCM) and the retention table from `DATABASE.md`.

## V1 (after MVP ships)

- [ ] Android caller card (`CallScreeningService` / overlay).
- [ ] Monthly summary and export.
- [ ] "Przypomnienia" passes and SMS top-ups: Play one-time products (`pass_12m`, `pass_1m`, `sms_200`) with `in_app_purchase`, `verify-purchase` function (Play Developer API, `purchases` table, `paid_until` / `sms_balance`), 300 SMS/month fair-use check in `send-pending-sms`, expiry push + e-mail, `BILLING_ENABLED` off for self-hosters. See `docs/PRODUCT.md`, "Pricing" and `docs/ARCHITECTURE.md`, "Billing".
- [ ] Push notifications from the server ("3 clients due this week", low balance) through `devices`; `PushSender` adapter with `PUSH_PROVIDER` (fcm | ntfy | console).
- [ ] Per-user data key in Supabase Vault, `pii_encrypt`/`pii_decrypt`, encrypted personal-data columns, key drop on deletion.
- [ ] Optional SQLCipher for the local database, key in the platform keystore.
- [ ] `reminders` 12-month purge; waitlist retention job.

## Later

- [ ] PDF service report with signature.
- [ ] Multiple technicians.
- [ ] Two-way SMS (one platform receiving number; costs the alphanumeric sender). Blocked on multi-technician accounts.
- [ ] Phone-side reminder rendering as an opt-in E2EE mode for self-hosters (server holds only ciphertext).
- [ ] `go_router_builder` typed routes if the route table outgrows the central list.
