# supabase/

The backend. Everything a self-hoster needs is in this folder:

| Path | Contents |
|---|---|
| `migrations/` | Plain SQL, applied in filename order by `supabase db push` / `supabase db reset`. Schema is documented in [`../docs/DATABASE.md`](../docs/DATABASE.md). |
| `functions/` | Edge functions (Deno/TypeScript): `send-due-reminders` (daily cron), `send-sms` (manual outbox), `sms-webhook` (delivery reports). |
| `config.toml` | Committed. Local ports, auth settings, cron schedules. Hosted projects are configured in the dashboard; CI does not push this file. |
| `seed.sql` | Optional dev data. Never real client data. |

## Local setup

Run the CLI from the repository root; it finds this folder by itself.

```bash
brew install supabase/tap/supabase      # or: npm i -g supabase
supabase start                          # Postgres + Auth + Studio in Docker
supabase db reset                       # applies migrations/ and seed.sql
```

Copy `.env.example` to `.env` and put the local URL and anon key from
`supabase status` into it. The app reads them with `--dart-define-from-file`.

## Hosted environments

| Target | Project | Deployed by |
|---|---|---|
| staging | free tier, EU region | `.github/workflows/deploy-supabase.yml` on every merge to `main` that touches this folder |
| production | Pro (or self-hosted), EU region | the same workflow on a `v*` tag, after approval on the `production` GitHub environment |

The workflow runs `supabase link`, `supabase db push` and `supabase functions
deploy`. It needs `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` and
`SUPABASE_DB_PASSWORD` as secrets on the GitHub environment; the keepalive job
reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from `staging`. Nothing is
stored at repository level. Function secrets are set once per project by hand:

```bash
supabase secrets set --project-ref <ref> SMS_PROVIDER=console EMAIL_PROVIDER=console
```

CI applies every migration to a fresh database on each pull request, so a
migration that does not apply cannot reach `main`.

## Rules

- Every table gets `enable row level security` and a policy scoped to
  `auth.uid()` **in the same migration that creates it**.
- The SMS gateway credentials live in function secrets
  (`supabase secrets set SMS_API_TOKEN=...`), never in a migration or the app.
- Schema changes are migrations. Never edit the database by hand and forget.
- A migration must keep working for the previous app release: expand, then
  contract (add with defaults now, rename or drop in a later release).
