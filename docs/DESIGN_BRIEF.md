# Rewizyta – Design brief

## Contents

- [Source of truth](#source-of-truth)
- [The user and the setting](#the-user-and-the-setting)
- [Principles](#principles)
- [Tokens](#tokens)
  - [Colour](#colour)
  - [Status](#status)
  - [Type](#type)
  - [Shape and size](#shape-and-size)
- [The app](#the-app)
- [The website](#the-website)
- [Copy](#copy)
- [Accessibility](#accessibility)
- [Where the prototype and the docs disagree](#where-the-prototype-and-the-docs-disagree)
- [Open questions](#open-questions)

How the app and the site look and read. Screen inventory and navigation are in
`APP_FLOW.md`; features in `PRD.md`.

## Source of truth

The high-fidelity prototypes in claude.ai/design: "Rewizyta App v2" (the app),
"Rewizyta Waitlist" (the site) and "Rewizyta Design System" (shared tokens).
Colours, type, spacing and Polish copy in them are final unless marked
otherwise. The export lives in the git-ignored `docs/private/design/`, with a
handoff README and `design-tokens.json`. The tokens below are copied from it
(2026-10-06), so this file is enough to build from; when the prototype changes,
update both.

The handoff also proposes a stack and a schema (Riverpod, freezed, feature
folders, its own tables). Those were the design tool's assumptions; the
decisions in `CLAUDE.md`, `TRD.md` and `BACKEND_SCHEMA.md` stand. Take the
look, the copy and the behaviour from the prototype, not the architecture.

## The user and the setting

- A one-person chimney sweep, gas or boiler serviceman, 300–600 clients. Not a
  power user; fewer taps, not more features (`PRD.md`, "Users").
- Uses the app standing at a door, in a car, in a boiler room: one hand, often
  with dirty fingers, in bright sun or a dark cellar, frequently with no
  signal.
- Mostly Android, often a mid-range phone a few years old, large system font
  common.
- Opens the app in short bursts: who is next, who is due, who is calling.

## Principles

1. **The answer on the first screen.** Dziś and Terminy show the next action
   without a tap: who, where, what is due, booked or not.
2. **Status by colour and word, never colour alone.** Every status tag carries
   its text ("po terminie 12 dni", "za 5 dni", "zrobione").
3. **Big targets.** Touch targets at least 48 px; primary buttons 54 px,
   full width.
4. **Prefill, then confirm.** Service and cycle from the catalogue, today's
   date, the price. Typing is the exception.
5. **Calm offline.** No spinners for local data and no "no connection" errors.
   One banner reassures ("Bez zasięgu. Wszystko działa.") and counts what
   waits to sync; every offline action's toast says it goes out "gdy wróci
   zasięg".
6. **Borders, not shadows. Text, not icons.** Flat surfaces with 1 px lines;
   the only glyphs are "›" and "‹". Shadows only on the phone frame and the
   call overlay.
7. **A tool, not a startup.** No gamification, no illustrations, no carousels.

## Tokens

### Colour

One palette for the app and the site (`apps/website/web/styles.css` already
uses it). Light only; there is no dark theme in the design.

| Token | Hex | Use |
|---|---|---|
| `paper` | `#F6F4EF` | Screen and sheet background |
| `white` | `#FFFFFF` | Cards, list groups, inputs, tab bar, selected segment |
| `ink` | `#1D1C1A` | Text, primary buttons, emphasis borders, selected day, offline banner, toasts |
| `text2` | `#3E3B36` | Addresses, body on white |
| `muted` | `#5E5A53` | Secondary lines, subtitles, inactive tabs |
| `line` | `#DAD5CB` | Default 1 px borders and dividers |
| `lineLight` | `#ECE8E0` | Segmented track, grey tags, disabled button background |
| `inputBorder` | `#A8A296` | 1.5 px input borders; toggle off |
| `placeholder` | `#8A857C` | Placeholder and disabled text |
| `selectedBg` | `#FDF1E6` | Selected option, today's header in the week view |
| `accent` | `#EE8A3A` | Due dates and progress only: active-tab bar, today dot, progress bars, pending-sync count. Ink text on it, never white |
| `accentBg` / `accentOnBg` | `#FBE3CF` / `#8A3F0C` | "Soon" tags |
| `accentText` | `#9A4A12` | Small orange labels on white ("NASTĘPNA", "NAJBLIŻSZE 60 DNI") |
| `ok` | `#3D8B55` | Toggle on, answer-call button |
| `okBg` / `okOnBg` | `#DCEEDF` / `#245B34` | "zrobione", "umówiony", SMS sent |
| `error` | `#B23A28` | Field errors |
| `errorBg` / `errorOnBg` | `#F7D9D3` / `#8E2A1B` | Overdue tags and banner, "PO TERMINIE" label |
| `callDecline` | `#C8412F` | Reject-call button |
| `phoneDark` / `phoneDarkText` | `#2A2825` / `#C9C4BA` | Incoming-call screen |

### Status

`daysToDue = nextDue − today`, one rule for every list and tag:

| Status | Rule | Tag | Colours |
|---|---|---|---|
| overdue | `< 0` | "po terminie {n} dni" | `errorBg` / `errorOnBg` |
| soon | `0` | "dzisiaj" | `accentBg` / `accentOnBg` |
| soon | `1…60` | "za {n} dni" | `accentBg` / `accentOnBg` |
| later | `> 60` | "za {n} mies." (days / 30, rounded) | `lineLight` / `text2` |
| none | no last visit | "bez terminu" | `lineLight` / `text2` |

### Type

IBM Plex Sans 400/500/600/700 for text; IBM Plex Mono 400/500/600 for dates,
times, phone numbers, codes, km and counts. Both are bundled (the site
self-hosts them in `apps/website/web/fonts/`).

| Style | Size / weight | Notes |
|---|---|---|
| display (site) | 58 / 700 | line height 1.04, −0.025em; `clamp(36px, 6vw, 58px)` |
| h2 (site) | 38 / 700 | line height 1.1, −0.02em |
| screenTitle | 30 / 700 | −0.02em |
| h3 | 21 / 600 | line height 1.25 |
| cardName | 20 / 700 | next-stop card |
| body | 17 / 400 | line height 1.5 |
| listTitle | 16 / 600 | |
| secondary | 15 / 400 | screen subtitles, in `muted` |
| small | 14 / 400 | second lines of list rows and cards ("town · service"), in `muted` |
| sectionLabel | 13 / 600 | uppercase, +0.04em |
| tag | 12–13 / 600 | the only text allowed below 15 px |

### Shape and size

| | Value |
|---|---|
| Radius | tag 5, inline box 8, control 10, card 12 (large card 14), bottom sheet 20 (top corners) |
| Borders | default 1 px `line`; emphasis 1.5 px `ink`; input 1.5 px `inputBorder` |
| Heights | primary button 54, secondary button 48, input 50–52, list row 64 (tall 68), toggle 56 × 32 |
| Screen padding | 14 top, 16 sides, 24 bottom |
| Minimums | touch 48, text 15 (tags excepted) |

## The app

- **Theme in code** (`apps/mobile/lib/app/theme/`). `ColorScheme.fromSeed`
  cannot produce these values, so `AppTheme.light()` builds the `ColorScheme`
  by hand (`surface` = `paper`, `primary` = `ink`, `outline` = `inputBorder`,
  `outlineVariant` = `line`, `tertiary` = `accent`…) and sets the component
  themes (buttons, inputs, cards, chips, switch, sheets, snack bars) to the
  radii, heights and borders above, with elevation 0. `AppColors` carries what
  Material has no slot for: `accent`, `accentText`, `selectedBackground`,
  `text2` and the background/foreground pair of each status (overdue, soon,
  later, done). `AppFonts.sans` / `AppFonts.mono` and `AppRadius` hold the
  rest; IBM Plex is bundled as TTF in `apps/mobile/assets/fonts/`. Light only.
  No colour literals in widgets.
- **Spacing.** `AppSpacing` (4 / 8 / 16 / 24 / 32) plus the 14 px screen top
  padding and 12 px card gaps the prototype uses; add a constant rather than
  a literal.
- **Navigation.** Four text tabs (Dziś · Terminy · Klienci · Więcej). Active:
  `ink`, 600, a 3 px `accent` bar; inactive: `muted`, 400. No icons.
- **Patterns.** Segmented control (track `lineLight`, 3 px padding, active
  segment white); the next-stop card (white, 1.5 px ink border, radius 14);
  64 px list rows in a `50px 1fr auto` grid (mono time, two text lines, a
  tag); bottom sheets for every short task (save visit, book, SMS, directions,
  import); toasts at the bottom (ink, paper text, 3.4 s).
- **Custom widgets** only where Material has nothing: week strip, next-stop
  card, the call overlay, the monthly bar chart.

## The website

- Same tokens. Max width 1080 px, 20 px side padding, one column on phones
  with a sticky call to action below 720 px.
- Logo: a 28 px ink square (radius 6) with a 10 px orange dot, then
  "Rewizyta" 19 / 700. Also the basis for the app icon.
- Static, no third-party scripts, no cookies, no consent banner (`CLAUDE.md`,
  "Conventions – website"). The handoff's "Google Fonts" note does not apply:
  fonts are self-hosted.

## Copy

- Polish, second person ("Ty"), short, no tech jargon. Plain imperative on
  buttons ("Dodaj klienta", "Zapisz wizytę", "Umów termin").
- Dates `DD.MM.RRRR` (short forms `pn 29.09`), times `09:30`, phone numbers
  `601 234 567`, money `180 zł`, all in mono. Formatting lives in
  `rewizyta_view_models`.
- Every string through `app_pl.arb`. Counts always use an ICU `plural` with
  Polish's `one`, `few` and `many` forms (`1 wizyta`, `2 wizyty`,
  `5 wizyt`, `22 wizyty`; 12–14 take `many`), never concatenation.
- The prototype's copy is final; take strings from it rather than writing new
  ones.

## Accessibility

- Contrast (checked 2026-10-06): every text pair in use meets WCAG 2.2 AA
  (4.5:1); the weakest are `error` on paper 5.4 and `accentText` on paper 5.7.
  `placeholder` (3.0–3.7) is for placeholders and disabled text only, never
  content. On `accent` use ink text (6.8), never white.
- Non-text contrast (3:1) falls short in two places: the `accent` tab bar on
  white (2.5), which is fine because the active tab is also ink and 600; and
  the 1.5 px `inputBorder` on white (2.5), which is not. Inputs need a label
  above them or a darker border; decide before M2's forms.
- Layouts survive 200% system text scale: the fixed row heights are minimums,
  not fixed heights; no clipped labels.
- Status tags read their word; the "›" and "‹" glyphs get semantic labels.
- Nothing depends on a swipe or a long press alone.

## Where the prototype and the docs disagree

The prototype goes beyond, or against, decisions in `PRD.md` and `TRD.md` in a
few places. Until one side is changed, the docs win for behaviour and the
prototype wins for looks:

| Prototype | Docs today |
|---|---|
| Cycle and service per client, equipment as free-text tags | Equipment rows, each with its own service type and due date (`BACKEND_SCHEMA.md`) |
| Template tokens `[usługa] [data] [telefon] [podpis]` | Placeholders `{imie} {usluga} {termin} {firma} {telefon}` |
| Fixed slots 08:00 … 15:30 | Slots from the planner settings (`slots_per_day`, `slot_minutes`, hours) |
| Confirmation SMS on booking, a reschedule SMS when the route is reordered | Only due-date reminders in the MVP |
| "+500 SMS" package, "212 / 500" usage | Passes with a fair-use pool and 200-SMS top-ups (`PRD.md`, "Pricing") |
| "Wyślij do księgowej" sends the summary by e-mail | CSV/PDF export (V1) |
| Excel import through the website | Not planned |
| Reminder offsets chips 30 / 14 / 7 / 1 | Any offsets, default 30 and 7 |

## Open questions

- Resolve each row of the table above: change the docs, or change the
  prototype.
- Dark theme: none designed. Ship light only until one is.
- App icon and store graphics from the logo mark.
