# VGV Code Review: M1 local data layer (working tree)

Scope: the 81 paths in `docs/code-review/working-tree/scope.txt`. These are the models, drift
tables, DTOs, row mappings, repositories, `OutboxWriter`, tests, the `ClientsService` rename
and `tool/check_layering.sh`. Conventions come from the repo's `CLAUDE.md` (flutter_bloc +
Equatable, manual get_it, layer-first packages, primary constructors, leancode_lint, no freezed).

Verification run on the working tree:

- `dart analyze --fatal-infos`: clean in `rewizyta_models`, `rewizyta_repositories`,
  `rewizyta_services` and `apps/mobile`.
- `dart test`: `rewizyta_repositories` 47/47 pass, `rewizyta_services` 7/7 pass.
- `tool/check_layering.sh`: ok.
- No callers are left on the removed `SyncEntity`, `outbox_entry.dart` or `Client.address`.
- No server migration creates `clients` yet, so renaming `address` to `address_line` breaks
  no deployed contract (hard rule 12 holds).

## Summary

This is a careful, convention-faithful slice and it is close to mergeable. Every entity
follows the `Client` vertical. The row mappings are shared extensions, and every synced
write goes through one `upsertSynced` that writes the row and its outbox entry in a single
transaction, coalescing pending entries per row. Foreign keys are deferred and tested,
enums are stored in snake_case, calendar days are stored as `YYYY-MM-DD` text, and each
repository has an in-memory drift test that checks behaviour rather than implementation.
Nothing blocks the build, and I found no critical defects. The important issues are design
traps the next milestone will trip over. `copyWith` cannot clear nullable fields, so a
soft-deleted default cannot be restored and an appointment cannot be un-ordered. Unknown
enum values from the server throw, which conflicts with the expand-then-contract rule. The
reminder push payload carries server-owned delivery columns under last-write-wins. Blank
address fields are not normalised, so the new keep-coordinates rule misfires. Services also
lack a seam for the multi-repository transaction that IMPLEMENTATION_PLAN.md promises.

## Critical: Must Fix Before Merge

None.

## Important: Should Fix

- **packages/rewizyta_models/lib/src/catalog/trade.dart:21** (also `service_type.dart:25`,
  `client.dart:26`, `equipment.dart:26`, `appointment.dart:32`, `visit.dart:19`).
  `copyWith` uses `x ?? this.x` for every nullable field, so callers cannot clear them.
  - Why: `TradesRepository.findByTemplateKey` returns soft-deleted defaults precisely so that
    "restore defaults" can bring them back, but `trade.copyWith(deletedAt: null)` keeps the
    old `deletedAt`, so the restore silently fails. The same trap blocks un-ordering an
    appointment (`routePosition: null` is documented as "not ordered yet"), unlinking a
    visit from its appointment, clearing a price or note, and undoing a client delete.
    `VisitItem.withDeletedAt` and `Equipment.withDue` already solve this for two models;
    the others do not.
  - Fix: add `withDeletedAt(DateTime?, {required updatedAt})` (or `restore`) to every
    soft-deletable model, plus explicit setters for the fields that really need clearing
    (`Appointment.withRoutePosition(int?)`). The alternative is to let `rewizyta_models`
    depend on the leaf `rewizyta_shared` and use `Optional<T>` as the state classes do.
    Add one model test per clearing path.

- **packages/rewizyta_repositories/lib/src/database/converters.dart:42**:
  `EnumConverter.fromSql` throws `ArgumentError` on an unknown value, and
  `dto_test.dart:108` pins that as "fails loudly".
  - Why: hard rule 12 says the previous app release must keep working. Adding an enum value
    on the server (a new `reminders.status`, a third `push_provider`, an appointment
    `rescheduled`) is an "expand" change, yet every older build would throw inside the
    pull's DTO decoding, and the whole pull would fail on one row.
  - Fix: decide the policy and write it down in BACKEND_SCHEMA.md. Either give each enum a
    fallback (for example `unknown`, or map to a safe existing value) and skip or flag the
    row, or declare new enum values a contract change that must wait for the old build to
    disappear. Then make the test assert that policy.

- **packages/rewizyta_services/lib/src/client/clients_service_impl.dart:49**: optional text
  fields are trimmed but blanks are not turned into null, unlike `phone` two lines above.
  - Why: `keepsCoordinates` compares the trimmed values exactly. A client imported with
    `town: null` and then saved from a form, whose `TextEditingController` yields `''`,
    fails the comparison, so its geocoded `lat`/`lng` are dropped even though the address
    never changed. `''` also lands in the database and in the sync payload instead of null.
    This affects `addressLine`, `town`, `postalCode` and `note`.
  - Fix: add a private `String? _blankToNull(String? s)` and apply it to every optional text
    field before both the comparison and the constructor. Add a service test where an
    unchanged address arrives as `''` against stored `null` and the coordinates are kept.

- **packages/rewizyta_repositories/lib/src/reminder/dto/reminder_dto.dart:31**: the push
  payload for a reminder carries the server-owned columns (`status` beyond `cancelled`,
  `provider_message_id`, `sent_at`, `error`).
  - Why: sync is last-write-wins on `updated_at` with whole-row payloads. Suppose the app
    cancels a pulled reminder whose local copy still says `pending` while the server has
    already sent it. The phone's newer `updated_at` then overwrites `sent` and the
    gateway's message id with stale values. The domain comment says that only the server
    moves a reminder past `pending`, but nothing in the data path enforces it.
  - Fix: record the rule that `sync_push` ignores server-owned reminder columns and accepts
    only `pending → cancelled` (or only manual inserts) from the phone, in BACKEND_SCHEMA.md
    ("Sync functions"). Alternatively, add a push-specific payload without those fields.
    Either way, do it before M5 builds `sync_push`.

- **packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:28**: no
  transaction seam exists for services. IMPLEMENTATION_PLAN.md now says that services wrap
  multi-repository writes in one drift transaction (a visit, its items and the equipment
  due-date caches).
  - Why: services see only repository interfaces. A transaction would therefore force them
    to import `AppDatabase` from the barrel and call `transaction()` directly, pulling drift
    into the service tier and making the services hard to unit-test with mocktail. Without
    a transaction, a crash between `VisitsRepository.upsert` and the equipment update
    leaves a stale `next_due_at`, which violates hard rule 3.
  - Fix: add a small `abstract interface class TransactionRunner { Future<T> run<T>(Future<T>
    Function() body); }` with a drift-backed impl in `rewizyta_repositories`, register it in
    DI, and have services depend on that interface. A fake that just calls `body()` serves
    the tests. Do it in the same M1 step as the due-date recompute.

## Suggestions: Nice to Have

- **packages/rewizyta_repositories/lib/src/database/tables/synced_columns.dart:5** and
  `client_dto.dart:28`: the `user_id` plumbing is dead. Every `fromDomain(…, {String?
  userId})` parameter is used only by `dto_test.dart`. `toDomain` drops `userId`, and no
  `toCompanion` writes it, so the local column the doc says "a pull fills in" can never be
  filled through this path, and every push sends `"user_id": null`.
  - Suggestion: drop the `userId` DTO parameter and the local column (the server sets it from
    the session anyway), or wire it end to end once the pull exists. Do not keep the
    half-wired version.

- **packages/rewizyta_repositories/lib/src/database/converters.dart:20** and
  `appointments_repository_impl.dart:9`: "comparing the stored text compares instants" is
  not strictly true. Drift writes UTC as `toIso8601String()`, which drops the microsecond
  digits when they are zero. `…00.001Z` therefore sorts after `…00.001500Z`, and a
  `watchBetween` bound at `.000Z` excludes a row at `.000500Z`.
  - Suggestion: truncate stored instants to milliseconds in `toCompanion` (or always format
    with six fractional digits), or soften the comment. In practice only sub-millisecond
    neighbours are affected.

- **packages/rewizyta_repositories/lib/src/database/converters.dart:26**: `enumToSql`
  builds a new `RegExp` on every call, and `EnumConverter.fromSql` re-derives the
  snake_case name of every enum value on every row read.
  - Suggestion: hoist the regex into a `final _upper = RegExp('[A-Z]')` at the top level.
    Optionally cache a `Map<String, T>` in the converter.

- **packages/rewizyta_repositories/lib/src/client/dto/client_dto.dart:42** (and every DTO):
  about 20 copies of `x == null ? null : formatTimestamp(x!)` and
  `x == null ? null : parseTimestamp(x!)` add a force-unwrap at each site.
  - Suggestion: add `formatTimestampOrNull` / `parseTimestampOrNull` (and the date
    equivalents) in `converters.dart` and drop the `!`s.

- **packages/rewizyta_repositories/lib/src/database/tables/trades.dart:7** (and
  `service_types.dart:8`): the unique local `template_key` index will reject a pull of
  defaults that a second phone has already seeded under different ids, and the server
  unique index rejects the push the other way round.
  - Suggestion: when the `DefaultCatalog` seed service is designed, seed only after the first
    pull has completed (or derive default ids deterministically from `template_key` and the
    user). Note the decision in BACKEND_SCHEMA.md.

- **packages/rewizyta_models/lib/src/client/client.dart:6**: the doc says that `lat`/`lng`
  "are geocoded on the phone when the address is saved", but nothing sets them yet, and
  `saveClient` can only keep or drop them.
  - Suggestion: phrase it as the intended contract ("set by geocoding after a save; cleared
    when the address changes").

- **packages/rewizyta_models/lib/src/equipment/equipment.dart:51** (also
  `visit_item.dart:17`): model behaviour such as `withDue`, `withDeletedAt`, the
  `copyWith` field preservation and `isDeleted` has no tests in `rewizyta_models/test/`.
  The repository tests cover them only indirectly.
  - Suggestion: add a short `models_test.dart`, especially once the clearing helpers from
    the first Important item exist.

- **packages/rewizyta_repositories/test/dto_test.dart:15**: one test asserts nine entity
  round-trips, so the first failure hides the rest and the report names no entity.
  - Suggestion: generate one `test` per DTO from a table of
    `(name, encode, decode, value)` cases.

- **packages/rewizyta_repositories/test/catalog_repositories_impl_test.dart:50** (also lines
  91 and 98, `equipment_repository_impl_test.dart:63`, and
  `visit_repositories_impl_test.dart:94`): these tests call `expect(() => futureCall(),
  throwsA(...))` without an await, while `app_database_test.dart` uses
  `await expectLater(...)`.
  - Suggestion: use `await expectLater(repository.upsert(...), throwsA(...))` throughout for
    one style and explicit sequencing before `tearDown` closes the database.

## Simplicity Assessment

- Lines that could be removed: about 40 (the `userId` DTO parameters and local column,
  plus the duplicated null-ternaries once helpers exist).
- Unnecessary abstractions: none. `OutboxWriter.upsertSynced` replaced nine copies of the
  same transaction and earns its keep. `SyncedColumns` removes real duplication. The
  per-entity row-mapping extensions are justified by the planned reuse in joins and sync.
- YAGNI violations: `fromDomain(…, {String? userId})` on every DTO; the local `user_id`
  column with no writer.
- Complexity verdict: Minor tweaks needed.

## Testing Assessment

- New code with tests: ✅ every new repository has an in-memory drift test. The DTO round
  trip, deferred foreign keys, purge cascades, CHECK constraints and the unique keys are
  covered. 🔴 Missing: direct tests for the new models' behaviour (`withDue`,
  `withDeletedAt`, `copyWith`), and a service test for blank-versus-null address fields.
- Test quality: Meaningful. The tests assert stored text (`no_show`, `2027-01-31`), outbox
  coalescing, UTC normalisation and zone-independent range bounds, and they avoid
  implementation coupling. Edge cases are missing in a few places: no rollback test for a
  failed row write inside `upsertSynced` beyond the foreign-key case, and no test for an
  unknown or blank address.
- State management test coverage: not applicable (no cubits changed).
- UI component test coverage: not applicable (no widgets changed).
