# Rewizyta

[![CI](https://github.com/LynxLynxx/rewizyta/actions/workflows/ci.yml/badge.svg)](https://github.com/LynxLynxx/rewizyta/actions/workflows/ci.yml)
[![Licence: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)

*Rewizyta* (Polish: a return visit) is an offline-first app for one-person field
technicians in Poland: chimney sweeps, gas and boiler servicemen. They look after
300–600 clients who each need a service every 3 or 12 months, and today they keep
those dates in their head, a notebook or phone contacts. Clients drift to competitors
because nobody reminds them.

**Core promise: no client gets lost, and the app works on one phone, without signal.**

The app keeps clients, their equipment and service cycles, calculates when each
visit is due, books appointments and sends SMS reminders from the server, so they
go out even when the phone is off. It is open source and the backend is meant to be
self-hosted with one command.

> Status: pre-MVP. The repository contains the structure and the design documents.
> See [`docs/TASKS.md`](docs/TASKS.md) for what is being built next.

## Documents

| Document | Read it for |
|---|---|
| [`docs/PRODUCT.md`](docs/PRODUCT.md) | The problem, the users, the feature set (MVP, V1, later) and the known risks. |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How the app, the backend, the SMS pipeline and the websites fit together; the offline-first sync design. |
| [`docs/DATABASE.md`](docs/DATABASE.md) | Every table, locally (drift/SQLite) and remotely (Postgres), plus the sync and RLS rules. |
| [`docs/TASKS.md`](docs/TASKS.md) | Milestones and their status. |
| [`CLAUDE.md`](CLAUDE.md) | Conventions and hard rules for anyone (human or AI) changing the code. |

## Repository layout

This is a [Melos](https://melos.invertase.dev) monorepo.

```
rewizyta/
├── apps/
│   ├── mobile/      Flutter app (Android first, iOS second): bootstrap, DI, router, pages, theme.
│   ├── waitlist/    Pre-launch landing page with a sign-up form and promo code. Jaspr, static.
│   └── website/     Product website. Jaspr, static.
├── packages/        Layer packages: rewizyta_models, _repositories (drift), _services,
│                    _blocs (flutter_bloc), _view_models, _localization, _shared (get_it).
├── supabase/        Backend: SQL migrations, edge functions, local config.
├── tool/            Layering audit and format helper used by the melos scripts.
├── docs/            Design documents.
└── pubspec.yaml     Melos workspace root and scripts.
```

## Getting started

Prerequisites: Flutter 3.47 (bundles Dart 3.13), Docker (for the local backend),
and these global tools:

```bash
dart pub global activate melos
dart pub global activate jaspr_cli
brew install supabase/tap/supabase     # or: npm i -g supabase
```

Then:

```bash
melos bootstrap          # pub get for every package, incl. the two Jaspr sites
melos run gen            # code generation (json_serializable, drift)
melos run l10n           # AppLocalizations from app_pl.arb
melos run check          # everything CI runs: gen, l10n, format, analyze, test
melos run hooks          # once: pre-commit hook that blocks secrets and personal data

cd apps/mobile && flutter run --dart-define-from-file=../../.env
melos run waitlist:serve # http://localhost:8080
melos run website:serve
```

Backend, locally:

```bash
cd supabase && supabase init   # first time only
supabase start                 # Postgres, Auth, Studio in Docker
supabase db reset              # applies migrations/ and seed.sql
cp .env.example .env           # then paste the URL and publishable key from `supabase status`
```

`melos run --list` shows every script. The Jaspr sites keep their own lockfiles
(see the note in `pubspec.yaml`), which is why `melos bootstrap` runs their
`pub get` in a hook rather than as workspace members.

## Contributing

Issues and pull requests are welcome. `main` is protected: every change lands through a
pull request that passes CI. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the
process and [`CLAUDE.md`](CLAUDE.md) for the rules the codebase follows (offline-first,
RLS on every table, Polish UI strings in ARB files, layers that only point down,
EU-hosted services) and the decisions that are already made. Stack: flutter_bloc +
Equatable + manual get_it in a layer-first Melos monorepo, `leancode_lint`, drift,
Supabase.

Security problems go through GitHub's private vulnerability reporting, not the issue
tracker: see [`SECURITY.md`](SECURITY.md).

## License

The code is released under the [MIT Licence](LICENSE). The *Rewizyta* name and logo
identify the hosted service and are not part of that grant; a self-hosted fork should
use its own name.
