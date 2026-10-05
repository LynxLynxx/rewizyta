# Rewizyta – Database

## Contents

- [Principles](#principles)
- [Entity overview](#entity-overview)
- [Synced tables](#synced-tables)
  - [`profiles` – one row per account](#profiles--one-row-per-account)
  - [`clients`](#clients)
  - [`trades` – the user's job lines (branże)](#trades--the-users-job-lines-branże)
  - [`service_types` – the user's catalogue](#service_types--the-users-catalogue)
  - [`equipment` – one serviced item at a client](#equipment--one-serviced-item-at-a-client)
  - [`visits`](#visits)
  - [`visit_items` – what was serviced during a visit](#visit_items--what-was-serviced-during-a-visit)
  - [`appointments`](#appointments)
  - [`devices` – push registrations](#devices--push-registrations)
  - [`reminders` – every SMS, automatic or manual](#reminders--every-sms-automatic-or-manual)
  - [`client_links` – a client's portal sign-in](#client_links--a-clients-portal-sign-in)
- [Local-only tables (drift)](#local-only-tables-drift)
  - [`outbox`](#outbox)
  - [`sync_state`](#sync_state)
  - [`app_settings`](#app_settings)
- [Remote-only tables](#remote-only-tables)
  - [`purchases` – store receipts](#purchases--store-receipts)
  - [`waitlist_signups` – the mailing list and the promo codes](#waitlist_signups--the-mailing-list-and-the-promo-codes)
  - [`rate_limits` – counters for public endpoints](#rate_limits--counters-for-public-endpoints)
- [Row Level Security](#row-level-security)
  - [`tombstones` – ids that were purged](#tombstones--ids-that-were-purged)
  - [`account_deletions` – audit trail without personal data](#account_deletions--audit-trail-without-personal-data)
- [Personal data, encryption and retention](#personal-data-encryption-and-retention)
- [Sync support in Postgres](#sync-support-in-postgres)
- [Due dates](#due-dates)
- [Migrations](#migrations)

Two databases with the same shape: SQLite on the phone (drift) and Postgres on
the server (Supabase). The phone is the source of truth for the technician's
data; the server keeps a copy for reminders and restore. See
[`ARCHITECTURE.md`](ARCHITECTURE.md) for the sync protocol.

## Principles

| Rule | Locally (drift) | Remotely (Postgres) |
|---|---|---|
| Primary keys are UUID v4 generated on the phone. | `TEXT` | `uuid` |
| Every synced table has `id, user_id, created_at, updated_at, deleted_at`. | same | plus `server_updated_at` set by trigger |
| Timestamps are UTC ISO-8601. | `TEXT` (`build.yaml`: `store_date_time_values_as_text`) | `timestamptz` |
| Calendar dates (visit day, due day) are `YYYY-MM-DD`. | `TEXT` | `date` |
| Money is an integer in grosze. | `INTEGER` | `integer` |
| Phone numbers are E.164 (`+48601234567`). Formatting happens in the UI. | `TEXT` | `text` |
| Enumerations are short lowercase snake_case strings (`no_show`), checked by a constraint. | `TEXT` | `text check (...)` |
| Deletes are soft (`deleted_at`). | same | same; nothing is physically deleted |
| Foreign keys are enforced and checked at commit, so a sync can apply rows in any order. | `DEFERRABLE INITIALLY DEFERRED`, `PRAGMA foreign_keys = ON` | `deferrable initially deferred` |
| Every remote table has RLS enabled **and forced**, with one policy: `user_id = auth.uid()`. | – | in the creating migration |

Foreign-key actions matter only for the 30-day purge and account deletion,
the two physical deletes. Rows a client owns go with it (`equipment`, `visits`,
`appointments`, `reminders` cascade from `clients`; `visit_items` from `visits`
and `equipment`); optional links are cleared (`service_types.trade_id`,
`visits.appointment_id`, `reminders.equipment_id` and `appointment_id` set
null); `equipment.service_type_id` has no action, so a service type in use is
archived, never deleted.

The local database holds one account, so its indexes leave out `user_id` and
serve the phone's own queries; the indexes listed below are the server's.

**A new enumeration value is an app change first.** The phone decodes every
pulled row before storing it, and a value it does not know fails the decode
(`EnumConverter` throws `ArgumentError`), so it never reaches a local table or
a screen. Under rule 12 that makes adding a value expand-then-contract: ship
the build that knows it, and let the server or the other phones write it only
once older builds are gone. Until then the pull skips such a row and reports
it rather than storing it.

## Entity overview

```
 profiles 1 ─── * trades 1 ─── * service_types
     │
     ├── * clients 1 ─── * equipment * ─── 1 service_types
     │        │                │
     │        │                └──── * visit_items * ─── 1 visits ─── 1 clients
     │        ├──── * visits
     │        ├──── * appointments  (a visit may close an appointment)
     │        ├──── * reminders     (kind: due → equipment, appointment → appointments, manual)
     │        └──── * client_links  (portal sign-ins; written by the server, read by the phone)
     └── * devices  (push tokens)

 local only:  outbox, sync_state, app_settings
 remote only: waitlist_signups, rate_limits
```

## Synced tables

Column types are given as Postgres; the drift mapping follows the table above.
`(std)` stands for `id, user_id, created_at, updated_at, deleted_at`.

### `profiles` – one row per account

| Column | Type | Notes |
|---|---|---|
| `user_id` | `uuid` PK → `auth.users` | Also the `id` for sync purposes. |
| `business_name` | `text` | Shown in SMS as `{firma}`. |
| `owner_name` | `text` | |
| `phone` | `text` | Callback number in SMS, `{telefon}`. |
| `sms_sender_name` | `text` | Registered alphanumeric sender, e.g. `KOMINIARZ`; null until approved. |
| `sms_template` | `text` | Default: `Dzień dobry {imie}, zbliża się termin: {usluga} – {termin}. Proszę o kontakt: {telefon}. {firma}` |
| `reminder_offsets_days` | `integer[]` | Default `{30, 7}`. Sorted descending. |
| `sms_balance` | `integer` | Top-up messages left, spent only after the month's fair-use pool (300 while a pass is active). Only the server changes it. |
| `timezone` | `text` | Default `Europe/Warsaw`; used by the daily job. |
| `home_lat`, `home_lng` | `double precision` | Where the day starts and ends; null = first stop. |
| `work_start`, `work_end` | `time` | Default `08:00`–`16:00`. |
| `slots_per_day` | `integer` | Default 8. How many visits the technician takes per day. |
| `slot_minutes` | `integer` | Default 60. Length of one visit slot. |
| `travel_speed_kmh` | `integer` | Default 40. Turns straight-line distance into a travel estimate. |
| `route_mode` | `text` | `nearest_neighbour` (default), `manual`. |
| `paid_until` | `date` | Reminders are sent while `paid_until >= today`. Extended by `redeem-promo` (trial) and `verify-purchase` (passes). Only the server changes it. |
| `portal_enabled` | `boolean` default true | Whether the client portal may show this technician's cards at all (see `client_links`). The switch in Settings. |
| `created_at, updated_at, deleted_at` | | |

The planning columns are the user's settings for the day planner (see
`ARCHITECTURE.md`, "Day planning"); they sync like everything else so a new
phone gets them back.

### `clients`

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `name` | `text` not null | Person or company. |
| `phone` | `text` | E.164, nullable (some clients have none). |
| `address_line` | `text` | Street and number. |
| `town` | `text` | |
| `postal_code` | `text` | |
| `lat`, `lng` | `double precision` | Geocoded on the phone when address is saved; used for route order. |
| `note` | `text` | Free text: gate code, dog, "call before". |
| `contact_id` | `text` | Device contact identifier if imported; helps re-import. |
| `email` | `text` | Typed by the technician for the client portal, and nothing else; stored trimmed and lower-cased (a check enforces it). Null for most clients. |

Indexes: `(user_id, name)`, `(user_id, phone)` for caller lookup, `(email)` for
the portal's claim (it matches across technicians).

### `trades` – the user's job lines (branże)

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `name` | `text` not null | e.g. `Kominiarz`, `Serwisant gazowy`, `Serwisant kotłów`. |
| `template_key` | `text` | Key of the default it was copied from (`chimney`, `gas`, `boiler`); null for a user-created trade. |
| `sort_order` | `integer` | |
| `is_archived` | `boolean` default false | |

Unique `(user_id, template_key)` where `template_key is not null`, so a default
is copied at most once per user.

### `service_types` – the user's catalogue

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `trade_id` | `uuid` → `trades` | Groups the pickers; null allowed for a loose type. |
| `name` | `text` not null | e.g. `Przegląd kominiarski`. |
| `cycle_months` | `integer` not null, `> 0` | 12, 3, 6 … |
| `default_price_grosze` | `integer` | Pre-fills the visit form. |
| `template_key` | `text` | Key of the default it was copied from (`chimney.inspection`); null for a user-created type. |
| `sort_order` | `integer` | |
| `is_archived` | `boolean` default false | Hidden from pickers, kept for history. |

Unique `(user_id, template_key)` where `template_key is not null`.

**Defaults are not a table.** `rewizyta_models` ships a `DefaultCatalog` (Dart
constants): each trade template with its service-type templates, Polish names,
cycles and suggested prices. Onboarding lets the user tick trades; the app then
inserts the user's own `trades` and `service_types` rows from the catalogue,
stamped with `template_key`. After that every value is the user's: rename,
change the cycle or price, archive, add types, add a custom trade. "Restore
defaults" re-inserts only the templates whose `template_key` is missing. Two
users can therefore have different cycles for the same template, and a
self-hoster changes the defaults in one Dart file. Initial catalogue:

| Trade | Service type | Cycle |
|---|---|---|
| `chimney` Kominiarz | `chimney.inspection` Przegląd przewodów kominowych | 12 |
| | `chimney.sweep_solid` Czyszczenie – paliwo stałe | 3 |
| | `chimney.sweep_gas` Czyszczenie – gaz | 12 |
| `gas` Serwisant gazowy | `gas.installation_check` Kontrola szczelności instalacji | 12 |
| `boiler` Serwisant kotłów | `boiler.service` Przegląd kotła | 12 |

### `equipment` – one serviced item at a client

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `client_id` | `uuid` → `clients` not null | |
| `service_type_id` | `uuid` → `service_types` not null | Determines the cycle. |
| `label` | `text` | e.g. `Komin – kuchnia`. |
| `count` | `integer` default 1 | Number of identical items (three flues). |
| `note` | `text` | |
| `last_visit_at` | `date` | **Cache.** Latest `visits.done_at` among this equipment's `visit_items`. |
| `next_due_at` | `date` | **Cache.** `last_visit_at + cycle_months`; null = never serviced, treated as due now. |

Indexes: `(user_id, next_due_at)` for the due list and the daily job, `(client_id)`.

### `visits`

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `client_id` | `uuid` → `clients` not null | |
| `done_at` | `date` not null | Day precision is enough. |
| `price_grosze` | `integer` | Total for the visit. |
| `note` | `text` | What was found / done. |
| `appointment_id` | `uuid` → `appointments` | The booking this visit fulfilled, if any. |

Index: `(client_id, done_at desc)`.

### `visit_items` – what was serviced during a visit

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `visit_id` | `uuid` → `visits` not null | |
| `equipment_id` | `uuid` → `equipment` not null | |

Unique `(visit_id, equipment_id)`. Saving or deleting rows here recomputes the
equipment caches.

### `appointments`

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `client_id` | `uuid` → `clients` not null | |
| `starts_at` | `timestamptz` not null | |
| `duration_minutes` | `integer` default 60 | |
| `status` | `text` | `planned`, `done`, `cancelled`, `no_show`. |
| `is_time_fixed` | `boolean` default false | The client asked for this hour; the optimiser must not move it. |
| `route_position` | `integer` | Order within the day, set by the optimiser or by drag-and-drop. Null = unordered. |
| `note` | `text` | |

Index: `(user_id, starts_at)` for day and week views. "Booked" in the due list
means a `planned` appointment for the client with `starts_at >= today`.
Travel distance and time between stops are computed on read from
`clients.lat/lng` and the profile's `travel_speed_kmh`; they are never stored.

### `devices` – push registrations

| Column | Type | Notes |
|---|---|---|
| (std) | | `id` is a UUID minted on the phone on first run (`sync_state.device_id`). |
| `platform` | `text` | `android`, `ios`. |
| `push_token` | `text` | From `PushNotificationsService.getToken()`; rotated on refresh. |
| `push_provider` | `text` | `fcm`, `unifiedpush`; tells the sending function which adapter to use. |
| `app_version` | `text` | |
| `last_seen_at` | `timestamptz` | Updated on every sync. |

Only edge functions read tokens; the app never addresses another device.

### `reminders` – every SMS, automatic or manual

| Column | Type | Notes |
|---|---|---|
| (std) | | |
| `client_id` | `uuid` → `clients` not null | |
| `kind` | `text` | `due` (service due), `appointment` (confirmation, V1), `manual`. |
| `equipment_id` | `uuid` → `equipment` | For `due`. |
| `appointment_id` | `uuid` → `appointments` | For `appointment`. |
| `due_on` | `date` | The due date the reminder is about (for `due`). |
| `offset_days` | `integer` | 30, 7 … (for `due`). |
| `send_at` | `timestamptz` not null | When it should go out. |
| `phone` | `text` not null | Snapshot at creation. |
| `body` | `text` not null | Rendered snapshot; what was actually sent. |
| `status` | `text` | `pending`, `sent`, `delivered`, `failed`, `cancelled`. |
| `provider_message_id` | `text` | From the gateway. |
| `sent_at` | `timestamptz` | |
| `error` | `text` | Gateway error, if any. |

Unique partial index `(equipment_id, due_on, offset_days) where kind = 'due'`
makes the daily job idempotent. Index `(user_id, status, send_at)` for the sender.

Automatic reminders are created by the server, manual ones by the app; both
sync like any other row, so the app can show the full message history.

The server owns delivery. The phone may create `manual` reminders and change a
reminder only while it is `pending` (edit a manual message, or cancel); it
never writes `provider_message_id`, `sent_at` or `error`, and never moves
`status` anywhere but `pending` → `cancelled`. `sync_push` enforces this rather
than trusting last-write-wins, so a phone cancelling a stale copy cannot undo a
`sent` or `delivered` status.

### `client_links` – a client's portal sign-in

One row per (client card, portal sign-in). Planned with the client portal
(after MVP, see `ARCHITECTURE.md`, "Client portal"). Written by the server
only, by the functions below and the daily reminder job; the phone pulls it
like `reminders` and never pushes it (`sync_push` ignores the table).

| Column | Type | Notes |
|---|---|---|
| (std) | | `user_id` is the technician who owns the card. `deleted_at` revokes the link. |
| `client_id` | `uuid` → `clients` not null | |
| `portal_user_id` | `uuid` → `auth.users` | The client's portal sign-in; null while an invitation is unclaimed. |
| `source` | `text` | `email` (the card's `email` matched the sign-in's verified address), `invite` (the link in the reminder SMS), `phone` (stage 2: a verified number matched `clients.phone`). |
| `invite_token` | `text` unique | For `invite`: eight characters of Crockford base32 like `promo_code`, minted by the daily job when it renders a message with `{portal}` and reused by later messages to the same card; cleared on claim. |
| `invite_expires_at` | `timestamptz` | Pushed forward on each send; an expired, unclaimed invitation is purged. |
| `claimed_at` | `timestamptz` | When `portal_user_id` was set. |

Unique partial indexes `(client_id) where source = 'invite' and portal_user_id is null`
(one open invitation per card) and `(client_id, portal_user_id) where deleted_at is null`
(one live link per pair). Index `(portal_user_id)` for the overview.

RLS is the standard technician policy, so the phone pulls its own links. A
portal user has no policy on any table and reaches rows only through these
functions, `security definer` with a pinned `search_path`, executable by
`authenticated`:

| Function | Does |
|---|---|
| `portal_claim_links()` | Inserts an `email` link for every non-deleted card whose `email` equals the caller's verified address (`auth.users.email_confirmed_at` set) and has no live link to the caller. |
| `portal_claim_invite(token)` | Binds an open invitation to the caller: sets `portal_user_id` and `claimed_at`, clears the token. False for an unknown, claimed or expired token. At most ten attempts per account per hour through `rate_limit_hit('portal_claim:<uid>', …)`, so the short token cannot be enumerated. |
| `portal_overview()` | Calls `portal_claim_links()`, then returns JSON: for each technician with `profiles.portal_enabled` and a live link to the caller, `business_name`, `owner_name`, `phone`, and their linked, non-deleted cards with equipment (`label`, service type `name`, `last_visit_at`, `next_due_at`), `planned` appointments with `starts_at >= today`, and visits (`done_at` plus the labels of their items). Never `price_grosze`, any `note`, the address, `lat/lng` or anything about another client. |

A trigger on `clients` soft-deletes the card's `email` links whenever `email`
changes, so clearing the field is how the technician revokes one link;
`profiles.portal_enabled = false` hides all of them at once. None of this adds
a second policy to a synced table: the own-rows rule below stays the only one.

## Local-only tables (drift)

### `outbox`

| Column | Type | Notes |
|---|---|---|
| `id` | `INTEGER` PK autoincrement | Push order. |
| `entity` | `TEXT` | Table name. |
| `entity_id` | `TEXT` | Row id. |
| `op` | `TEXT` | `upsert` or `delete`. |
| `payload` | `TEXT` | Full row as JSON. |
| `created_at` | `TEXT` | |
| `attempts` | `INTEGER` default 0 | |
| `last_error` | `TEXT` | |

Written with the row in one transaction (`OutboxWriter.upsertSynced`). A newer
write to the same row replaces its pending entry: the payload is the whole
row, so only the latest one has to reach the server.

### `sync_state`

Key/value. Keys: `last_pulled_at` (server time from the last successful pull),
`last_push_at`, `device_id`.

### `app_settings`

Key/value for device-only preferences: `onboarding_done`, `theme_mode`,
`contacts_import_done`. Nothing here is synced.

## Remote-only tables

### `purchases` – store receipts

One row per verified store transaction; the idempotency record for
`verify-purchase`. Never synced to the phone; the app reads the outcome through
`profiles`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `user_id` | `uuid` → `auth.users` | |
| `store` | `text` | `play` now, `app_store` later. |
| `product_id` | `text` | `pass_12m`, `pass_1m`, `sms_200`. |
| `purchase_token` | `text` unique | Play purchase token (or App Store transaction id). Unique, so a replayed token cannot grant twice. |
| `granted_days` | `integer` | Days added to `paid_until`; 0 for top-ups. |
| `granted_sms` | `integer` | Messages added to `sms_balance`; 0 for passes. |
| `amount_grosze` | `integer` | Net price at purchase time, for reporting. |
| `verified_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

RLS: the user can `select` their own rows; only the service role writes.

### `waitlist_signups` – the mailing list and the promo codes

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK default `gen_random_uuid()` | |
| `email` | `text` not null, unique | Stored trimmed and lower-cased (a check enforces it), so the plain unique constraint is case-insensitive. |
| `trade` | `text` | `chimney`, `gas`, `boiler`, `other`; optional. |
| `source` | `text` | UTM / referrer. |
| `answers` | `jsonb` | The waitlist survey: option keys per question (a list for multiple choice) and `<question>_other` free text up to 200 characters, validated by `functions/_shared/waitlist/survey.ts`. Must be an object, at most 4,000 characters. The price in the `would_pay` question is the one on the page at `created_at`. |
| `phone` | `text` | E.164, optional, for a call-back. Only with `consented_at` (a check enforces it); stored only when the first sign-up ticks consent, cleared on unsubscribe. |
| `consented_at` | `timestamptz` | When the first sign-up ticked "contact me about Rewizyta"; kept after an opt-out as the record of it. Mail beyond the first still needs `confirmed_at`. |
| `confirm_token` | `text` unique | Random 32 bytes, base64url. Cleared on confirmation. |
| `signup_mailed_at` | `timestamptz` | When the last confirmation or code-reminder mail went out. A repeat sign-up within 15 minutes sends nothing. |
| `confirmed_at` | `timestamptz` | Double opt-in. Null = never mail again except the confirmation itself. |
| `unsubscribe_token` | `text` not null unique | Lives for the row's lifetime; every mail links to it. |
| `unsubscribed_at` | `timestamptz` | Set by `waitlist-unsubscribe`; the row is kept as the opt-out record. Cleared only by confirming a new link after re-subscribing. |
| `last_mailed_at` | `timestamptz` | Set by the launch/newsletter function. |
| `promo_code` | `text` not null unique | Human-typeable, e.g. `REWI-7K3M-9QZT`: Crockford base32 without the vowels A and E, 30^8 codes. Generated on sign-up and shown on the page, only to a new address. |
| `promo_reward` | `text` default `'trial_90d'` | `sms_100`, `trial_90d`; the campaign decides. The waitlist page promises three free months, so the default is `trial_90d` and earlier rows were backfilled (`*_waitlist_promo_reward.sql`). A campaign with another reward changes the default in a new migration. |
| `redeemed_at` | `timestamptz` | Set by `redeem-promo`. |
| `redeemed_by` | `uuid` → `auth.users` | The account that used it. One code, one account. |
| `created_at` | `timestamptz` default `now()` | |

No user rows. RLS enabled and forced with **no** policy, and every grant to
`anon` and `authenticated` revoked; only the `waitlist-*` and `redeem-promo`
edge functions (service role) touch it, through SQL functions that are
executable by `service_role` alone:

| Function | Does |
|---|---|
| `waitlist_signup(email, trade, source, answers, phone, consent)` | Inserts or finds the address and says which mail to send: `confirm` (new, pending or re-subscribing), `code` (already confirmed) or none (throttled). Anyone can type any address, so a repeat changes none of the stored data (answers, phone, consent, trade, source); it only issues a confirmation link when needed. A re-subscription stays opted out until that link is used. The phone is stored only with consent. The last three arguments default to null/false, so the three-argument call still works. |
| `waitlist_confirm(token)` | Sets `confirmed_at`, clears the token and any opt-out (a token on an unsubscribed row came from a re-subscription); false for a used or unknown token. |
| `waitlist_unsubscribe(token)` | Sets `unsubscribed_at` (idempotent), clears any pending confirm token and the phone number (its consent is withdrawn). |

Tokens are 256-bit random values looked up through their unique index, so
there is nothing to learn from timing. The reward lands on `profiles`
(`sms_balance` or `paid_until`) inside the same transaction as `redeemed_at`.

### `rate_limits` – counters for public endpoints

| Column | Type | Notes |
|---|---|---|
| `key` | `text` | `<endpoint>:<hmac>`: an HMAC-SHA-256 of the caller's IP under the `WAITLIST_IP_SALT` function secret, never the address. `<endpoint>:*` counts everyone together. |
| `window_start` | `timestamptz` | Start of the fixed window (`date_bin`). |
| `hits` | `integer` | |

Primary key `(key, window_start)`. `rate_limit_hit(key, max, window)` counts a
hit and returns whether the caller is still within `max`; it deletes windows
older than a day as it goes, so the table never holds more than a day of
pseudonymous keys. Service role only, like `waitlist_signups`.

## Row Level Security

Every table created in `supabase/migrations/` ends with:

```sql
alter table public.<t> enable row level security;
alter table public.<t> force row level security;
create policy "<t>: own rows" on public.<t>
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

`profiles` uses `user_id` as well. `waitlist_signups` and `rate_limits` get RLS with no policy.
A portal user (client portal, after MVP) matches no policy anywhere and reads
only through the `portal_*` functions described under `client_links`.
`public.keepalive()` is the one function granted to `anon`; it returns `'ok'`
and exists only so the scheduled workflow can keep a free-tier project awake.
The API roles never get `bypassrls`, table ownership or superuser. A
`tool/check_rls.sql` (to be written in M5) fails if any table in `public` lacks
forced RLS or has a `using (true)` policy.

### `tombstones` – ids that were purged

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | The purged row's id. No other data. |
| `user_id` | `uuid` | RLS as usual. |
| `entity` | `text` | Table name. |
| `purged_at` | `timestamptz` | |

`sync_push` refuses any row whose id is here, so a phone that was offline past
the retention window cannot resurrect a purged client. Tombstones are pulled
like other rows and the phone deletes the local row on receipt.

### `account_deletions` – audit trail without personal data

| Column | Type | Notes |
|---|---|---|
| `user_id_hash` | `text` PK | `sha256(user_id)`; the id itself is gone. |
| `requested_at`, `completed_at` | `timestamptz` | |
| `reason` | `text` | Optional, from the form. |

Service role only; no RLS policy for API roles.

## Personal data, encryption and retention

The technician is the **controller** of the clients' data; we (or the
self-hoster) are the **processor**. Supabase, the SMS gateway and the mail
provider are sub-processors and are listed in the privacy policy with their
DPAs. What that means for the schema:

**Personal data columns.** `clients.name/phone/address_line/town/postal_code/
lat/lng/note/contact_id/email`, `equipment.label/note`, `visits.note`,
`appointments.note`, `reminders.phone/body`, `profiles.owner_name/phone`,
`waitlist_signups.email`, and for the client portal the sign-in's e-mail and
phone in `auth.users` (`client_links` holds only ids). Nothing else identifies
a person.

**Encryption.**

| Level | What | Status |
|---|---|---|
| Transport | TLS everywhere; the app pins nothing extra. | always |
| At rest, platform | Supabase encrypts disks and backups (AES-256). | always |
| At rest, per user (**planned, V1**) | The personal-data columns above are stored as `bytea` produced by `pgp_sym_encrypt` with a **per-user data key** kept in Supabase Vault, created by a trigger on sign-up. Two `security definer` functions, `pii_encrypt(text)` and `pii_decrypt(bytea)`, look up the key for `auth.uid()` only, so a user can never reach another user's key and the key never leaves Postgres. `sync_push`/`sync_pull` call them; the reminder job calls `pii_decrypt` at render time, and so does `portal_overview()` (the client portal), which decrypts with the card owner's key for linked cards only, the second server-side reader of ciphertext. Studio, dumps and logical backups then contain ciphertext, and deleting the key is a crypto-shred of every backup copy. | V1 |
| On the phone | SQLite in the app sandbox; optional SQLCipher (`sqlcipher_flutter_libs` with drift) behind a setting for technicians who want it, key in the platform keystore. | V1, optional |

**What we do not do: end-to-end encryption.** The server has to read a phone
number and a name to send `Dzień dobry {imie}…` while the phone is off; that is
the product's core promise. A design where only the phone holds the key would
force the phone to pre-render every reminder and would stop reminders after a
long offline period. The per-user key in Vault is the strongest measure that
keeps the promise; it is documented as such in the privacy policy. A
self-hoster who prefers E2EE can run the reminder job on the phone instead
(documented as a "Later" option).

**Retention and purge.**

- Soft-deleted rows (`deleted_at` set) are kept for **30 days** so every device
  learns about the deletion, then hard-deleted by a nightly `purge-deleted`
  cron; the id goes to `tombstones`. The phone purges its own copies the same
  way. This is the one exception to "nothing is physically deleted".
- `reminders` older than **12 months** are purged (the visit history stays; the
  message body was personal data).
- `waitlist_signups` rows are deleted 12 months after launch or 30 days after
  unsubscribing, whichever comes first; the unsubscribed e-mail is kept as a
  salted hash only, to honour the opt-out. `/prywatnosc/` and `/wypisz/` state
  this to the reader.
- `rate_limits` rows (keyed hashes of IP addresses) live for one day; every
  call to `rate_limit_hit` deletes the older ones.
- `client_links`: an unclaimed invitation is deleted when it expires; a
  claimed link goes with the card (the 30-day purge) or with the portal
  account (its deletion removes the `auth.users` row and the links, nothing
  else, because a portal account owns nothing else).
- Platform backups roll off after 7 days (Pro) – stated in the privacy policy.

**A client of the technician asks to be forgotten.** The technician deletes the
client in the app; the soft delete syncs, pending reminders for that client are
cancelled by the same service call, and the purge removes the rows after 30
days. The app has an "export this client" action so the technician can answer
an access request.

**The technician deletes the account** – see `ARCHITECTURE.md`, "Account
export and deletion".

## Sync support in Postgres

- Trigger `set_server_updated_at()` on every synced table: `new.server_updated_at = now()`.
- `sync_push(changes jsonb) returns jsonb`: for each `{table, rows[]}` upserts
  with `on conflict (id) do update … where excluded.updated_at > <t>.updated_at`,
  forces `user_id = auth.uid()` regardless of payload, and returns the rows it
  rejected as stale so the phone can apply the server's version.
- `sync_pull(since timestamptz) returns jsonb`: every row of every synced table
  with `server_updated_at > since` for the caller, including soft-deleted rows,
  plus `server_now`.
- `sync_push` rejects ids present in `tombstones` (returned as `purged` so the
  phone deletes its copy).
- `sync_push` ignores `client_links` (server-written); `sync_pull` returns it
  like any other table.
- For `reminders`, `sync_push` inserts new `manual` rows and applies a change
  to an existing row only while the server's copy is `pending`; it never takes
  `provider_message_id`, `sent_at` or `error` from the phone. A refused change
  comes back like a stale row, so the phone applies the server's version.
- Both run as `security invoker`, so RLS still applies inside them.

## Due dates

```
next_due_at = add_months(last_visit_at, service_type.cycle_months)
```

`add_months` clamps to the last day of the month (31 Jan + 1 month = 28/29 Feb).
Recompute the two cached columns on `equipment` whenever:

- a `visit_items` row is inserted, deleted or its visit's `done_at` changes;
- `equipment.service_type_id` changes;
- `service_types.cycle_months` changes (recompute all equipment of that type;
  each user's own row, so editing a default never touches another user).

The app does this inside the writing transaction (use case). The server does
not recompute; it trusts the synced caches, which is fine because only the
phone writes visits. If server-side writes ever appear (multi-technician), move
the rule into a Postgres trigger and drop it from the app.

Due-list buckets: `overdue` (`next_due_at < today`), `soon` (within 60 days),
`later`, and `unknown` (`next_due_at is null`).

## Migrations

- Files under `supabase/migrations/` named `YYYYMMDDHHMMSS_<what>.sql`, applied
  in order by `supabase db reset` / `supabase db push`.
- A table's DDL, RLS, policies, indexes and triggers live in the same file.
- Local drift schema versions track the same changes; bump `schemaVersion` and
  add a migration step in `AppDatabase` in the same PR as the SQL file.
- Until the first app release no phone has a database to upgrade, so drift
  schema version 1 is edited in place. Before that release, snapshot it with
  `dart run drift_dev make-migrations` (schema files and generated migration
  tests are committed); from then on every local change bumps `schemaVersion`.
- Never edit an applied migration; add a new one.
