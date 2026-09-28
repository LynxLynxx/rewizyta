# apps/waitlist – pre-launch landing page

One static page, in Polish, with an e-mail sign-up form. Built with
[Jaspr](https://pub.dev/packages/jaspr) in static mode, the same way as the
author's `portfolio_rs`. The form posts to the `waitlist-signup` edge function
(see `supabase/functions/`), so the page itself holds no keys.

This package keeps its own `pubspec.lock` and is driven through the melos
`sites:*` scripts (see the root `pubspec.yaml` for why).

```bash
melos run waitlist:serve     # or: cd apps/waitlist && jaspr serve   → http://localhost:8080
jaspr build                  # pre-renders to build/jaspr
```

Currently the Jaspr starter template; see `docs/TASKS.md`, milestone M8.
