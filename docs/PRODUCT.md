# Rewizyta – Product

## Contents

- [Problem](#problem)
- [Users](#users)
- [Core promise](#core-promise)
- [Feature set](#feature-set)
  - [MVP](#mvp)
  - [V1](#v1)
  - [Later](#later)
  - [Not in scope](#not-in-scope)
- [Key flows](#key-flows)
- [Pricing](#pricing)
  - [How it is sold](#how-it-is-sold)
  - [Why these numbers](#why-these-numbers)
- [Platform decisions and risks](#platform-decisions-and-risks)
- [Open questions](#open-questions)

## Problem

A one-person field technician (chimney sweep, gas or boiler serviceman) has
300–600 clients who each need a service every 3 or 12 months. Today he keeps the
due dates in his head, a paper notebook or phone contacts.

- Clients drift away to competitors because nobody reminds them that a service is due.
- When a client calls, he doesn't know who it is, what equipment they have or when
  he was last there.
- In the field there is often no signal, so anything that needs the internet to
  work is useless exactly when he needs it.

## Users

- **Primary:** the technician himself. Works alone, from a phone, mostly Android.
  Not a power user; wants fewer taps, not more features.
- **Secondary (later):** an accountant who receives a monthly summary; a second
  technician in the same business.

## Core promise

**No client gets lost, and the app works on one phone, without signal.**

Everything else is measured against that sentence.

## Feature set

### MVP

| Area | What it does |
|---|---|
| Clients | Name, phone, address, equipment, notes. Add by hand, paste a number, or import from phone contacts. |
| Service types and cycles | Chimney every 12 months, coal stove every 3 months, gas every 12, and so on. Editable list with sensible Polish defaults. |
| Due list | Who is due: overdue, next 60 days, later. Each row shows whether a visit is already booked. |
| Visit log | What was done at a client and for how much. Saving a visit updates the next due date automatically. |
| Appointments | Book a day and hour. Day plan and week view. |
| SMS reminders | Sent automatically 30 and 7 days before the due date (offsets configurable), from a template with placeholders such as `{imie}`, `{usluga}`, `{termin}`, `{firma}`, `{telefon}`. |
| Offline-first | Everything works with no signal and syncs later. The phone is the source of truth. |

### V1

- Caller card on incoming calls (Android): name, equipment, last visit, next due.
- Open the address in Google Maps / Apple Maps; order the day's stops by route.
- Monthly summary (visits, revenue) and CSV/PDF export for the accountant.
- "Przypomnienia" passes and SMS top-ups through Google Play Billing (see
  "Pricing"); first-run onboarding (profile, sender name, import contacts).

### Later

- PDF service report with the client's signature on the phone.
- Multiple technicians per business.
- Two-way SMS: the client replies "TAK" and is booked into the proposed slot.
- Web dashboard for the accountant / office.

### Not in scope

- Invoicing and accounting (export to the accountant is enough).
- Inventory, parts, warehouse.
- A client-facing app or portal.
- Anything that requires signal in the field.

## Key flows

1. **Add a client** → name, phone (from contacts or pasted), address, one or
   more pieces of equipment, each tied to a service type. Optional: date of the
   last service, so the due date is right from day one.
2. **Record a visit** → pick the client, tick which equipment was serviced, enter
   the price and a note. Next due dates are recomputed and the reminders for the
   new date will be created by the server.
3. **Work the due list** → open a client, call or SMS them, book an appointment.
   The row turns to "booked".
4. **Run the day** → today's plan, ordered by route; tap to navigate, call, or
   record the visit on the doorstep.
5. **Client calls** (V1) → caller card pops with everything the technician needs
   to sound like he remembers them.

## Pricing

**Free app, paid reminders.** The app is free forever: clients, equipment, due
list, visits, calendar, caller card. One paid thing, "Przypomnienia", turns on
the server-sent SMS. That charges exactly for what costs money, gives the Play
listing a free tier without paying for anyone's messages, and makes the
open-source story trivial: a self-hoster runs the same free app with their own
gateway key and billing switched off. There is no feature fork.

Three products, all one-time purchases:

| Product | What it does |
|---|---|
| Przypomnienia, 12 months | Server-sent reminders for a year; the cheaper rate per month. |
| Przypomnienia, 1 month | The same for 30 days. |
| Top-up pack, 200 SMS | Extra messages above the fair-use pool. |
| Fair-use pool while a pass is active | 300 SMS / month, manual messages included. |
| Trial | 30 days of reminders; the waitlist promo code may extend it. |

Prices are set in the Play listing and on the website at launch. The price
points, the margin sheet behind them and the competitor research live in
`docs/private/BUSINESS.md`, which is git-ignored.

### How it is sold

**In-app, through Google Play Billing, as one-time time passes**, not as an
auto-renewing subscription. Each purchase extends `profiles.paid_until` by
30 or 365 days; the top-up adds to `profiles.sms_balance`. One mechanism
covers all three products, and there is no subscription lifecycle to handle
(no grace periods, pauses or renewal webhooks). Renewal is a push and an e-mail
a week before the pass expires. The purchase is verified server-side by the
`verify-purchase` edge function against the Play Developer API; the phone
never grants itself anything.

Why not a web checkout at 0% Play fee (Play's EEA conditions, June 2026, allow
consuming a web-bought pass in-app as long as the app never links to the
purchase): the app would have to stay silent about how to buy, which is a
conversion leak for a "fewer taps" user, and every way to put a buy button in
the app costs 10% plus a transaction-reporting integration with Google, or 7%
plus our own in-app checkout. Neither is less work than Play Billing.

What Play Billing buys for its 15% (10% service fee + 5% billing fee, EEA,
first 1M USD a year):

- One tap to buy, restore on a new phone, refunds and disputes handled by
  Google. The lost-phone flow covers the purchase for free.
- Google is the merchant of record in the EU. We invoice Google monthly with
  reverse charge and never issue a customer invoice; a sole trader downloads
  his VAT invoice from Google after adding his NIP to the payments profile.
- The same code path serves iOS later, where in-app purchase is mandatory.
- BLIK works on Google Play in Poland for one-time purchases only, which is
  another reason the passes are one-time products and not subscriptions.
  Cards, Play balance and carrier billing work too.

**RevenueCat** is not needed for one store and three consumable products; a
single verification function is smaller than the integration. Revisit when the
App Store path is added and one entitlement has to be reconciled across stores.

### Why this shape

The Polish market for this niche sells a flat monthly price with SMS included;
SMS-packages-only would look stingy and would make every reminder a visible
cost, which works against the core promise. We sit between the cheapest and the
most expensive flat-fee competitor, above the cheap end because of offline mode
and the caller card. SMS is the only variable cost, so the fair-use pool is
sized so that a typical technician never touches it and a heavy one buys
top-ups instead of the price rising for everyone. The numbers behind this
(gateway rates, per-subscriber margin, fixed costs, break-even) are in
`docs/private/BUSINESS.md`.

## Platform decisions and risks

- **Android first.** The caller card needs `READ_PHONE_STATE` and an overlay or a
  `CallScreeningService`. Google Play restricts call-log permissions, but caller-ID
  apps are a permitted category; plan for the review and a privacy-policy page on
  the website. iOS does not allow a custom overlay; at most a CallKit caller-ID label.
- **SMS cost and sender name.** Registering an alphanumeric sender (e.g.
  `KOMINIARZ`) with a Polish gateway (SMSAPI, SerwerSMS) takes days and paperwork.
  Start it early. Messages are the main running cost; the app shows the balance.
- **Route optimisation.** Nearest-neighbour on straight-line distance, computed
  on the phone, is enough. The technician sets slots per day, working hours,
  home and travel speed; fixed-hour appointments stay put, the rest are
  ordered, and the planner shows the distance between stops. No paid routing API.
- **GDPR / RODO.** The database holds names, phone numbers and addresses of the
  technician's clients. The technician is the data controller; we are the
  processor, with Supabase, the SMS gateway and the mail provider as
  sub-processors. Consequences: EU hosting only, a DPA in the terms, a
  privacy policy listing sub-processors, export and deletion as server
  functions, 30-day purge of deleted rows, and (V1) per-user encryption keys
  so dumps and backups hold ciphertext. Full end-to-end encryption is ruled
  out because the server must read a name and a number to send an SMS while
  the phone is off. See `DATABASE.md`, "Personal data, encryption and retention".
- **Backup and account loss.** Since the phone is the source of truth and sync is
  the backup, a technician who loses the phone must be able to log in on a new one
  and pull everything back. This is a first-class requirement of the sync design.

## Open questions

- Two-way SMS ("reply TAK to book"). Cost is settled: one dedicated 9-digit
  receiving number for the whole platform on a 12-month contract at SMSAPI or
  SerwerSMS (rate in `docs/private/BUSINESS.md`); shared numbers and prefixed short codes are unusable
  for our clients. The blocker is branding: an alphanumeric sender such as
  `KOMINIARZ` cannot receive replies, so two-way means reminders arrive from a
  bare number. Until multi-technician accounts make a booking bot worth that,
  the reminder template carries `{telefon}` and the client calls or texts the
  technician directly. Still to check before committing: whether reminders to
  existing clients count as service communication rather than marketing under
  the Polish telecom consent rules.
