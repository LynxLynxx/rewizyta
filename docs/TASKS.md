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
- [x] `main` protected by a ruleset: PR required, the five CI checks required, squash-only, linear history, no force-push; Dependabot for the GitHub Actions (2026-09-28).

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

Moved ahead of M1 on 2026-09-29: the waitlist goes live first, to measure
interest before the app is built.

- [x] `waitlist_signups` + `rate_limits` migration with service-role-only SQL functions and pgTAP tests; `waitlist-signup` edge function (origin check, decoy field, per-caller and overall rate limits, 15-minute mail throttle) (2026-09-29).
- [x] `EmailGateway` adapter (`functions/_shared/email/`) selected by `EMAIL_PROVIDER` (brevo | console): Brevo implementation, console stub, shared contract test (2026-09-29).
- [x] `waitlist-confirm`, `waitlist-unsubscribe` (page button + `List-Unsubscribe` one-click; GET never acts) (2026-09-29).
- [x] Waitlist and product website are one Jaspr site, `apps/website`; `apps/waitlist` removed (2026-09-29).
- [x] Waitlist home page in `apps/website` from the claude.ai/design mock-up: hero, how it works, audience, comparison, seven-question survey + contact step (`@client` `SignupForm`) → `waitlist-signup`, promo code on screen, sticky call to action on phones; self-hosted IBM Plex (2026-09-29).
- [x] `waitlist-signup` takes the survey `answers`, an optional `phone` (E.164) and `consent`; expand-only migration `*_waitlist_survey.sql` with pgTAP tests (2026-09-29).
- [x] `/potwierdz/` and `/wypisz/` pages (`noindex`), one `@client` button each that posts the `#t=` token to `waitlist-confirm` / `waitlist-unsubscribe`; `/prywatnosc/` notice (GDPR art. 13) (2026-09-30).
- [x] Controller and contact on the site: USŁUGI IT Ryszard Schossler, NIP and `r.schossler@rsapps.org` in `apps/website/lib/constants/site.dart` (2026-09-30).
- [ ] Before the site goes live: a legal read of `/prywatnosc/` (Supabase's transfer wording in particular).
- [ ] Waitlist retention job before the site goes live, because `/wypisz/` and `/prywatnosc/` promise it: delete a row 30 days after `unsubscribed_at` and everything 12 months after launch, keeping only a salted hash of the address that `waitlist_signup` checks, so the opt-out holds (see `DATABASE.md`, "Retention and purge"). Moved from V1 on 2026-09-30.
- [x] `promo_reward` defaults to `trial_90d`, earlier rows backfilled (`*_waitlist_promo_reward.sql`, pgTAP): the page promises "3 miesiące za darmo" (2026-09-30).
- [x] Both mails name the reward ("3 miesiące za darmo"), as the page does (2026-09-30).
- [x] Brevo sending domain `rewizyta.rsapps.org` authenticated (Brevo code, DKIM, DMARC `p=none`, branded link subdomain `em.rewizyta`; all DNS-only in Cloudflare) (2026-09-30).
- [ ] Brevo: sender `lista@rewizyta.rsapps.org`, replies to `r.schossler@rsapps.org` through `WAITLIST_REPLY_TO` (no Cloudflare Email Routing: it takes over the root MX and would break `rsapps.org` mail); API key with IP blocking off (Supabase has no fixed IPs; off on 2026-09-30, but Brevo can switch it on after a 30-day learning phase, so look at Security → Authorized IPs after the first sends and again a month later; a blocked send shows as "brevo: 401" in the `waitlist-signup` log and as "E-mail … nie wyszedł" on the page); ask Brevo support to switch off tracking (open pixel, link rewriting), disclosed on `/prywatnosc/` until then. Then a real send on staging: the confirm and unsubscribe links must survive Brevo's link redirect with the `#t=` fragment intact; Gmail, Outlook, WP, Onet, Interia; whose `List-Unsubscribe` reaches the inbox (if Brevo's, mirror its unsubscribes through a webhook); any Brevo footer.
- [x] Hosting on Cloudflare Workers static assets (`apps/website/wrangler.jsonc`): 404 page, `web/_headers` (CSP, HSTS, font cache), `robots.txt` and a sitemap; `deploy-website.yml` deploys staging on merge and production on a `v*` tag, like the backend. Checked locally with `wrangler dev` (2026-09-30).
- [ ] Cloudflare setup: an "Edit Cloudflare Workers" API token (account + `rsapps.org` zone) and the account id as `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` on both GitHub environments; no existing DNS records on `rewizyta` and `staging.rewizyta` (the first deploy creates them); Rocket Loader and Web Analytics off.
- [ ] Production backend for the waitlist: Pro, or free plus the keepalive job (a paused project breaks the form; check what backups the free plan keeps, and dump the list yourself if none); function secrets `EMAIL_PROVIDER=brevo`, `BREVO_API_KEY`, `WAITLIST_SITE_URL` (`https://rewizyta.rsapps.org`; staging: `https://staging.rewizyta.rsapps.org`), `WAITLIST_FROM_EMAIL`, `WAITLIST_REPLY_TO`, `WAITLIST_IP_SALT` on each project; the first `v*` tag deploys migrations and functions.
- [x] Site icon: the header mark as `web/favicon.svg`, `favicon.ico` (16/32/48) and `apple-touch-icon.png`, linked from the document head (2026-09-30).
- [ ] Sharing: Open Graph tags and a 1200×630 image.
- [ ] Data processing agreements accepted with Supabase, Brevo and Cloudflare (the notice says they exist; Cloudflare is named on `/prywatnosc/` since 2026-09-30).

Not needed to go public, only for the app launch:

- [ ] Supabase Auth custom SMTP pointed at the same Brevo account.
- [ ] Launch-mail function with batching and `last_mailed_at`; `scaleway` adapter when volume outgrows Brevo's free plan.
- [ ] `redeem-promo` function and the onboarding step that calls it.

## M9 – Product website

The app's information and support site that the store listings link to, not a
web version of the app (see `ARCHITECTURE.md`, "Websites").

- [ ] Home at launch: replace the waitlist hero with what the app does, pricing and store badges; keep `/potwierdz/`, `/wypisz/`, `/prywatnosc/`. PL + EN.
- [ ] Support page: FAQ and contact address (App Store "Support URL").
- [ ] Privacy policy (both stores' "Privacy Policy URL") and terms with the DPA (umowa powierzenia), the sub-processor list (Supabase EU, SMSAPI/SerwerSMS, Scaleway, Sentry EU, PostHog EU, FCM) and the retention table from `DATABASE.md`.
- [ ] Account deletion page: the in-app path and an e-mail request route that works without reinstalling (Play Data safety "Delete account URL").

## V1 (after MVP ships)

- [ ] Android caller card (`CallScreeningService` / overlay).
- [ ] Monthly summary and export.
- [ ] "Przypomnienia" passes and SMS top-ups: Play one-time products (`pass_12m`, `pass_1m`, `sms_200`) with `in_app_purchase`, `verify-purchase` function (Play Developer API, `purchases` table, `paid_until` / `sms_balance`), 300 SMS/month fair-use check in `send-pending-sms`, expiry push + e-mail, `BILLING_ENABLED` off for self-hosters. See `docs/PRODUCT.md`, "Pricing" and `docs/ARCHITECTURE.md`, "Billing".
- [ ] Push notifications from the server ("3 clients due this week", low balance) through `devices`; `PushSender` adapter with `PUSH_PROVIDER` (fcm | ntfy | console).
- [ ] Per-user data key in Supabase Vault, `pii_encrypt`/`pii_decrypt`, encrypted personal-data columns, key drop on deletion.
- [ ] Optional SQLCipher for the local database, key in the platform keystore.
- [ ] `reminders` 12-month purge.

## Later

- [ ] PDF service report with signature.
- [ ] Multiple technicians.
- [ ] Two-way SMS (one platform receiving number; costs the alphanumeric sender). Blocked on multi-technician accounts.
- [ ] Phone-side reminder rendering as an opt-in E2EE mode for self-hosters (server holds only ciphertext).
- [ ] `go_router_builder` typed routes if the route table outgrows the central list.
