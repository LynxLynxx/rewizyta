# supabase/

The backend. Everything a self-hoster needs is in this folder:

| Path | Contents |
|---|---|
| `migrations/` | Plain SQL, applied in filename order by `supabase db push` / `supabase db reset`. Schema is documented in [`../docs/DATABASE.md`](../docs/DATABASE.md). |
| `functions/` | Edge functions (Deno/TypeScript): `send-due-reminders` (daily cron), `send-sms` (manual outbox), `sms-webhook` (delivery reports). |
| `config.toml` | Created by `supabase init`; local ports, auth settings, cron schedules. |
| `seed.sql` | Optional dev data. Never real client data. |

## Local setup

```bash
brew install supabase/tap/supabase      # or: npm i -g supabase
supabase init                           # once, creates config.toml
supabase start                          # Postgres + Auth + Studio in Docker
supabase db reset                       # applies migrations/ and seed.sql
```

Copy `.env.example` to `.env` and put the local URL and anon key from
`supabase status` into it. The app reads them with `--dart-define-from-file`.

## Rules

- Every table gets `enable row level security` and a policy scoped to
  `auth.uid()` **in the same migration that creates it**.
- The SMS gateway credentials live in function secrets
  (`supabase secrets set SMS_API_TOKEN=...`), never in a migration or the app.
- Schema changes are migrations. Never edit the database by hand and forget.
