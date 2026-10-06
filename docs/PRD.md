# Rewizyta – Product requirements (PRD)

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
- [Client portal](#client-portal)
  - [Stage 1 – see my technicians](#stage-1--see-my-technicians)
  - [Stage 2 – an account](#stage-2--an-account)
  - [Open points](#open-points)
- [Pricing](#pricing)
  - [How it is sold](#how-it-is-sold)
  - [Why this shape](#why-this-shape)
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
- **The technician's client (after MVP):** a homeowner or a building manager
  with one or more technicians. Opens the client portal from a reminder SMS or
  with an e-mail code, in whatever browser is at hand, and installs nothing.

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
- Two-way SMS: the client replies "TAK" and is booked into the proposed slot
  (or confirms in the client portal, stage 2, which needs no receiving number).
- Web dashboard for the accountant / office.
- Client portal on the website (see "Client portal"): the client signs in
  with an e-mail code and sees every technician who services them, the due
  dates, the next booked visit and the history; stage 2 adds an account,
  phone verification and booking requests.

### Not in scope

- Invoicing and accounting (export to the accountant is enough).
- Inventory, parts, warehouse.
- A client-facing app. The web portal for clients (see "Client portal") is
  the one client-facing surface, and only after the MVP ships.
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
6. **Client checks the portal** (after MVP) → opens the link from the reminder
   SMS or types an e-mail and the code it receives; sees the technicians, the
   due dates and the next visit; (stage 2) asks for a date or confirms one.

## Client portal

Added 2026-10-01; until then "a client-facing app or portal" was out of scope.
A web page, not an app, for the technician's clients: one place where a
homeowner or a building manager sees every technician who services them and
when each next visit is due. Built in stages after the MVP ships, on the synced
data the server already holds for reminders. The design is in
`TRD.md`, "Client portal"; the tables in `BACKEND_SCHEMA.md`, `client_links`.

**Why.** Three reasons, in order:

1. A client with a chimney sweep, a gas serviceman and a boiler serviceman
   has three due dates to remember and three people to call. A page that lists
   them is the client's half of "no client gets lost".
2. It is a selling point no flat-fee competitor offers, and it answers "when
   were you last here?" without a call.
3. It is a way in: every client who signs in sees the Rewizyta name, and a
   technician who is not on it can be invited by their own client.

**What it must not do.** Add work for the technician. Everything the portal
shows is already entered for reminders; the only extras are optional, an
e-mail on the client card and a `{portal}` placeholder in the SMS template.
Nothing on the portal ever writes to the technician's data; the phone stays
the source of truth.

### Stage 1 – see my technicians

- The client opens `/klient/` on the website, types an e-mail address and
  receives a six-digit code; typing the code signs them in. No password, no
  app to install.
- The page lists the technicians who have that e-mail on one of their client
  cards, or who invited this client: business name, a phone to call, each
  serviced item with its service type, last visit and next due date, the next
  booked appointment, and the visit history (dates and what was serviced). No
  prices, no notes, nothing about other clients.
- Two ways a client gets linked to a technician: the technician saves the
  client's e-mail on the client card (the field says it is for the portal),
  or the reminder SMS carries a short personal link and the first e-mail that
  signs in through it is linked to that card. The technician can switch the
  portal off for the whole account in Settings.
- A technician who is not on Rewizyta cannot appear; the page says so and
  offers a link to send them.

### Stage 2 – an account

- The client can turn the sign-in into an account: a name, a password or a
  passkey instead of a code each time, and a phone number verified by SMS
  code, which links every client card with that number, so technicians no
  longer have to type e-mails.
- Self-service that reaches the technician as a request, never as a change:
  "ask for a date", confirm or cancel a booked appointment, propose a
  correction to the contact details. The technician accepts in the app with
  one tap. This covers what two-way SMS was meant to do, without a receiving
  number and without giving up the alphanumeric sender.
- Download the own service history (an access request answered by
  self-service).
- Delete the portal account; the technician's card is untouched.

### Open points

- Phone-number matching (stage 2) links cards the technician never marked for
  the portal, which is why the account-wide switch exists. Decide whether it
  defaults on or off for existing technicians when stage 2 ships.
- A reassigned e-mail or phone number would show a stranger the previous
  holder's due dates. The reminder SMS to that number already carries the
  same information, so the exposure is not new, but the privacy notice has to
  say it.
- Whether the invitation link in the SMS is worth its length (about 30 to 40
  characters of a 160-character message) before stage 2's phone matching
  makes it unnecessary.

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
  the phone is off. The client portal shows a client their own card on the
  technician's instruction (the e-mail typed on the card, the link put in the
  SMS, the account-wide switch); for the portal sign-in itself we are the
  controller, with its own section in the privacy notice. See `BACKEND_SCHEMA.md`,
  "Personal data, encryption and retention".
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
