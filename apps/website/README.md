# apps/website – product website

Home, features, pricing, privacy policy and contact, in Polish (`/`) and
English (`/en/`). Built with [Jaspr](https://pub.dev/packages/jaspr) in static
mode with `jaspr_router`, the same way as the author's `portfolio_rs`: every
route is pre-rendered to HTML at build time and no Dart ships to the browser.

This package keeps its own `pubspec.lock` and is driven through the melos
`sites:*` scripts (see the root `pubspec.yaml` for why).

```bash
melos run website:serve      # or: cd apps/website && jaspr serve   → http://localhost:8080
jaspr build                  # pre-renders to build/jaspr
```

Currently the Jaspr starter template; see `docs/TASKS.md`, milestone M9.
