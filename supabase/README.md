# supabase/

The backend. Everything a self-hoster needs is in this folder:

| Path | Contents |
|---|---|
| `migrations/` | Plain SQL, applied in filename order by `supabase db push` / `supabase db reset`. Schema is documented in [`../docs/DATABASE.md`](../docs/DATABASE.md). |
| `functions/` | Edge functions (Deno/TypeScript). Now: `waitlist-signup`, `waitlist-confirm`, `waitlist-unsubscribe`. Later: `send-due-reminders` (daily cron), `send-pending-sms`, `sms-webhook`. Shared code (e-mail adapters, HTTP helpers) under `functions/_shared/`. |
| `tests/` | pgTAP tests for the SQL side (RLS, grants, functions), run by `supabase test db`. |
| `deno.json` | fmt, lint and test settings for the functions; `deno task check` runs them all. |
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

Edge functions read their secrets from `functions/.env` (git-ignored):

```bash
cp supabase/functions/.env.example supabase/functions/.env   # EMAIL_PROVIDER=console
supabase start                          # serves every function at http://127.0.0.1:54321/functions/v1/
docker logs -f supabase_edge_runtime_rewizyta   # the console adapter prints each mail here
```

Checks (both also run in CI):

```bash
melos run functions:check   # deno fmt, lint, type check, unit and contract tests (needs Deno 2)
melos run db:test           # pgTAP tests against the running local database
```

## Hosted environments

| Target | Project | Deployed by |
|---|---|---|
| staging | free tier, EU region | `.github/workflows/deploy-supabase.yml` on every merge to `main` that touches this folder |
| production | Pro (or self-hosted), EU region | the same workflow on a `v*` tag, after approval on the `production` GitHub environment |

The workflow runs `supabase link`, `supabase db push` and `supabase functions
deploy`. It needs `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` and
`SUPABASE_DB_PASSWORD` as secrets on the GitHub environment; the keepalive job
reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from `staging`. Nothing is
stored at repository level. Function secrets are set once per project by hand; `functions/.env.example`
lists and explains every name:

```bash
supabase secrets set --project-ref <ref> \
  EMAIL_PROVIDER=brevo BREVO_API_KEY=xkeysib-... \
  WAITLIST_SITE_URL=https://<waitlist-domain> WAITLIST_FROM_EMAIL=<sender on a verified domain> \
  WAITLIST_IP_SALT="$(openssl rand -base64 32)"
```

The waitlist functions are public (`verify_jwt = false` in `config.toml`,
which `supabase functions deploy` honours); they check the origin, the input
and the rate limits themselves.

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
