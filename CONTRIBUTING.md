# Contributing to Rewizyta

Thanks for taking an interest. Rewizyta is a small, opinionated project built by one
person, so the fastest way to get a change in is to follow the conventions that are
already there. This page covers the process; the rules for the code live in
[`CLAUDE.md`](CLAUDE.md) and the design in [`docs/`](docs/).

## Before you start

- **Open an issue first for anything bigger than a bug fix.** The product scope
  (`docs/PRODUCT.md`) and the architecture (`docs/ARCHITECTURE.md`) are deliberate,
  and `CLAUDE.md` lists decisions that are already made. A short issue saves both of
  us a pull request that cannot be merged.
- **Check `docs/TASKS.md`.** It says what is being built next and what is already
  in progress.
- Issues and discussions may be written in Polish or English. Code, comments,
  commit messages and documentation are in English; user-facing strings are Polish
  and live in `packages/rewizyta_localization/lib/l10n/app_pl.arb`.

## Setting up

The [README](README.md#getting-started) has the full walkthrough. In short:

```bash
dart pub global activate melos
melos bootstrap
melos run gen && melos run l10n
melos run hooks          # installs the pre-commit secrets scan; do this once
melos run check          # what CI runs
```

`melos run hooks` is not optional: the repository is public, and the hook blocks a
commit that contains a credential, a real phone number or an e-mail address. See
"What must never be committed" below.

## Making a change

1. Branch from `main`.
2. Read one vertical slice of the feature you are touching before adding to it
   (`Client` → `ClientDto` + `ClientsRepository` → `ClientsService` →
   `ClientsCubit` → view model → page). New code should look like its neighbours.
3. Keep the hard rules in `CLAUDE.md`. The ones people trip over most:
   - the UI never waits on the network; every write goes to the local database
     and the outbox in one transaction;
   - layers point down only (`melos run layering` enforces it);
   - every new remote table gets RLS enabled and forced in the same migration;
   - no hardcoded UI strings; no `Colors.*` literals in widgets.
   - a migration must keep working for the previous app release (add columns
     with defaults now; rename or drop in a later release).
4. Add tests. Every service method, cubit and page has one; repositories run
   against an in-memory database.
5. Update the document that describes what you changed (`docs/DATABASE.md` for
   schema, `docs/ARCHITECTURE.md` for flows, `docs/TASKS.md` for status).
6. Run `melos run check` and `melos run layering`. Both must pass.

Schema changes are always a new file under `supabase/migrations/`; never edit an
existing migration or the database by hand.

## Pull requests

`main` is protected by a ruleset: nobody pushes to it directly, not even the
maintainer. Every change is a branch and a pull request, and the PR can only be
merged when the five CI checks are green:

| Check | What it runs |
|---|---|
| Secret and personal-data scan | gitleaks over the tree and the whole history, plus the PII greps |
| Backend migrations | every migration applied to a fresh Postgres, then `supabase db lint` |
| Flutter workspace | `melos run gen`, `l10n`, `format`, `analyze`, `layering`, `test` |
| Jaspr site (waitlist) | `dart format`, `dart analyze --fatal-infos`, `jaspr build` |
| Jaspr site (website) | the same for the product website |

- One change per pull request. Refactors and features go in separate PRs.
- Branch names: `feat/…`, `fix/…`, `chore/…`, `docs/…`. The branch is deleted
  automatically after the merge.
- Fill in the template. The checklist mirrors `CLAUDE.md`; ticking a box you have
  not done wastes review time.
- CodeRabbit posts an automated review on every PR. Treat it like a reviewer:
  fix what is right, reply to what is not, and resolve the thread either way.
- Every review thread must be resolved before merging.
- PRs are **squash-merged**, so `main` has one commit per PR and a linear history.
  The PR title becomes the commit subject: write it in English, imperative mood,
  under 72 characters (`Add equipment table and repository`), and use the PR
  description to say *why* when the diff does not make it obvious. Commits inside
  the branch can be as messy as you like.

Review is done by the maintainer, usually within a week. Small, focused PRs get
merged fastest.

## Releases

`main` deploys to staging automatically. A release is a tag on `main`:

```bash
git tag -a v0.1.0 -m "v0.1.0" && git push origin v0.1.0
```

The tag triggers the production backend deploy, which waits for the maintainer's
approval on the `production` environment. There are no `develop` or `release/*`
branches; a hotfix is an ordinary PR followed by a new patch tag.

## What must never be committed

The repository is public. Do not commit:

- credentials of any kind: Supabase keys, Sentry DSNs, PostHog keys, gateway
  tokens, signing keystores, `google-services.json`, any `.env` other than
  `.env.example`;
- hosted project identifiers: Supabase project refs or URLs (`<ref>.supabase.co`
  is the placeholder), Sentry or PostHog project slugs, server hostnames;
- real personal data: client names, phone numbers, addresses. The one fixture
  phone number is `+48 601 234 567`; use `@example.com` addresses.

`melos run secrets` runs the same scan CI does. If it flags a false positive,
explain it in the PR rather than bypassing the hook.

## Licence of contributions

Rewizyta is released under the [MIT Licence](LICENSE). By submitting a
contribution you agree that it is licensed under the same terms, and that you
have the right to grant that licence (in other words, it is your own work or
work you are allowed to contribute). There is no contributor licence agreement
to sign.

## AI-assisted contributions

Contributions written with the help of an AI assistant are welcome. `CLAUDE.md`
exists so that assistants follow the same conventions as people. You are
responsible for the result: read the diff, run the checks, and make sure you
can explain every line in review.

## Code of conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md).
