# Rewizyta – Technical requirements (TRD)

## Contents

- [Goals](#goals)
- [Overview](#overview)
- [Components](#components)
- [The app](#the-app)
  - [Packages and layers](#packages-and-layers)
  - [State and data flow](#state-and-data-flow)
  - [Trades and service types](#trades-and-service-types)
  - [Due dates](#due-dates)
  - [Day planning](#day-planning)
  - [Third-party adapters](#third-party-adapters)
- [Offline-first sync](#offline-first-sync)
  - [Principles](#principles)
  - [Outbox](#outbox)
  - [Push](#push)
  - [Pull](#pull)
  - [Triggers](#triggers)
  - [Why this is enough](#why-this-is-enough)
- [SMS on the server](#sms-on-the-server)
- [Billing](#billing)
- [E-mail: auth, waitlist and unsubscribe](#e-mail-auth-waitlist-and-unsubscribe)
- [Account export and deletion](#account-export-and-deletion)
- [Messaging: start free, swap by config](#messaging-start-free-swap-by-config)
- [Hosting and the free-tier pause](#hosting-and-the-free-tier-pause)
- [Environments and deployment](#environments-and-deployment)
- [EU stance](#eu-stance)
- [Websites](#websites)
- [Client portal](#client-portal)
- [Open source and self-hosting](#open-source-and-self-hosting)
- [Platform notes](#platform-notes)
- [Decisions log](#decisions-log)

## Goals

1. **Works without signal.** Every screen and every write works offline. The
   phone's database is the source of truth; the server is a backup and a relay.
2. **Reminders go out anyway.** SMS are sent by the server on a schedule, so a phone
   that is off, flat or out of coverage does not lose a client.
3. **One phone, one person.** Single user per account for MVP. This keeps sync
   conflict handling trivial (last write wins).
4. **Self-hostable in one command.** Open source; the backend is a Supabase project
   that runs locally with `supabase start` and has no vendor-specific pieces
   beyond Postgres, Auth, Storage and edge functions.
5. **Cheap.** No server per request for the websites (static Jaspr), no paid
   routing API, SMS as the only per-use cost.
6. **Compliant by design, EU by default.** EU hosting for every service that
   holds user data, RLS on every table, export and deletion of an account's
   data, no tracking on the websites.

## Overview

```
 Phone (Android first)                              Supabase project (EU, Frankfurt)
 ┌───────────────────────────────────┐              ┌────────────────────────────────────────────┐
 │ Flutter app                       │              │ Postgres                                    │
 │  pages ◄─ cubits ◄─ services ◄─┐  │   push       │   profiles, trades, service_types, clients, │
 │  writes ─► repositories ───────┼──┼─────────────►│   equipment, visits, visit_items,           │
 │            (drift + outbox)    │  │              │   appointments, reminders, devices,         │
 │  SyncService ◄─── pull since ──┼──┼──────────────│   waitlist_signups                          │
 │  (on start, on connectivity,   │  │   sync_pull  │   RLS: user_id = auth.uid() on every table  │
 │   after each write, workmanager)  │              │                                             │
 └───────────────────────────────────┘              │ Auth (email, SMTP via EU provider)          │
                                                    │                                             │
                                                    │ pg_cron ─► Edge functions                   │
                                                    │   08:00  send-due-reminders  (materialise)  │
                                                    │   */5min send-pending-sms    (send)         │
                                                    │   http   sms-webhook         (delivery)     │
                                                    │   http   waitlist-signup, waitlist-confirm, │
                                                    │          waitlist-unsubscribe, redeem-promo │
                                                    └───────────────┬────────────────────────────┘
                                                                    │ HTTPS
                                            SMS gateway (SMSAPI / SerwerSMS, PL)   E-mail (Scaleway TEM / Brevo, FR)
                                                                    │
                                                              client's phone

 apps/website (waitlist until launch)  ── jaspr build ──► static HTML ──► Cloudflare Workers (rewizyta.rsapps.org)
```

## Components

| Part | Tech | Responsibility |
|---|---|---|
| `apps/mobile` + `packages/rewizyta_*` | Flutter 3.47, flutter_bloc, Equatable, get_it, go_router, drift, supabase_flutter, connectivity_plus, url_launcher, flutter_contacts (M2), workmanager (M5) | The product. Reads only from the local DB; syncs in the background. |
| `supabase/migrations` | SQL | Schema, RLS, indexes, triggers, `sync_push`/`sync_pull` RPCs, `keepalive()`, cron schedules. |
| `supabase/functions` | Deno / TypeScript | `send-due-reminders`, `send-pending-sms`, `sms-webhook`, `waitlist-signup`, `waitlist-confirm`, `waitlist-unsubscribe`, `redeem-promo`, `verify-purchase`. Gateways behind adapter interfaces. |
| Supabase Auth | email + password (magic link optional), custom SMTP | One account per technician. The JWT `sub` is the `user_id` on every row. |
| `apps/website` | Jaspr 0.23 static, jaspr_router | The one site. Until launch: the waitlist page with the sign-up form, `/potwierdz/`, `/wypisz/`, privacy notice (Polish). After launch: the information and support pages the store listings link to (about and pricing, support, privacy policy, account deletion, terms), PL + EN. Never a web version of the app. |
| CI | GitHub Actions | Format, analyse, layering audit, test the workspace; format, analyse, test and build the site; keepalive ping for the free-tier project. |

## The app

### Packages and layers

Layer-first Melos monorepo, the same shape as Bodyspace and Catalyst Voices.
Dependencies point strictly down; the pubspecs enforce most of it and
`tool/check_layering.sh` (`melos run layering`) catches the transitive cases.

```
apps/mobile                 bootstrap, AppConfig, Dependencies (DI), router, pages, theme, handlers
   ├─► rewizyta_blocs       cubits + states, side-channel mixins, AppBlocObserver
   │      ├─► rewizyta_services      ClientsService…, observers, sync managers,
   │      │      │                   AnalyticsService / ReportingService / PushNotificationsService
   │      │      └─► rewizyta_repositories   drift AppDatabase, tables, outbox, DTOs, repositories
   │      │             └─► rewizyta_models   Client, Equipment…, typed exceptions, nextDue()
   │      └─► rewizyta_view_models  ClientListItemViewModel…, formatters, LocalizedException
   │             └─► rewizyta_localization   app_pl.arb → AppLocalizations, context.l10n
   └─► rewizyta_shared      DependencyProvider (get_it), Optional
```

| Layer | Owns | Never |
|---|---|---|
| models | entities (`with Equatable`), value objects, typed exceptions, enums, pure rules | JSON, Flutter, I/O |
| repositories | drift tables and queries, DTOs (json_serializable) for sync payloads, DTO ↔ model and row ↔ model mapping, the outbox write | caching policy, orchestration, validation |
| services | validation, ids and timestamps, orchestration across repositories, shared state (observers), sync managers, adapter interfaces | Flutter types, presentation formatting |
| blocs | one state class per screen, cubit methods as the screen's API, domain → view model mapping, error wrapping | widgets, direct data access |
| view_models | UI-shaped data, presentation enums, formatters (dates, phones, plurals), `LocalizedException` | business logic |
| app | pages, widgets, routing, theme, DI wiring, vendor SDK integrations | business logic, direct service calls from widgets |

The first vertical slice (`Client`) exists in every layer and is the template
for the rest: `packages/rewizyta_models/lib/src/client/`,
`packages/rewizyta_repositories/lib/src/client/`,
`packages/rewizyta_services/lib/src/client/`,
`packages/rewizyta_blocs/lib/src/clients/`,
`packages/rewizyta_view_models/lib/src/client/`, `apps/mobile/lib/pages/clients/`.

### State and data flow

- **Reads:** a cubit calls `service.watchX()` in `init()`, which is a drift
  stream from the repository. The cubit maps rows to view models and emits;
  the screen rebuilds when the row changes, whether the change came from the
  user or from a pull. There is no "loading from network" state anywhere.
- **Writes:** a service validates, stamps `id`/`updated_at`, and calls the
  repositories inside one `TransactionRunner.run`: (1) upserts the row(s),
  (2) recomputes any cached values (`equipment.next_due_at`); every repository
  write (3) appends its `outbox` row in the same transaction. Then it pokes `SyncService`, which tries to push immediately
  and gives up silently if offline.
- **Errors:** repositories throw typed exceptions from `rewizyta_models`; the
  cubit wraps them with `LocalizedException.create` and pushes them through
  `emitError`; the page's `ErrorHandlerStateMixin` shows a snackbar. Unknown
  errors are logged and reported, not shown. Field validation is state.
- **One-off effects** (navigate, toast) go through `emitSignal` and
  `SignalHandlerStateMixin`.
- **DI:** `Dependencies.init()` registers everything bottom-up in tiers;
  `bootstrap()` is the single start-up path (config → Supabase → DI →
  reporting → error handlers → `Bloc.observer` → `runApp`).

### Trades and service types

Defaults are data the user owns, not global tables. `rewizyta_models` ships a
`DefaultCatalog`: trades (`kominiarz`, `serwisant gazowy`, `serwisant kotłów`,
…) each with default service types (name, cycle in months, suggested price).
During onboarding the user picks one or more trades; the app copies those
service types into the user's own `service_types` rows and the trade into
`trades`, both stamped with `template_key` so "restore defaults" and
de-duplication work. From then on everything is per user: rename, change the
cycle, archive, add a service type, add a whole custom trade. Equipment points
at the user's row, so two technicians can have different cycles for the same
template. Self-hosters change the defaults in one Dart file.

### Due dates

`next_due = last_visit_at + cycle_months` (calendar months; a 31 January plus one
month becomes 28/29 February; `nextDue()` in `rewizyta_models`). Equipment with
no visit yet is "due now" and shown in its own bucket so the technician enters
the last real date. The value is cached on `equipment` for sorting and for the
server job, and recomputed by the services that change visits, visit items,
equipment or a service type's cycle.

### Day planning

Planning is on the phone, from the profile's settings, with no paid API:

- **Settings (per user, synced on `profiles`):** working hours, slots per
  day, slot length, home location, travel speed (km/h) and route mode. The
  defaults suit a chimney sweep (8 slots of 60 minutes, 40 km/h); a boiler
  technician sets 4 slots of 120 minutes.
- **Capacity.** A day has `slots_per_day` slots; booking shows how many are
  left and refuses (with an override) when the day is full or when the
  estimated travel plus visits no longer fits between `work_start` and `work_end`.
- **Distance.** Between two stops the planner uses the straight-line
  (haversine) distance from `clients.lat/lng`, multiplied by a road factor
  (1.3) and divided by `travel_speed_kmh`. It is an estimate for ordering and
  fit, not a promise; the technician sees "~12 km, ~20 min" between stops.
- **Order.** `nearest_neighbour` starts from home (or the first fixed
  appointment), keeps `is_time_fixed` appointments at their hour and fills
  the flexible ones in between by nearest next stop; the result is written to
  `appointments.route_position`. `manual` mode keeps the technician's
  drag-and-drop order and only shows the distances. "Optimise" can always be
  re-run; it never moves a fixed appointment.
- **Proposals.** When booking a due client, the planner suggests the days in
  the next two weeks with a free slot whose existing stops are closest to
  the client, so the technician clusters a village on one day.
- Everything lives in a `DayPlanService` (pure Dart, `rewizyta_services`)
  with unit tests on synthetic coordinates; the cubit only renders the plan.

### Third-party adapters

Every SDK sits behind an interface in `rewizyta_services` with a no-op
implementation, so the domain and the tests never see a vendor and a
self-hoster can build without any account:

| Interface | Vendor (EU) | Alternative | Where the vendor code goes |
|---|---|---|---|
| `ReportingService` | Sentry, EU data residency (`de.sentry.io`) | self-hosted GlitchTip (same protocol) | `apps/mobile/lib/app/integrations/sentry_reporting_service.dart` |
| `AnalyticsService` | PostHog EU cloud (Frankfurt) | none (leave the key empty) | `…/posthog_analytics_service.dart` |
| `PushNotificationsService` | FCM (Google) – the only reliable Android delivery | UnifiedPush / ntfy for the self-hosted build | `…/fcm_push_notifications_service.dart` |

`AppConfig` reads the keys from `--dart-define-from-file`; an empty key selects
the no-op in `Dependencies._registerReporting()`. The global `AppBlocObserver`
and the Flutter error handlers forward to `ReportingService` in every build
mode. Push tokens are uploaded to `devices` and used only by edge functions
(e.g. "your SMS balance is low", "3 clients due this week"); the app never
addresses another device.

## Offline-first sync

### Principles

- The phone is authoritative for the technician's own data. The server keeps a
  copy so that reminders can be sent and so a new phone can restore everything.
- UUIDs (v4) generated on the phone, so inserts never wait for the server.
- Every synced table, locally and remotely, has `id`, `user_id`, `created_at`,
  `updated_at` (set by the writer, the LWW clock) and `deleted_at` (soft delete).
- The server adds `server_updated_at`, set by a trigger to `now()` on every
  write. **Pulls use `server_updated_at`, not `updated_at`**, so a phone with a
  wrong clock cannot make rows invisible to a later pull.

### Outbox

Each local write appends `outbox(entity, entity_id, op, payload, created_at)`.
`op` is `upsert` or `delete` (a delete is an upsert with `deleted_at` set; the
distinction is only for logging). The payload is the full row as its DTO, so
pushes are idempotent and order-independent within one entity, and a newer
write to the same row replaces its pending entry instead of queueing a second
one. Foreign keys on both sides are checked at commit, so neither the push nor
the pull has to order rows by dependency within a transaction.

### Push

`SyncService.push()` groups the outbox by entity, sends batches to the
`sync_push(changes jsonb)` RPC and deletes the outbox rows that the server
acknowledged, by their local `id`. A write during the push replaces the row's
pending entry with a new one (`upsertSynced`); deleting by `(entity,
entity_id)` would drop that newer change unsent. The RPC upserts each row with `on conflict (id) do update ... where
excluded.updated_at > existing.updated_at`, so a stale phone cannot overwrite a
newer server row. Rows the server rejected (older `updated_at`) come back in the
response and are applied locally, which resolves the conflict the same way on
both sides.

### Pull

`SyncService.pull()` calls `sync_pull(since timestamptz)` with the stored
`sync_state.last_pulled_at` and receives every row of every table with
`server_updated_at > since`, including soft-deleted ones. Rows are applied with
the same LWW rule (`incoming.updated_at > local.updated_at`), then `last_pulled_at`
is set to the server's `now()` returned in the same response. First login on a
new phone is just a pull with `since = -infinity`.

### Triggers

Push and pull run: on app start, when connectivity returns
(`connectivity_plus`), after every local write (push only, best effort), and
periodically in the background (`workmanager`, ~15 min, Android). Failures are
logged to the outbox row (`attempts`, `last_error`) and retried with backoff;
nothing is ever dropped.

### Why this is enough

One user per account means conflicts only arise between the same person's two
devices or a phone that was offline for a long time. Last write wins on
`updated_at` is what the technician would expect in both cases. Multi-technician
support (later) will need per-field merges or CRDTs for a few tables; the schema
already carries the timestamps that would need.

## SMS on the server

1. **Materialise.** `send-due-reminders` runs daily at 08:00 Europe/Warsaw
   (`pg_cron` → HTTP). For every user and every configured offset (default 30 and 7
   days) it finds `equipment` where `next_due_at - offset = today` and the client
   has a phone, renders the user's template with the client's data, and inserts
   a `reminders` row (`kind = 'due'`, `status = 'pending'`). A unique index on
   `(equipment_id, due_on, offset_days)` makes the job idempotent.
2. **Send.** `send-pending-sms` runs every 5 minutes and sends every `pending`
   reminder with `send_at <= now()` through the gateway adapter, then stores
   `provider_message_id`, `sent_at` and `status = 'sent'` (or `failed` with the
   error). Manual messages written by the app (`kind = 'manual'`) go through the
   same path, so the phone never talks to the gateway.
3. **Delivery.** `sms-webhook` receives delivery reports and updates `status` to
   `delivered` or `failed`. The app pulls these rows like any other and shows
   them in the client's history.
4. **Entitlement.** A message goes out when `profiles.paid_until >= today` and
   this month's sent count (from `reminders`) is under the 300 fair-use pool,
   or, past the pool, when `profiles.sms_balance > 0`, which the send then
   decrements. Otherwise the job skips the user, and the app shows the pass
   expiry and the balance well before either runs out. See "Billing".

The gateway adapter is a TypeScript interface (`send(to, body, from) →
providerId`) with an SMSAPI implementation and a `console` stub used locally and
in tests. Sender name registration (e.g. `KOMINIARZ`) is a manual, per-gateway
step documented in `supabase/README.md` once done.

## Billing

Passes and top-ups are Google Play one-time products (`pass_12m`, `pass_1m`,
`sms_200`), bought in-app with `in_app_purchase` and granted only by the server.
See `docs/PRD.md`, "Pricing", for why this and not a web checkout.

1. The app completes the Play purchase flow and posts the purchase token and
   product id to `verify-purchase` (authenticated as the user).
2. The function verifies the token with the Play Developer API
   (`purchases.products.get`, a Google Cloud service account whose JSON key is
   a function secret), inserts a `purchases` row (the unique `purchase_token`
   makes the call idempotent), extends `profiles.paid_until` or adds to
   `profiles.sms_balance`, and acknowledges and consumes the product so it can
   be bought again.
3. The app pulls `profiles` like any other table; the purchase is "pending"
   in the UI until the pull shows the new date. If the phone was offline when
   the store completed the purchase, `in_app_purchase` redelivers it on the
   next start and the app retries the call.
4. `BILLING_ENABLED` (function secret, off by default) gates all of this. Off,
   `send-pending-sms` ignores `paid_until` and `sms_balance`, so a self-hoster
   with their own gateway account has no billing at all and configures no Play
   products.

Renewal: a push and an e-mail seven days before `paid_until`, and the app shows
the date on the settings page. Google is the merchant of record; we invoice
Google monthly with reverse charge and issue no customer invoices.

## E-mail: auth, waitlist and unsubscribe

One transactional e-mail provider, EU-hosted, used for two things:

- **Supabase Auth mail** (confirmation, magic link, password reset; after MVP
  also the client portal's sign-in codes) through the project's custom SMTP
  settings. Supabase's built-in sender is rate-limited
  and not for production.
- **Waitlist mail**, sent by edge functions through an `EmailGateway` adapter
  (`functions/_shared/email/`) with a `console` stub for local development.

Provider: **Brevo** (Paris; free plan of 300 mails a day, SMTP + API) to start,
**Scaleway Transactional Email** (Paris; pay per 1,000) when volume outgrows
it. Both are EU companies with EU data centres; the swap is one adapter class
and an env var. No US providers (Resend, Postmark, SendGrid, Mailgun US) for
user data. Brevo's own contact lists are not used: the list is ours.

Brevo, as set up for the waitlist: the sending domain is `rewizyta.rsapps.org`
(Brevo code, DKIM and DMARC records at Cloudflare, all DNS-only; tracked
links go through the branded subdomain `em.rewizyta.rsapps.org`), the sender
`lista@rewizyta.rsapps.org` has no mailbox, and `WAITLIST_REPLY_TO` sends
replies to a real one. Two Brevo behaviours to know: API keys block unknown IPs
30 days after first use unless IP blocking is switched off, and edge functions
have no fixed IPs, so it is off; and transactional mail always carries an open
pixel and rewritten (redirected) links, which only Brevo support can switch
off. The privacy notice says so, and the confirm and unsubscribe links must be
checked to arrive with their `#t=` fragment after the redirect.

We keep the mailing list ourselves so no vendor owns it:

1. **Sign-up.** The waitlist form posts `{email, answers, phone, consent,
   source}` plus a decoy anti-spam field to `waitlist-signup` (`answers` are
   the seven survey questions as option keys, checked against
   `_shared/waitlist/survey.ts`; the phone number is optional, normalised to
   E.164 and taken only with the consent tick; the older `{email, trade,
   source}` shape still works). The function checks the origin, the
   input and two rate limits, then calls `waitlist_signup()` in SQL, which
   inserts the row with a `confirm_token`, an `unsubscribe_token` and a
   `promo_code`, and sends the double-opt-in mail. The page shows the promo
   code right away so the visitor has a reason to keep it. An address that is
   already on the list never gets its code in the response, only by mail, so
   typing someone else's address reveals nothing but the fact that it is
   known.
2. **Confirm.** The mail links to the site's `/potwierdz/#t=…` page, which has
   a "confirm" button that posts the token to `waitlist-confirm`; that sets
   `confirmed_at`. Only confirmed rows ever receive a second mail (GDPR
   consent is the confirmation). The link opens a page instead of acting on
   GET because corporate link scanners open every URL in a message and would
   confirm on the reader's behalf; hosted functions also rewrite `text/html`
   on GET to plain text, so the page has to live on the site anyway. The token
   rides in the fragment, which never reaches a server log.
3. **Unsubscribe.** Every mail carries the site's `/wypisz/#t=…` page in the
   body (a button again) and `waitlist-unsubscribe?token=…` as `List-Unsubscribe`
   / `List-Unsubscribe-Post` headers (RFC 8058 one-click, required by
   Gmail/Yahoo since 2024; mail providers POST to it). A GET on that URL is
   redirected to the page. The function sets `unsubscribed_at` and drops the
   phone number; the row stays so we never mail that address again and can
   prove the opt-out. Typing the address into the form again only mails a new
   confirmation link; the opt-out holds until that link is used, so nobody can
   lift someone else's. Brevo adds
   its own `List-Unsubscribe` to transactional mail as well, and a click on it
   blocks the address at Brevo without telling us. Before launch, check with a
   real send which header wins; if Brevo's does, add a webhook that mirrors
   Brevo unsubscribes into `unsubscribed_at`.
4. **Launch mail and later sends** are an edge function that selects
   `confirmed_at is not null and unsubscribed_at is null` and sends in batches
   through the same adapter, recording `last_mailed_at`.
5. **Promo code.** After launch the technician enters the code in the app's
   onboarding; `redeem-promo` (service role) checks the code is unused, sets
   `redeemed_at` / `redeemed_by` and grants the reward on `profiles`
   (`sms_balance` credit or days on `paid_until`). One code, one account.

Abuse controls on the public functions, all without a CAPTCHA or a third-party
script: the decoy field (a filled one gets a fake success and nothing is
stored), an origin check, 5 sign-ups per caller per 10 minutes and 120 for
everyone per hour (`rate_limits`, keyed by an HMAC of the IP), and at most one
mail per address per 15 minutes. The overall cap is what keeps a flood with
forged `x-forwarded-for` headers from burning Brevo's 300 mails a day.

The website and the waitlist page still ship no scripts other than the form,
and set no cookies.

## Account export and deletion

GDPR asks for both without undue delay; a self-hoster should not have to
write them, so they are server functions called from Settings.

**Export** (`export-account`, authenticated): returns a ZIP with one JSON and
one CSV per table for `auth.uid()`, plus the profile. The app saves it through
the system share sheet. The same function, filtered to one client, backs the
"export this client" action used to answer a client's access request.

**Deletion** (`delete-account`, authenticated, re-authentication required):

1. The app asks the technician to export first, then to re-enter the password
   and type the confirmation word.
2. The function, as service role and in one transaction:
   - cancels every `pending` reminder so nothing goes out after the account is gone;
   - hard-deletes the user's rows in every table (the second exception to
     "nothing is physically deleted"), deletes storage objects, and drops the
     per-user data key from Vault (crypto-shredding the ciphertext left in backups);
   - writes `account_deletions(user_id_hash, completed_at)`;
   - calls `auth.admin.deleteUser`.
3. Outside the database: the PostHog person is deleted through the EU API,
   Sentry holds only the user id (scrubbed on deletion), the SMS gateway keeps
   its own delivery logs under its DPA (stated in the privacy policy), and a
   confirmation e-mail is sent to the address that was on the account.
4. The phone wipes SQLite and secure storage, deletes the push token and
   returns to the login screen. Other devices logged into the account are
   signed out by the auth deletion and wipe on their next start.
5. Backups: the rows vanish from platform backups when those roll off (7
   days on Pro); with the per-user key gone they are unreadable before that.
   The privacy policy states "deleted immediately, gone from backups within
   30 days".

There is no grace period: the export step is the safety net, and a paused
account would still be holding third-party personal data.

## Messaging: start free, swap by config

E-mail, SMS and push each sit behind one adapter with one environment
variable selecting the vendor, so the starting choice is the cheapest one that
is EU-hosted and the move to a cheaper high-volume vendor is a new adapter
class plus a config change, never a schema or app change. The interfaces cover
only what every vendor offers (send, delivery report); vendor-specific extras
(contact lists, templates, campaigns) are deliberately unused, which is also
why the mailing list lives in our own table.

| Channel | Adapter and switch | Start (free or near-free) | At volume | Migration cost |
|---|---|---|---|---|
| E-mail (auth mail + waitlist) | `functions/_shared/email/EmailGateway`, `EMAIL_PROVIDER=brevo\|scaleway\|console`; Supabase Auth custom SMTP settings | **Brevo** free plan, 300 mails/day, EU (Paris), SMTP + API, covers auth mail and the waitlist for the first thousands of sign-ups | **Scaleway Transactional Email** (Paris): 300/month included, then about €0.25 per 1,000; or Brevo paid | one class (~60 lines) + two env vars; auth SMTP host/user/password in the Supabase dashboard |
| SMS (reminders) | `functions/_shared/sms/SmsGateway`, `SMS_PROVIDER=smsapi\|serwersms\|console` | **SMSAPI** (Poland) pay-as-you-go, no subscription; "Eco" messages without a sender name for testing, "Pro" with the registered `KOMINIARZ` sender. New accounts get a few test messages free; there is no real free tier for SMS anywhere (rates in `docs/private/BUSINESS.md`) | **SerwerSMS** or **SMSPLANET** volume tiers – prices are close, so the deciding factor is the sender-name paperwork already done; migrate only if the difference pays for re-registering the sender | one class + `SMS_PROVIDER`; the delivery webhook is per vendor, so a second `sms-webhook-<vendor>` route |
| Push | app: `PushNotificationsService`; server: `functions/_shared/push/PushSender`, `PUSH_PROVIDER=fcm\|ntfy\|console` | **FCM**: free, unlimited, the only reliable path on stock Android | stays free; self-hosters can run **ntfy** (free, EU-hostable) via UnifiedPush | one class each side |
| Backend | – | Supabase free (EU) for dev, kept awake by the keepalive job | Pro $25/month, or self-hosted on a Hetzner VPS (~€5/month) | none: same migrations and functions |
| Crash reporting | `ReportingService` | Sentry free tier (EU data residency), or GlitchTip self-hosted | Sentry Team, or keep GlitchTip | DSN only; same protocol |
| Analytics | `AnalyticsService` | PostHog EU free tier (1M events/month) | PostHog usage-based | key only |

Costs that actually scale with users are SMS and Supabase. SMS is passed
through to the technician as the "Przypomnienia" passes and top-ups
(`profiles.paid_until`, `profiles.sms_balance`), so it is never our fixed cost; everything else stays inside free tiers until a few
thousand accounts. Prices above are 2026 list prices to be re-checked before
each vendor decision.

Rules that keep the swap cheap:

- The adapter interface is the union of nothing: only methods every candidate
  vendor implements. Sender name, `List-Unsubscribe` headers and delivery
  status are inputs/outputs of `send()`, not vendor features.
- Secrets and the provider name are Supabase function secrets (`supabase
  secrets set EMAIL_PROVIDER=brevo BREVO_API_KEY=…`); the code never checks
  which vendor is active outside the adapter factory.
- Every adapter has the same contract test (send a message, parse the
  delivery webhook) run against the `console` stub in CI and against the real
  vendor in a manual smoke test before switching.
- Message history (`reminders`, `waitlist_signups.last_mailed_at`) is ours,
  so switching vendors loses no data.

## Hosting and the free-tier pause

Supabase free projects are **paused after 7 days without API activity** and
resume with a manual click (data kept for up to a year); Pro projects
(from $25/month) never pause. Activity means traffic through the API gateway
(REST/RPC, Auth, Storage, Functions), not internal `pg_cron` runs, so a
project whose only traffic is the cron job can still be paused.

Three tiers, three answers:

| Environment | Plan | Pause handling |
|---|---|---|
| local | `supabase start` | n/a |
| dev / staging | free, EU region | `.github/workflows/supabase-keepalive.yml` calls the `keepalive()` RPC (a no-op SQL function exposed to `anon`) twice a week. That counts as API traffic. |
| production | Pro, EU region – or self-hosted Supabase on Hetzner (DE/FI) | never pauses; Pro adds daily backups and PITR. A paused production project would silently stop every reminder, so the free tier is not an option there. |

Self-hosting is the fully-EU route: the Supabase Docker stack on a Hetzner
VPS (Falkenstein or Helsinki) with the same migrations and functions; the
`keepalive()` function is harmless there. `supabase/README.md` will carry the
compose notes once M5 lands.

## Environments and deployment

Three targets share one `supabase/` folder. Nothing is ever applied by hand to a
hosted database.

| Target | What | Backend deployed by | App build |
|---|---|---|---|
| local | `supabase start` on the developer's machine | `supabase db reset` | `--dart-define-from-file=.env` |
| staging | hosted, free tier, EU region (kept awake by the keepalive job) | `deploy-supabase.yml` on every merge to `main` that touches `supabase/` | `.env.staging` |
| production | hosted Pro, EU region, or self-hosted on Hetzner | `deploy-supabase.yml` on a `v*` tag, after approval on the `production` GitHub environment | `.env.production` |

**Trunk-based.** `main` is the only long-lived branch and is protected by a
ruleset: pull request required, the CI checks required, squash-only merges,
linear history, no force-push. Every merge is deployable and lands on staging
by itself. A release is an annotated `vX.Y.Z` tag on `main`; the same tag will
later drive the Play Store build. There is no `develop` branch and no release
branch: one person does not need a release train, and the app-store review is
already a gate. A hotfix is a normal PR plus a new patch tag.

**What CI proves before merge.** Besides format, analysis, layering and tests,
the `Backend migrations` job starts a fresh Postgres and applies every migration
in order, then runs `supabase db lint`. A migration that does not apply never
reaches `main`, and so never reaches `supabase db push`.

**Secrets per target.** Every hosted value lives on the GitHub environment of
its target, never at repository level, so staging and production can never be
mixed up. The deploy workflow reads `SUPABASE_ACCESS_TOKEN`,
`SUPABASE_PROJECT_REF` and `SUPABASE_DB_PASSWORD` (the ref is kept as a secret
so the hosted project never appears in the public repo); the keepalive job reads
`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from `staging` only, since Pro
never pauses. Function secrets (`SMS_PROVIDER`, gateway tokens, `BILLING_ENABLED`) are
set once per project with `supabase secrets set --project-ref`. The app's keys
are in git-ignored `.env*` files and end up inside the binary, so anything that
must stay private belongs behind an edge function, never in `.env`. There is no
hosted secrets manager: Doppler was considered and rejected (US-only hosting,
and a self-hoster would need a fourth account); if a team ever needs one,
sops + age in the repo or self-hostable Infisical keep the EU stance.

**Expand, then contract.** Phones are offline-first and may run a build from a
month ago when a migration lands. Every migration therefore keeps the previous
app release working: new columns get defaults, new tables and functions are
additive, edge functions accept the previous payload shape. Renames and drops
happen in a later release, once the old build is out of the field. This is hard
rule 12 in `CLAUDE.md`.

**Not used, on purpose.** Supabase branching (a preview database per PR) needs
the Pro plan and the GitHub integration; not worth it for one contributor.
`config.toml` is not pushed to hosted projects: it describes the local stack,
and the hosted auth and API settings are set in the dashboard.

**Code review.** CodeRabbit reviews every pull request against `CLAUDE.md`
(`.coderabbit.yaml`). It is free for a public repository and only reads code
that is public anyway, so the EU rule does not apply. It is advisory, not a
required check.

## EU stance

Every hosted dependency, with the EU option chosen and the reason:

| Need | Choice | Why |
|---|---|---|
| Backend | Supabase, `eu-central-1` (Frankfurt); self-host on Hetzner as the fully-EU path | Supabase Inc. is US, but data stays in the EU and the stack is open source |
| Crash reporting | Sentry with EU data residency, or self-hosted GlitchTip | GlitchTip is the zero-vendor fallback behind the same adapter |
| Product analytics | PostHog EU cloud (Frankfurt) | EU ingest host; the app works with the key empty |
| Push | FCM behind an adapter | no EU service delivers reliably on stock Android; the adapter keeps UnifiedPush possible for self-hosters |
| SMS | SMSAPI or SerwerSMS (Poland) | needed for a registered Polish sender name anyway |
| E-mail | Brevo (FR) free plan to start; Scaleway Transactional Email (FR) at volume | EU companies, EU data centres; see "Messaging: start free, swap by config" |
| Static hosting / CDN | Cloudflare Workers static assets | US, but serves static files only: the forms post straight to Supabase, so form data never reaches it. It still sees request metadata (IP address, user agent) in its logs, as any host does; the privacy notice names it. Free with no traffic cap. Bunny.net (SI, about $1/month) is the fully-EU fallback; any static host works |
| DNS / domain | Cloudflare, `rsapps.org` zone | US; DNS only. The domain was already there |
| Source hosting and CI | GitHub Actions | US, but holds code only, no user data |

Rule for new dependencies: an EU region or an EU company, or self-hostable in
the EU behind an adapter. If none applies, nothing people enter may reach it
(request metadata such as IP addresses is disclosed in the privacy notice).

## Websites

One site, `apps/website`, following `portfolio_rs`: Jaspr in static mode, every
route pre-rendered at build time, no Dart in the browser except where a
component must be interactive. Polish at `/`, English at `/en/` (English from
launch). Self-hosted fonts, no third-party scripts, no cookies, so no consent
banner.

- **Until launch – the waitlist.** The home page is the sign-up page. The form
  posts to the `waitlist-signup` edge function (rate-limited, decoy field),
  which inserts into `waitlist_signups`, sends the confirmation mail and returns
  the promo code. `/potwierdz/` and `/wypisz/` carry the buttons the mail links
  to; `/prywatnosc/` is the privacy notice. The site has no Supabase key; the
  functions' URLs are public and the table is written only through the
  functions' service role. (The client portal, after MVP, is the first page to
  carry the publishable key, which is public by design; see "Client portal".)
- **From launch – the app's information and support site.** Not a web version
  of the app (the app is phone-only), but the pages the store listings need:

  | Page | Why |
  |---|---|
  | Home: what the app does, pricing, store badges | Play "Website" and App Store "Marketing URL" (optional in both) |
  | Support: FAQ and a contact address | App Store "Support URL" (required) |
  | Privacy policy, with the sub-processors and the retention table | "Privacy Policy URL" in both stores (required); the Play caller-ID review reads it |
  | Account deletion: how to delete in the app, and how to ask by e-mail without reinstalling | Play "Delete account URL" in the Data safety form (required for apps with accounts); App Store needs the in-app path only |
  | Terms with the DPA (umowa powierzenia) | The technician is the controller of their clients' data; we are the processor |
  | Client portal, `/klient/` (after MVP) | Not a store requirement; the one client-facing surface, see "Client portal" |

  `/potwierdz/`, `/wypisz/` and `/prywatnosc/` keep their paths, because every
  mail already sent links to them.

Waitlist and website were one site from the start (2026-09-29) rather than two
apps: a second site would have had to take over the domain at launch and carry
the mail pages across.

**Hosting.** Cloudflare Workers with static assets only (no Worker script):
`apps/website/wrangler.jsonc` points at `build/jaspr`, serves `404.html` for
unknown paths and redirects `/potwierdz` to `/potwierdz/`; `web/_headers` sets
the CSP (this origin plus `https://*.supabase.co` for the forms), HSTS and a
year-long cache for the fonts. `.github/workflows/deploy-website.yml` builds
with `FUNCTIONS_URL` derived from the environment's `SUPABASE_PROJECT_REF` and
deploys on the backend's triggers: staging (`staging.rewizyta.rsapps.org`,
`X-Robots-Tag: noindex`) on every merge touching `apps/website/`, production
(`rewizyta.rsapps.org`) on a `v*` tag after approval. So each site always
talks to its own backend, whose `WAITLIST_SITE_URL` must be that site's origin.

## Client portal

Decided 2026-10-01 (`PRD.md`, "Client portal"): after the MVP, the
technician's clients get a page on the website, `/klient/`, that lists every
technician who services them, with due dates, the next booked visit and the
visit history. It is the one client-facing surface; there is no client app.
This section is the design; nothing of it exists yet.

**Accounts.** Portal users are ordinary Supabase Auth users without a
`profiles` row, so Goal 3 still holds: one technician per account, and a
technician who is also somebody's client signs in to the portal with the same
account. Sign-in is an e-mail one-time code (`signInWithOtp`, then `verifyOtp`
with `type: email`; the magic-link template carries `{{ .Token }}`), not a
link: a link opens in the mail app's own browser, where the PKCE verifier of
the page that asked for it is missing, and fails. The code is typed into the
page that requested it, which always works. Stage 2 adds a password or a
passkey and a phone number verified by SMS code through Supabase's send-SMS
hook, pointed at the same `SmsGateway` adapter, so a self-hoster's gateway
serves it too. The sign-in mail goes through the project's custom SMTP
(Brevo), which the waitlist and the app's auth share; the free plan's daily
cap and Auth's e-mail rate limit (`config.toml`) bound how many codes a day
can go out.

**Linking a sign-in to a client card.** Three sources, all recorded in
`client_links` (`BACKEND_SCHEMA.md`), which the server writes and the phone only
reads:

| Source | How the link is made | Who opted in |
|---|---|---|
| `email` | The technician types the client's e-mail on the card; the first sign-in with that address, or the first page load after the e-mail was saved, claims the card (`portal_claim_links()`). | The technician, per card; the field says what it is for. |
| `invite` | The reminder template contains `{portal}`; the daily job mints a short token per card and renders `rewizyta.rsapps.org/k/#<token>` (the fragment never reaches a server log, as with the mail pages). Whoever opens it and signs in with an e-mail binds that e-mail to the card (`portal_claim_invite(token)`, rate-limited per account). Needs M6. | The technician, by putting the placeholder in the template; the client, by opening the link sent to their own phone. |
| `phone` (stage 2) | The portal user verifies a phone number; every card with that number is claimed. | The technician, through `profiles.portal_enabled` only, which is why that switch exists. |

Clearing or changing the e-mail on a card soft-deletes its `email` links
(trigger); deleting the card hides it (`deleted_at`) and the purge removes the
links with it; `portal_enabled = false` hides every card of that technician at
once. A reassigned e-mail or phone number can show a stranger the previous
holder's due dates; the reminder SMS to that number already carries the same
information, so the exposure is not new, and the privacy notice says so.

**Reading.** The portal never selects from a table. It calls
`portal_overview()`, a `security definer` function for `authenticated` that
claims pending e-mail links, then returns, for each technician with
`portal_enabled` and at least one live link to the caller: business and owner
name, phone, the linked cards with their equipment (service type name,
`last_visit_at`, `next_due_at`), `planned` appointments from today on, and
visits with the labels of what was serviced. Never `price_grosze`, notes, the
address or coordinates, and never anything about another client. No synced
table gets a second RLS policy; the own-rows rule in `BACKEND_SCHEMA.md` stays the
only one. When V1's per-user column encryption lands, the function is the
second server-side reader of ciphertext after the reminder job and decrypts
with the card owner's key, for linked cards only.

**Writing.** Stage 1 writes nothing of the technician's. Stage 2 adds
`portal_requests` (ask for a date, confirm or cancel an appointment, correct
the contact details): rows the portal user owns, which the technician's app
pulls and accepts or declines with one tap; accepting writes the appointment
or the client change on the phone, through the normal outbox. The phone stays
the source of truth, and the request covers what two-way SMS was meant to do
without a receiving number and without giving up the alphanumeric sender.

**On the site.** `/klient/` and `/k/` are pre-rendered shells with a
`@client` component for sign-in and the overview, `noindex` like the mail
pages. They are the first pages to carry the publishable key and the project
URL, injected at build time like `FUNCTIONS_URL`; the CSP already allows
`https://*.supabase.co`. The calls are three (`/auth/v1/otp`, `/auth/v1/verify`,
`/rest/v1/rpc/portal_overview`), so a hand-written client next to
`waitlist_client.dart` is enough; the pure-Dart `supabase` package is the
alternative if it builds under Jaspr's analyzer pin. The session lives in
`localStorage`, with a sign-out button. Cloudflare still sees request metadata
only; the data goes between the browser and Supabase.

**Deleting.** A portal-only account is deleted from the page:
`auth.admin.deleteUser` and its `client_links`, nothing else, because it owns
nothing else. The technician's card is untouched. The privacy notice gets a
section for the portal account, where we are the controller; the DPA states
that the portal shows a card on the technician's instruction.

## Open source and self-hosting

- The app reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (plus the optional
  Sentry and PostHog keys) from `--dart-define-from-file`, so one build works
  against local, staging or a self-hoster's project.
- `supabase/` is the whole backend: `supabase start && supabase db reset` gives a
  working instance; `supabase functions serve` runs the functions; the SMS and
  e-mail adapters default to the console stubs, so no gateway account is needed
  to develop.
- No proprietary services outside Supabase, the SMS gateway and the mail
  provider. Maps open in the phone's maps app via URL; geocoding (for route
  order) uses the platform geocoder, not a paid API.
- Exporting an account (JSON/CSV of every table) and deleting it are server
  functions, because GDPR requires both and a self-hoster should not have to write them.
- Billing is a single server-side switch (`BILLING_ENABLED`, a function secret,
  off by default). With it off, `send-pending-sms` ignores `paid_until` and
  `sms_balance`, `verify-purchase` is never called and no Play products exist;
  every message goes to the self-hoster's own gateway account. The hosted
  service turns it on; the app and the functions are otherwise identical. See
  "Billing" above and `docs/PRD.md`, "Pricing".

## Platform notes

- **Caller card (V1, Android).** `CallScreeningService` (Android 10+) gives the
  number without call-log permissions; the card itself is an overlay
  (`SYSTEM_ALERT_WINDOW`) or a full-screen notification. Play review needs the
  privacy policy URL and a declaration form. iOS gets no overlay; CallKit's
  caller-ID directory extension can show a label at most.
- **Background sync** on Android via `workmanager`; on iOS it is opportunistic
  (BGTaskScheduler), so reminders never depend on the phone syncing anyway.
- **Contacts import** needs `READ_CONTACTS`; only the picked entries are stored.
- **Push** needs `POST_NOTIFICATIONS` on Android 13+; asked in onboarding, never
  on first launch.

## Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-09-28 | Supabase over Firebase | SQL + RLS + Docker local stack suits an open-source, self-hosted backend. |
| 2026-09-28 | Android first | Caller card and background sync are Android-only or Android-better; that is where the users are. |
| 2026-09-28 | Server-side SMS, daily materialisation | Reminders must not depend on the phone being on. |
| 2026-09-28 | LWW on `updated_at`, pull cursor on `server_updated_at` | Single user; clock-skew-safe pulls. |
| 2026-09-28 | Melos + pub workspace; Jaspr sites outside the workspace | `jaspr_builder` pins an older `analyzer` than drift codegen. |
| 2026-09-28 | flutter_bloc + Equatable + manual get_it in layer-first packages; Riverpod, freezed and feature-first dropped | Same conventions as Bodyspace / Catalyst Voices; no codegen for state; the layer boundary is a pubspec, not a folder. |
| 2026-09-28 | leancode_lint, latest Dart syntax (primary constructors, declaring parameters), page width 100, trailing commas preserved | Strict, maintained in Warsaw, analyzer-plugin based (no custom_lint, so no melos conflict); the author wants to track the newest Dart/Flutter. |
| 2026-09-28 | Adapters for reporting, analytics and push with no-op defaults | Self-hosters build without accounts; vendors are swappable; tests never touch an SDK. |
| 2026-09-28 | EU first: Supabase Frankfurt, Sentry EU / GlitchTip, PostHog EU, Scaleway mail, Bunny/Hetzner hosting | Compliance and the author's preference; FCM is the one non-EU exception, behind an adapter. |
| 2026-09-28 | Free tier only for dev/staging, kept awake by a scheduled keepalive; production on Pro or self-hosted | A paused project stops the reminder jobs. |
| 2026-09-28 | Own mailing list with double opt-in and one-click unsubscribe; promo code per sign-up | GDPR consent trail without a marketing vendor owning the list. |
| 2026-09-28 | Trades and service types per user, seeded from a Dart default catalogue | Works offline on first run, fully editable per user, self-hoster edits one file. |
| 2026-09-28 | Day planning from user settings (slots, hours, speed, home), haversine distances, fixed vs flexible stops | Configurable without a routing API; still nearest-neighbour on the phone. |
| 2026-09-28 | No end-to-end encryption; per-user data key in Supabase Vault + column encryption (V1), 30-day purge with tombstones, hard delete on account deletion | Server-sent SMS needs plaintext at send time; per-user keys plus crypto-shredding is the strongest measure that keeps the promise. |
| 2026-09-28 | MIT licence | Simplest for adoption and contributions. |
| 2026-09-28 | Free app; "Przypomnienia" sold in-app through Google Play Billing as one-time passes (12 months, 1 month) plus 200-SMS top-ups, 300 SMS/month fair use, verified by `verify-purchase` | Charges only for what costs money and matches the market's flat-with-SMS norm. Play's 15% buys one-tap purchase, restore, refunds, Google as merchant of record (no customer invoices) and the iOS path; a 0% web checkout would force the app to stay silent about buying. One-time products because BLIK on Play is one-time only and there is no subscription lifecycle to handle. Self-hosted is the same app with billing off. RevenueCat deferred until an App Store path exists. |
| 2026-09-28 | Waitlist collects e-mail and an optional trade | One tap sizes the segments and picks which default catalogue to polish first. |
| 2026-09-29 | Waitlist asks seven one-tap questions (trade, client count, phone platform, current records, how reminders are sent, clients lost, willingness to pay) plus an optional call-back number | Answers decide what to build first (Android or iPhone, which trades, whether the price holds) before any app code exists. Stored as option keys in `answers` jsonb; `trade` stays for the older payload. |
| 2026-09-30 | Site on Cloudflare Workers static assets, DNS at Cloudflare (`rewizyta.rsapps.org`); mail stays on Brevo | Free with no traffic cap, and the DNS was there already. A US company is acceptable because form data never reaches a static host; it sees request metadata only, which the privacy notice discloses. Firebase Hosting was rejected for its free daily transfer cap (about 1,200 first visits); Bunny/Hetzner stay the fully-EU fallback. Mailgun EU (100 mails a day free) and MailerLite (no API sending on free) were looked at and not taken. |
| 2026-09-28 | Trunk-based git: protected `main`, squash-only PRs, `v*` tags as releases; staging deploys on merge, production on tag with approval | One contributor, an app-store gate already exists, and a `develop` branch would only add merges. |
| 2026-09-28 | Migrations must keep the previous app release working (expand, then contract) | Offline-first phones lag the server by weeks. |
| 2026-09-28 | No hosted secrets manager; `.env` files, GitHub environment secrets and Supabase function secrets | Doppler is US-hosted and would be a fourth account for self-hosters; the app's keys ship in the binary anyway. |
| 2026-09-28 | CodeRabbit on every PR, advisory only | Free for open source; a second reviewer for a one-person project; the repo is public so no EU concern. |
| 2026-09-28 | Two-way SMS stays in "Later"; reminders carry `{telefon}` | A receiving number is a fixed monthly cost, but an alphanumeric sender cannot receive replies, so two-way costs the `KOMINIARZ` branding. |
| 2026-10-01 | Client portal on the website after MVP, in two stages: e-mail code sign-in and a read-only list of the client's technicians, due dates and visits; then an account with phone verification and requests the technician accepts in the app | Replaces "no client-facing portal": the client-side half of "no client gets lost", a selling point, and a way in for technicians invited by their clients. Portal users are plain Auth users without a profile; links live in `client_links`, reads go through `security definer` functions, so no synced table gets a second RLS policy and the phone stays the source of truth. A web page, not an app, so the store listings are untouched. |
