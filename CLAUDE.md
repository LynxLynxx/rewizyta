# Rewizyta – working notes for contributors and AI assistants

Offline-first Flutter app (plus two Jaspr websites and a Supabase backend) that
keeps a one-person field technician's clients, service cycles, due dates,
appointments and SMS reminders. Read `docs/PRODUCT.md` for what we are building
and why, `docs/ARCHITECTURE.md` for how, `docs/DATABASE.md` for the schema and
`docs/TASKS.md` for what is next. Keep those documents current when you change
the thing they describe.

## Repo map

| Path | What | Toolchain |
|---|---|---|
| `apps/mobile` | The Flutter app (package `rewizyta`): bootstrap, DI container, router, pages, theme. | Flutter 3.47 / Dart 3.13, flutter_bloc, go_router, drift_flutter, supabase_flutter |
| `packages/rewizyta_models` | Domain: Equatable entities, typed exceptions, pure rules (`nextDue`). Leaf, pure Dart. | equatable |
| `packages/rewizyta_repositories` | Data: drift `AppDatabase`, tables, DTOs, repository interfaces + impls, outbox. Pure Dart. | drift, json_serializable |
| `packages/rewizyta_services` | Domain services (the only thing cubits inject), observers, sync managers, and the adapter interfaces for analytics, crash reporting and push. Pure Dart. | uuid |
| `packages/rewizyta_blocs` | Cubits + Equatable states, error/signal side-channel mixins, `AppBlocObserver`. Re-exports flutter_bloc. | flutter_bloc, bloc_test |
| `packages/rewizyta_view_models` | What widgets render: view models, presentation enums, formatters, `LocalizedException`. | equatable, intl |
| `packages/rewizyta_localization` | `app_pl.arb` and the generated `AppLocalizations`; `context.l10n`. | gen-l10n |
| `packages/rewizyta_shared` | `DependencyProvider` (get_it wrapper), `Optional`. Leaf, pure Dart. | get_it |
| `apps/waitlist` | Pre-launch landing page with a sign-up form and promo code. | Jaspr 0.23, static mode, own lockfile |
| `apps/website` | Product website (features, pricing, privacy, contact). | Jaspr 0.23, static mode, jaspr_router, own lockfile |
| `supabase/` | Backend: `migrations/` (SQL), `functions/` (Deno/TS edge functions), `config.toml`. | Supabase CLI |
| `tool/` | `check_layering.sh`, `format.sh` (used by the melos scripts). | bash |
| `docs/` | Design documents. | Markdown |

Melos 8 with a pub workspace at the root: the app and every `packages/rewizyta_*`
share one lockfile. The Jaspr sites are **not** workspace members (jaspr_builder
pins an older `analyzer` than drift_dev needs); they are driven through the
`sites:*` melos scripts. Don't try to add them to `workspace:` again.

## Commands

```bash
melos bootstrap        # pub get everywhere (sites via the post-bootstrap hook)
melos run gen          # build_runner (json_serializable, drift) where needed
melos run l10n         # regenerate AppLocalizations from app_pl.arb
melos run analyze      # dart analyze --fatal-infos, every package
melos run layering     # grep-based import-direction audit (tool/check_layering.sh)
melos run secrets      # gitleaks + PII greps over the tree (tool/check_secrets.sh); CI runs it on the history too
melos run hooks        # once per clone: pre-commit hook that runs the secrets scan on staged files
melos run test         # flutter test in every package with test/
melos run check        # gen + l10n + format + analyze + test, app and sites
melos run --list       # everything else (serve a site, build the sites, ...)
supabase start / db reset / functions serve     # from supabase/
```

Generated files (`*.g.dart`, `*.drift.dart`, `lib/generated/`) are git-ignored.
Run `melos run gen && melos run l10n` after pulling. The order gen → l10n →
format → analyze matters; `melos run check` does it right.

## Hard rules

1. **The UI never waits on the network.** Cubits subscribe to drift streams
   through services. Every write goes to the local database and an `outbox`
   row in the same transaction; `SyncService` pushes the outbox and pulls
   changes later. If a feature "needs" a network call to render, redesign it.
2. **IDs are UUIDs generated on the phone.** Records must be creatable offline.
3. **`next_due_at` is derived, never authored.** It is `last_visit_at` plus the
   service type's cycle (`nextDue` in `rewizyta_models`). The column on
   `equipment` is a cache recomputed whenever a visit, a visit item, an
   equipment row or a cycle changes. See `docs/DATABASE.md`, "Due dates".
4. **Every remote table has RLS enabled and forced, with a policy on `user_id = auth.uid()`,
   in the same migration that creates it.** Schema changes are migrations under
   `supabase/migrations/`; never edit the database by hand.
5. **Secrets never enter the repo.** Supabase URL and publishable key, Sentry
   DSN and PostHog key come from `--dart-define-from-file=.env`; gateway tokens
   live in Supabase function secrets. `.env.example` documents the keys. An
   empty key means the no-op adapter, so the app always builds. The repo is
   public: no hosted project refs or hostnames (use `<ref>.supabase.co`), no real
   client data in seeds, fixtures or docs (the one fixture number is
   `+48 601 234 567`), no prices, margin sheets or competitor research in `docs/`; those go in
   the git-ignored `docs/private/` (see `docs/private/BUSINESS.md` locally).
   `melos run secrets` and the CI `secrets` job scan for the mechanical part;
   `/publish-review` (the `publish-reviewer` agent in `.claude/agents/`) reads
   the docs for the rest. Run it before making anything public.
6. **SMS and e-mail are sent by the server, never by the phone or the browser.**
   The app only writes `reminders` rows; edge functions render, send and
   record delivery through gateway adapters.
7. **Polish is the product language.** User-facing strings go in
   `packages/rewizyta_localization/lib/l10n/app_pl.arb` and are read through
   `context.l10n`. No hardcoded UI strings. Code, comments, commit messages
   and docs are in English.
8. **Money is an integer in grosze; phone numbers are E.164 (`+48…`);
   timestamps are ISO-8601 UTC text; dates are `YYYY-MM-DD`.** Locally and remotely.
9. **Soft delete.** Rows get `deleted_at`; nothing is physically deleted on the
   server, so deletions sync like any other change.
10. **Layers point down, never up.** `app → blocs → services → repositories →
    models`; `view_models` beside `blocs`; `shared` and `localization` are
    leaves. A cubit never imports a repository; only `dependencies.dart` in
    the app may. `melos run layering` fails otherwise.
11. **EU first.** Every hosted service we add must offer EU data residency or
    be self-hostable in the EU. See `docs/ARCHITECTURE.md`, "EU stance".

## Conventions – the Flutter side

- **Layer-first Melos monorepo**, the Bodyspace / Catalyst Voices layout. Each
  package has `lib/<name>.dart` (the only public file) and `lib/src/<feature>/`.
  Read one vertical slice before adding to it: `Client` → `ClientDto` +
  `ClientsRepository` → `ClientsService` → `ClientsCubit` →
  `ClientListItemViewModel` → `ClientsPage`.
- **State: flutter_bloc, Cubit by default.** `Bloc` only when events need
  transformers (debounce, drop-while-busy). States are `final class … with
  Equatable`: a single class with `copyWith` when the UI needs several facts at
  once, a `sealed` hierarchy when states are mutually exclusive. `Optional<T>`
  from `rewizyta_shared` clears nullable fields in `copyWith`. Cubits are plain
  `class` (not `final`) so widget tests can mock them.
- **No code generation for models or state.** Equatable + primary
  constructors + hand-written `copyWith`; no freezed. Codegen is limited to DTOs (json_serializable),
  drift and l10n.
- **Errors and effects leave cubits through side-channels**, never through a
  dead error state: `emitError(LocalizedException.create(e))` and
  `emitSignal(...)`; pages consume them with `ErrorHandlerStateMixin` /
  `SignalHandlerStateMixin` from `apps/mobile/lib/common/handlers/`. Field
  validation is state (an enum on the state, localized in `view_models`).
- **Guard every async boundary**: `if (isClosed) return;` after each `await`.
  Streams go through `SubscriptionManagerMixin`, which cancels them in `close()`.
- **Map domain → view model before emitting.** Widgets never see a domain model.
  A view model earns its place with real transforms (formatting, derived flags)
  or 2+ domain models; otherwise pass parameters.
- **Services are the only tier cubits inject.** Repositories are API/DB-only
  and do the DTO ↔ model mapping; caching, orchestration and validation live in
  services. Interfaces are `abstract interface class X`, implementations
  `final class XImpl implements X` in the same folder; barrels export both
  (the DI container needs the impl).
- **DI is manual get_it** behind `DependencyProvider`; the one container is
  `apps/mobile/lib/app/dependency/dependencies.dart`, registered bottom-up in
  tiers (config → databases → observers → network → repositories → sync
  managers → reporting → services → blocs). Register against the interface;
  add `dispose:` to anything owning a stream, a DB handle or a cubit. Pages
  resolve cubits only inside `BlocProvider(create: …)`; nothing deeper in the
  tree touches the locator. Per-page cubits are factories, app-wide ones lazy
  singletons.
- **Page pattern:** `XPage` (stateless, provides the cubit) + `XView`
  (renders, mixes in the handlers, `@visibleForTesting`). Widget tests pump
  `XView` with a `MockCubit` through `test/helpers/pump_app.dart`.
- **go_router** with a central table in `apps/mobile/lib/router/` and
  `RoutePaths` constants; screens never hard-code paths. Typed routes
  (`go_router_builder`) can come later if the table grows.
- **Theming**: Material 3 from a seed colour, semantic colours (overdue, due
  soon, booked) in the `AppColors` `ThemeExtension`, `AppSpacing` constants.
  No `Colors.*` literals in widgets; read `context.appColors` / `context.colorScheme`.
- **Lints: `leancode_lint`** (LeanCode, Warsaw) through the root
  `analysis_options.yaml`, which every package includes. `dart analyze
  --fatal-infos` must pass. We track the latest Dart syntax: **primary
  constructors and declaring parameters everywhere** (`final class const
  Client({required final String id, …}) with Equatable`, `class XCubit(final
  XService _service) extends Cubit<XState> { this : super(const XState()); }`,
  `class MockX() extends Mock implements X;`). `dart fix --apply` migrates
  old-style code. Formatter: page width 100, `trailing_commas: preserve`.
- **Tests**: `test` for pure-Dart packages, `flutter_test` + `bloc_test` +
  `mocktail` above. Repositories run against `NativeDatabase.memory()`. Every
  service method, every cubit and every page gets a test; a
  single-subscription `StreamController` in a test must be `broadcast()` or
  its `close()` hangs the tearDown.
- **Third-party SDKs sit behind adapters** in `rewizyta_services`
  (`AnalyticsService`, `ReportingService`, `PushNotificationsService`) with a
  no-op implementation each. Vendor implementations (PostHog EU, Sentry EU,
  FCM) live in `apps/mobile/lib/app/integrations/` and are chosen in
  `_registerReporting()` from `AppConfig`. Nothing else knows the vendor.

## Conventions – websites (apps/waitlist, apps/website)

- Same approach as the author's `portfolio_rs`: Jaspr **static** mode, every
  route pre-rendered to HTML at build time, no Dart shipped to the browser unless a
  component really needs interactivity (the waitlist form is the one exception).
- Polish first, English second, each language on its own path (`/`, `/en/`).
- Styling through Jaspr `@css` rules and a small `styles.css`; self-hosted fonts;
  no third-party scripts, no cookies, no analytics that need a consent banner.
- Hosting is static on an EU CDN (Bunny.net or Hetzner Object Storage; see
  `docs/ARCHITECTURE.md`). The waitlist form posts to a Supabase edge function
  that inserts into `waitlist_signups`, sends a double-opt-in e-mail and
  returns the promo code.

## Conventions – backend (supabase/)

- One SQL file per change under `migrations/`, named `YYYYMMDDHHMMSS_<what>.sql`.
  Tables, RLS, policies, indexes and triggers for a table are in the same file.
- Edge functions in TypeScript, one folder per function, shared code under
  `functions/_shared/`. Gateways (SMS, e-mail, push) are behind small adapter
  interfaces selected by `SMS_PROVIDER` / `EMAIL_PROVIDER` / `PUSH_PROVIDER`
  secrets, each with a console stub and a shared contract test. Interfaces
  expose only what every vendor offers, so switching to a cheaper vendor is
  one class plus a secret. Start free: Brevo, SMSAPI pay-as-you-go, FCM.
- Scheduled work uses `pg_cron` calling the edge function over HTTP; the schedule
  is documented in `docs/ARCHITECTURE.md`.
- Everything must run locally with `supabase start`; a self-hoster must never
  need a vendor account beyond Supabase, an SMS gateway and an SMTP provider.
- The Supabase project lives in an EU region (Frankfurt). Dev/staging on the
  free tier is kept awake by `.github/workflows/supabase-keepalive.yml`;
  production is Pro or self-hosted, never free (a paused project stops reminders).

## Decisions already made (don't relitigate without a reason)

- Supabase over Firebase: SQL schema, RLS and Docker-based local setup fit an
  open-source, self-hosted backend better. EU region; self-host on Hetzner is
  the fully-EU option.
- flutter_bloc + Equatable + manual get_it, layer-first packages (2026-09-28,
  replaced Riverpod + freezed + feature-first). Reason: same conventions as the
  author's other apps, no codegen for state.
- leancode_lint over very_good_analysis: equally strict, Polish/EU, ships as an
  analyzer plugin so no custom_lint/melos conflict.
- Android first. The caller card on incoming calls is Android-only; iOS gets the
  same app without it (CallKit caller-ID at most).
- Last-write-wins on `updated_at` for sync conflicts. One user per account for now.
- Reminders are materialised and sent by a daily server job, not by the phone.
- Route ordering for a day is nearest-neighbour on straight-line distance, on the phone.
- Melos + pub workspace for the Flutter side; Jaspr sites keep separate lockfiles.
- Crash reporting: Sentry (EU region) or self-hosted GlitchTip. Analytics:
  PostHog EU cloud. Push: FCM behind the adapter (no EU alternative reaches
  Android reliably). E-mail: an EU SMTP/API provider (Scaleway TEM or Brevo).
- Trades and service types are per-user rows seeded from a Dart default
  catalogue, not global tables (works offline, fully editable, self-hoster can
  change the defaults in code).
- MIT licence.
