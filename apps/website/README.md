# apps/website – the Rewizyta site

Until launch this is the waitlist, in Polish: the home page (`/`) with the
survey and sign-up form that posts to the `waitlist-signup` edge function, the
two pages the mails link to (`/potwierdz/`, `/wypisz/`) and the privacy notice
(`/prywatnosc/`). After launch it becomes the app's information and support
site (see `docs/TRD.md`, "Websites"). Built with
[Jaspr](https://pub.dev/packages/jaspr) in static mode with `jaspr_router`,
the same way as the author's `portfolio_rs`: every route is pre-rendered to
HTML at build time; the only Dart in the browser is the three `@client`
components in `lib/waitlist/`: the sign-up form and the confirm and
unsubscribe buttons. Each page loads only its own.

This package keeps its own `pubspec.lock` and is driven through the melos
`sites:*` scripts (see the root `pubspec.yaml` for why).

```bash
melos run website:serve      # or: cd apps/website && jaspr serve   → http://localhost:8080
dart test                    # flow, API client and render tests
jaspr build --dart-define=FUNCTIONS_URL=https://<ref>.supabase.co/functions/v1
                             # pre-renders to build/jaspr
```

- `FUNCTIONS_URL` is the only setting and it is public. Without it the form
  talks to `supabase start` on this machine (`http://127.0.0.1:54321/functions/v1`).
  The function accepts the site's origin only (`WAITLIST_SITE_URL`,
  `http://localhost:8080` locally), so serve the site on that port.
- `jaspr build` pre-renders by running the site on port 8080 (`--port` changes
  it) and fetching each route, through a proxy on port 5567 that cannot be
  changed. Stop `jaspr serve` first: it holds both the proxy and the build
  daemon.
- Hosting: Cloudflare Workers, static assets only. `wrangler.jsonc` sets the
  domains (`rewizyta.rsapps.org`, staging `staging.rewizyta.rsapps.org`), the
  404 page (`/404.html`, `lib/pages/not_found_page.dart`) and trailing-slash
  handling; `web/_headers` the CSP, HSTS and caching. A new third-party origin
  (an image, a script, an API) has to be added to the CSP there, or the browser
  blocks it. `.github/workflows/deploy-website.yml` builds and deploys; to try
  the result locally, `jaspr build`, then `npx wrangler@4.145.0 dev`
  (→ http://localhost:8787).
- Layout: `lib/pages/` holds the pages (`home/` has one file per section),
  `lib/components/` the header, footer and `SitePage` frame, `lib/waitlist/`
  the survey (`survey.dart`, whose keys must match
  `supabase/functions/_shared/waitlist/survey.ts`), the flow state, the API
  client, the form and the mail-link buttons (`mail_action.dart`; Jaspr
  allows one `@client` component per file, hence `confirm_action.dart` and
  `unsubscribe_action.dart`). Colours are CSS custom properties in
  `web/styles.css`, read through `Palette` in `lib/constants/theme.dart`.
- The data controller and contact address named on `/prywatnosc/` are in
  `lib/constants/site.dart`; a fork that runs its own site changes them. What
  the notice promises must match `docs/BACKEND_SCHEMA.md`, "Personal data,
  encryption and retention".
- To try the mail pages locally, sign up through the form, read the tokens with
  `psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -c "select
  confirm_token, unsubscribe_token from waitlist_signups"` (or take the links
  from the console mail in the functions log) and open
  `http://localhost:8080/potwierdz/#t=<confirm_token>`.
- Fonts: IBM Plex Sans and Mono, self-hosted in `web/fonts/` (SIL OFL 1.1,
  `web/fonts/OFL.txt`), Latin and Latin Extended subsets.
- Icons: `web/favicon.svg` is the header mark (`lib/components/site_header.dart`)
  and the source; `favicon.ico` (16, 32, 48) and `apple-touch-icon.png` (180,
  full-bleed, iOS rounds it) are rasterised from it. Change the mark in all
  three; `lib/main.server.dart` links them.
