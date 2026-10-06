## What and why

<!-- One paragraph. Link the issue if there is one: "Closes #12". -->

## Checklist

Mirrors `CLAUDE.md`. Leave a box unticked and say why if it does not apply.

- [ ] `melos run check` and `melos run layering` pass locally.
- [ ] No hardcoded UI strings; new strings are in `app_pl.arb`.
- [ ] Writes go to the local database and the outbox in one transaction; nothing in the UI waits on the network.
- [ ] New or changed remote tables: migration under `supabase/migrations/` with RLS enabled, forced and a `user_id = auth.uid()` policy in the same file.
- [ ] Tests added or updated (service method, cubit, page, repository as applicable).
- [ ] Docs updated where they describe the thing changed (`docs/BACKEND_SCHEMA.md`, `docs/TRD.md`, `docs/IMPLEMENTATION_PLAN.md`).
- [ ] No credentials, hosted project identifiers or real personal data anywhere in the diff (`melos run secrets`).
