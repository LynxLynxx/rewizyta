# Rewizyta – App flow

## Contents

- [Scope](#scope)
- [Start-up and gates](#start-up-and-gates)
- [Navigation](#navigation)
- [Screens](#screens)
- [Journeys](#journeys)
- [Cross-cutting behaviour](#cross-cutting-behaviour)
- [Website flows](#website-flows)
- [Open questions](#open-questions)

## Scope

Every screen of the mobile app, how they connect and what the user does on
each. What the features are and why is in `PRD.md`; how they are built is in
`TRD.md`; the order they are built in is in `IMPLEMENTATION_PLAN.md`. Screen
names are the Polish titles the user sees; route paths are the constants in
`apps/mobile/lib/router/route_paths.dart`.

The screens follow the claude.ai/design prototype "Rewizyta App v2" (export
and handoff notes in the git-ignored `docs/private/design/`; looks, tokens and
the places where it disagrees with the other docs in `DESIGN_BRIEF.md`). Its
copy is final; take strings from it.

Status today (2026-10-06): only the client list (`/clients`) exists. Everything
else here is the target for the MVP milestones M2–M7 and V1, and changes when
a milestone decides otherwise; update this file when it does.

## Start-up and gates

```
launch
  └─ bootstrap (config → Supabase → DI → reporting → runApp)
       ├─ no session ─────────────► Logowanie (sign in / create account)
       │                               └─ new phone, existing account ─► restore (pull everything) ─┐
       ├─ session, no profile ────► Onboarding ─────────────────────────────────────────────────────┤
       └─ session and profile ────────────────────────────────────────────────────────────────────► Dziś
```

- The gates are `GoRouter` redirects driven by a session cubit through
  `refreshListenable` (`app_router.dart`). A screen never checks auth itself.
- After the first sign-in on a phone the app opens from the local database:
  no network call stands between launch and the first screen.
- Restore on a new phone shows progress while the first pull runs, then lands
  on Dziś. It is the only screen that waits on the network, and it can be left
  running in the background.

## Navigation

A bottom navigation bar with four tabs (`StatefulShellRoute.indexedStack`, so
each tab keeps its own stack and scroll position):

| Tab | Route | Screen | Why it is a tab |
|---|---|---|---|
| Dziś | `/today` | Day plan, Dzień / Tydzień toggle | Where the working day starts. |
| Terminy | `/due` | Due list | The core promise: nobody gets lost. |
| Klienci | `/clients` | Client list | Lookup during a call. |
| Więcej | `/more` | Settings, summary, account | Everything used rarely. |

Klient and the forms are pushed above the shell; the client card keeps the
tab bar and adds a sticky "Zapisz wizytę" above it. Short tasks (save a visit,
book, SMS, directions, import) are bottom sheets, not routes. The system back
button closes a sheet or pops; on a tab root it goes to Dziś, and on Dziś it
leaves the app.

## Screens

| Screen | Route | Reached from | Main actions | Milestone |
|---|---|---|---|---|
| Logowanie | `/sign-in` | Gate | Sign in, create account, reset password | M5 |
| Pierwsze uruchomienie | `/onboarding` | Gate, Więcej | Four steps with orange progress bars; profile and trades, then where the clients come from (Z kontaktów w telefonie / Z pliku Excel / Wpiszę ręcznie), promo code, notification permission. "Pomiń" on the first step | M7 |
| Dziś – Dzień | `/today` | Tab | Subtitle "28.09 · 4 wizyty · ok. 18,5 km · 1 zrobione"; Dzień / Tydzień toggle; 7-day strip (dot on days with visits); red banner "N klientów po terminie bez umówionej wizyty ›" → Terminy; the next-stop card (Dojazd, Zadzwoń, Zapisz wizytę); the rest of the day as rows (time, name, town · service, "zrobione" or "{km} km"); "Ułóż trasę najkrócej · {x} km mniej". Empty: "Wolne." + "Otwórz terminy" | M4 |
| Dziś – Tydzień | `/today` (toggle) | Dziś | One card per day: "{n} · {km} km" or "wolne", rows of time + "name · town" | M4 |
| Terminy | `/due` | Tab | "{n} klientów do obsłużenia · SMS-y idą same"; groups "PO TERMINIE" and "NAJBLIŻSZE 60 DNI"; each row a status tag plus "umówiony pn 29.09, 09:30" or the SMS status, and a round "Dzwoń" button | M3 |
| Klienci | `/clients` | Tab | Count; "Dodaj klienta", "Import z kontaktów", "Wklej numer"; search "Nazwisko, miejscowość, telefon" (digits match without spaces); list by name in Polish order with status tags | M2 |
| Klient | `/clients/:id` | Klienci, Terminy, Dziś, caller card | "‹ {previous}"; name, phone, address, due status, equipment tags, note; Zadzwoń, SMS, Dojazd, Umów termin; history; sticky "Zapisz wizytę" | M2–M3 |
| Nowy klient / edycja | `/clients/new`, `/clients/:id/edit` | Klienci, Wklej numer, Klient | Name or company, phone, address, town, service chips (set the cycle), cycle, "Ostatnia wizyta" (DD.MM.RRRR) with a live "Następny przegląd: {date}", or the hint "Nie pamiętasz? Zostaw puste – policzymy po pierwszej wizycie." Save enabled when the name has 2+ characters and the phone 9+ digits | M2 |
| Zapisz wizytę | sheet | Klient, Dziś | Work-done chips, price in zł, "Następny przegląd {date}" | M3 |
| Umów termin | sheet | Klient, Terminy, call screen | 7-day picker ("{n} wiz." / "wolne"), free slots, "Umów na {day}, {time}"; replaces the client's open booking | M4 |
| SMS | sheet | Klient | Prefilled from the template, editable, characters and SMS count | M6 |
| Dojazd | sheet | Klient, Dziś | Open in maps, copy the address | M4 |
| Import z kontaktów | sheet | Klienci, onboarding | Checklist of contacts, numbers already in the book greyed out ("już w bazie"), "Dodaj {n} kontaktów" | M2 |
| Więcej | `/more` | Tab | Przypomnienia SMS · Podsumowanie miesiąca · Ustawienia · Pierwsze uruchomienie; profile line at the bottom | M7 |
| Przypomnienia SMS | `/more/reminders` | Więcej | Auto-send toggle, offsets, SMS usage bar, template preview, "ZAPLANOWANE" queue, buy more | M6, buying V1 |
| Podsumowanie miesiąca | `/more/summary` | Więcej | Month switcher, visits and the change on last month, revenue, average, weekly bars, services, next month's due count; send to the accountant | V1 |
| Ustawienia | `/more/settings` | Więcej | Name, phone, trade chips, SMS template with placeholder chips and live preview ("{chars} znaków · {n} SMS"), offsets, services with cycles; planner settings, account (export, delete, sign out) | M5–M7 |
| Połączenie przychodzące | system overlay | Incoming call | "KARTA KLIENTA": name, phone, due tag, address, equipment, last two visits, note; Odrzuć / Odbierz. Answer opens Klient | V1 |
| Połączenie wychodzące | `/call/:clientId` | Zadzwoń | "Łączenie…", then a timer; "Umów termin" or "Zmień termin wizyty"; hang up → toast "Rozmowa mm:ss z: {name}." | V1 |

## Journeys

The key flows from `PRD.md` as tap paths. Fewer taps is the product goal, so
each path is a budget: a change that adds a step needs a reason.

1. **Add a client.** Klienci → Dodaj klienta (or Wklej numer, which opens the
   form with the phone filled in) → name, phone, address, service chip, last
   visit → Zapisz → Klient. The next due date shows while typing; without a
   last visit the client is "bez terminu" until the first visit.
2. **Record a visit.** Dziś → next-stop card → Zapisz wizytę (sheet: work-done
   chips, price) → Zapisz. The due date moves, the appointment is done and the
   card moves to the next stop.
3. **Work the due list.** Terminy → Dzwoń on the row → after the call, Umów
   termin → day and slot → Umów. The row shows "umówiony pn 29.09, 09:30".
4. **Run the day.** Dziś → Ułóż trasę najkrócej (reorders the open stops; fixed
   hours stay) → Dojazd (sheet → maps) → Zadzwoń → Zapisz wizytę.
5. **Client calls (V1).** The client card shows over the incoming call;
   Odbierz, and after the call Klient is open.
6. **Lost phone.** New phone → Logowanie with the same account → restore →
   Dziś with everything back, purchases included.
7. **Leave.** Więcej → Ustawienia → Eksportuj dane (offered first) → Usuń konto
   → re-authenticate → type the confirmation word → local wipe → Logowanie.

## Cross-cutting behaviour

- **Offline.** Every screen works without signal. Without one, a dark banner
  under the status bar says "Bez zasięgu. Wszystko działa." with the count of
  changes waiting to sync ("2 do wysłania", from `SyncStatusObserver`);
  nothing blocks on it. Every action taken offline confirms with a toast that
  it goes out "gdy wróci zasięg". Actions that need the server (buy, export, delete account, promo code) say
  "Wymaga internetu" and stay disabled until online.
- **Empty states.** Every list has one that says what to do next ("Dodaj
  pierwszego klienta", "Na dziś nic – zobacz Terminy").
- **Toasts** sit at the bottom, ink with paper text, for 3.4 s. Errors reach
  them through `ErrorHandlerStateMixin`, confirmations ("Zapisano", "Trasa
  ułożona") through `SignalHandlerStateMixin`; field errors are inline.
- **Destructive actions** (delete client, delete equipment) are soft deletes
  with an "Cofnij" snackbar, not a confirmation dialog. Deleting the account is
  the one confirmed action.
- **Deep links.** Push notifications open a route (`/due`, `/more/reminders`);
  the caller card opens `/clients/:id`.

## Website flows

The site (`apps/website`) is not part of the app; its flows are in `TRD.md`,
"Websites" and "Client portal". In short: waitlist sign-up → confirmation mail
→ `/potwierdz/` → promo code; `/wypisz/` from any mail; after the MVP the
client portal at `/klient/` (e-mail code → overview of their technicians).

## Open questions

- Can the app be used before an account exists (local-only, sign up later to
  sync)? It fits "works without signal", but the promo code and restore need an
  account anyway. Today's assumption: sign in first.
- The SMS sheet on Klient sends through the server (hard rule 6: it writes a
  `reminders` row of kind `manual`), so it needs an active pass and counts
  against the pool. Does a technician without a pass get the system SMS app
  instead (`url_launcher`, free, no history)?
