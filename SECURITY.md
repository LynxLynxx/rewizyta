# Security policy

Rewizyta stores other people's names, phone numbers and addresses, and sends them
SMS. Security reports are taken seriously and handled quickly.

## Reporting a vulnerability

**Please do not open a public issue for a security problem.**

Report it privately through GitHub: open the repository's **Security** tab and
choose **Report a vulnerability**. This reaches only the maintainer.

Include what you can: the affected component (app, migration, edge function,
website), steps to reproduce, and the impact you believe it has. A proof of
concept against a local `supabase start` instance is ideal; please do not test
against the hosted service with accounts or data that are not yours.

You will get an acknowledgement within 72 hours, a first assessment within a
week, and a fix or a mitigation plan as soon as the severity warrants. You will
be credited in the release notes if you wish.

## What is in scope

- The Flutter app under `apps/mobile` and the packages it is built from.
- The backend under `supabase/`: migrations (schema, RLS policies, triggers,
  RPC functions), edge functions and their shared code.
- The website under `apps/website` (currently the waitlist page) and the
  waitlist sign-up flow.
- CI workflows under `.github/`.

Things we especially want to hear about: a way to read or change another user's
rows despite RLS, a way to make the server send SMS to numbers a user did not
enter, a way to trigger the reminder or billing jobs without authorisation,
and any credential or personal data that has reached the repository.

## What is out of scope

- Vulnerabilities in Supabase, Flutter, Dart packages or gateway providers
  themselves. Report those upstream; a heads-up here is still welcome if they
  affect this project.
- Denial of service, rate limiting on the public waitlist endpoint, and
  findings that require a rooted device or physical access to an unlocked phone.
- Findings on a self-hosted instance caused by that instance's configuration.

## Supported versions

The project is pre-release. Only the `main` branch receives fixes.

## How the repository protects itself

- `tool/check_secrets.sh` (gitleaks plus greps for phone numbers, e-mail
  addresses and hosted hostnames) runs as a pre-commit hook and in CI over the
  whole history.
- Secrets never enter the repository; the app reads them from a local `.env`
  and the functions from Supabase secrets. See `CLAUDE.md`, rule 5.
- Every remote table has Row Level Security enabled and forced with a policy on
  `user_id = auth.uid()`. See `docs/BACKEND_SCHEMA.md`, "Row Level Security".
