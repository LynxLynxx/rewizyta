# Architecture Review: working tree (M1 local data layer)

Scope: the 81 paths in `docs/code-review/working-tree/scope.txt`. Read against `CLAUDE.md`
(layers, hard rules 1-12, Flutter conventions), `docs/BACKEND_SCHEMA.md`, `docs/TRD.md`
("Offline-first sync") and `docs/IMPLEMENTATION_PLAN.md` (M1, M5).

Verification run during the review:

- `bash tool/check_layering.sh`: `layering: ok`
- `dart analyze --fatal-infos` in `rewizyta_models`, `rewizyta_repositories`, `rewizyta_services`: no issues
- `dart test` in `rewizyta_repositories` (47 tests) and `rewizyta_services` (7 tests): all pass
- No caller above services uses the renamed `address` field or `saveClient`, so the rename breaks nothing.

## Layer Separation

- Violations found: 0
- `rewizyta_models` imports only `equatable`. The repository tables, DTOs and row mappings import
  `rewizyta_models` (downward). The one service change imports only models and repositories.
  No file imports Flutter below presentation, and none imports another package's `src/`.
- Clean files: all checked files are clean.

## State Management Assessment

No cubits or states are in scope. `ClientsServiceImpl.saveClient` keeps validation, id minting,
timestamps and the "drop coordinates when the address changes" rule in the service, which is
where `CLAUDE.md` puts them.

- `ClientsServiceImpl`: correct, with one normalisation gap (finding S4).

## Dependency Direction

- Direction violations: 0. Every dependency points down: services -> repositories -> models.
- One planned violation path (finding I1): `docs/IMPLEMENTATION_PLAN.md` M1 says "Services wrap
  multi-repository writes in one drift transaction". No abstraction exists for that, so the
  services would have to call `AppDatabase.transaction` and import drift. `check_layering.sh`
  would not catch it.
- Clean dependencies: models (leaf), repositories -> models, services -> repositories/models.

## Package Structure

- `rewizyta_models`: complete. Seven new entities under `lib/src/<feature>/`, exported from the
  barrel, pure Dart.
- `rewizyta_repositories`: complete. It has a pubspec, `analysis_options.yaml`, `build.yaml`
  (snake-case JSON, text timestamps) and a `test/` directory with one file per repository plus
  `app_database_test.dart` and `dto_test.dart`. The layout per feature (`<entity>_repository.dart`,
  `_impl.dart`, `_row_mapping.dart`, `dto/`) is uniform. The barrel leaks internals (finding S1).
- `rewizyta_services`: only the client slice changed; structure is unchanged.
- `tool/check_layering.sh`: the `.dart_tool`/`build` exclusion is correct and needed. A rule
  against `package:drift` in services is worth adding (finding I1).

## Data-layer design: what is good

- `OutboxWriter.upsertSynced` gives every synced table one path: the row write and the outbox
  write share a transaction (hard rule 1). It derives the entity from `actualTableName`, so
  `EquipmentTable` correctly reports `equipment`. A newer write replaces the pending entry.
- `SyncedColumns` keeps `id/user_id/created_at/updated_at/deleted_at` identical on every table.
- The foreign keys are deferred (`initiallyDeferred`) with `PRAGMA foreign_keys = ON`, and the
  cascade and set-null actions match BACKEND_SCHEMA.md's purge rules. `app_database_test.dart` proves
  both the commit-time check and the rollback.
- `insertOnConflictUpdate` compiles to `INSERT ... ON CONFLICT DO UPDATE`, not `REPLACE`, so a
  re-upsert never fires the `ON DELETE CASCADE` actions.
- Calendar days use `DateConverter` (`YYYY-MM-DD`). Timestamps are forced to UTC in every
  `toCompanion()`, so text range queries (`watchBetween`) compare instants. Enums are stored in
  snake_case, matching Postgres (hard rule 8).
- The row <-> model mapping sits in shared extensions, never in private repository methods, as
  the new `CLAUDE.md` text requires.

## Findings

### Important

**I1. Missing transaction abstraction for multi-repository writes**
(`packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:28`; plan in `docs/IMPLEMENTATION_PLAN.md` M1)
Hard rule 3 and BACKEND_SCHEMA.md "Due dates" require a visit, its items and the equipment cache
recompute to commit together ("inside the writing transaction"). IMPLEMENTATION_PLAN.md says services will
"wrap multi-repository writes in one drift transaction". The repository layer exposes only
`AppDatabase` for that, and `app_database_test.dart:16` already composes repositories through
`db.transaction`. A service would then import drift and the concrete database, so the
"repositories are DB-only" boundary breaks. `check_layering.sh` does not forbid
`package:drift` in `rewizyta_services`.
Fix: add `abstract interface class TransactionRunner { Future<T> run<T>(Future<T> Function() body); }`
in repositories with an `AppDatabase`-backed impl, inject it into services, and add a layering
rule that fails on `package:drift` under `packages/rewizyta_services/lib`.

**I2. Server-owned reminder columns ride in the phone's full-row push**
(`packages/rewizyta_repositories/lib/src/reminder/dto/reminder_dto.dart:31-50`,
`reminders_repository_impl.dart:25`)
The server alone moves `status` past `pending` and writes `provider_message_id`, `sent_at`
and `error` (TRD.md "Send", "Delivery"). The outbox payload is the whole row, and
`sync_push` resolves conflicts per row by `updated_at`. Suppose the phone cancels or edits a
manual reminder before pulling the server's `sent` state. Its newer `updated_at` then wins,
writing `status = cancelled` and nulls over the server's delivery record of a message already
sent. Equipment caches are fine to push because only the phone writes them; reminders have
mixed ownership.
Fix: give reminders a push payload limited to phone-writable columns, or have `sync_push`
ignore the server-owned columns for `reminders`. Record the rule in BACKEND_SCHEMA.md under
`reminders`.

**I3. An unknown enum value from the server throws in the read path**
(`packages/rewizyta_repositories/lib/src/database/converters.dart:42-45`)
`EnumConverter.fromSql` throws `ArgumentError` on an unknown value. It sits on drift columns
(`appointments.status`, `reminders.kind/status`, `devices.platform/push_provider`) and in
every DTO `toDomain`. Hard rule 12 says the previous app release must keep working after a
migration. Widening a check constraint, say a new `ReminderStatus` such as `queued` or a new
`PushProvider`, is an "expand" step, yet any older build that pulls such a row throws. It
throws while mapping the pull, or inside a `watch()` stream, where it would break the whole
list.
Fix: make enum decoding tolerant (an `unknown` member or a fallback per enum; skip or
quarantine the row on pull). Otherwise document in BACKEND_SCHEMA.md "Migrations" that a new enum
value is a contract change that ships in the app before the server writes it.

**I4. Model `copyWith` cannot clear nullable fields or restore a soft delete**
(`packages/rewizyta_models/lib/src/appointment/appointment.dart:32`, `visit/visit.dart:19`,
`catalog/service_type.dart:25`, `client/client.dart:26`, `reminder/reminder.dart:50`)
Every `copyWith` uses `x ?? this.x`. Nothing can reset `Appointment.routePosition` to null
("not ordered yet"), unlink `Visit.appointmentId`, clear `ServiceType.tradeId` or
`Client.phone/note`, or undelete any entity by setting `deletedAt` to null. Two models work
around it ad hoc (`Equipment.withDue`, `VisitItem.withDeletedAt`). CLAUDE.md names
`Optional<T>` as the house answer, but `rewizyta_shared` is not a dependency of the models
leaf.
Fix: pick one pattern for all models. Either move `Optional<T>` into `rewizyta_models` (or
let models depend on `shared`, and record that in CLAUDE.md) and use it for nullable fields
in `copyWith`, or add explicit `clearX`/`restore()` methods consistently.

### Suggestion

**S1. Narrow the repositories barrel to interfaces, impls and `AppDatabase`**
(`packages/rewizyta_repositories/lib/rewizyta_repositories.dart:8-36`)
The barrel now exports nine DTOs and `OutboxOp`, and `OutboxOp` is used only by tests.
CLAUDE.md puts DTO <-> model mapping inside repositories. Public DTOs invite a future
`SyncService` in `rewizyta_services` to handle wire shapes itself ("DTOs never travel in").
Fix: stop exporting `dto/*` and `OutboxOp`. Let the tests import `src/` and give repositories
an `applyPulled(...)`-style method for the sync to call.

**S2. Write down that outbox acks must delete by `outbox.id`**
(`packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:30`)
A write that lands during a push deletes the in-flight entry and inserts a new one. That is
safe only if `SyncService` acknowledges by outbox row `id`. An ack by `(entity, entity_id)`
would silently drop the newer change.
Fix: state this in the `upsertSynced` doc comment and in TRD.md "Push", and add a
test for it when `SyncService` lands (M5).

**S3. `Equipment.copyWith(serviceTypeId:)` keeps a stale due-date cache**
(`packages/rewizyta_models/lib/src/equipment/equipment.dart:26-46`)
BACKEND_SCHEMA.md requires a recompute when `service_type_id` changes. Yet `copyWith` carries the
old `nextDueAt`, which was computed from the old cycle, and the repository persists whatever
it receives. Rule 3 then depends on every caller remembering `withDue`.
Fix: null the caches in `copyWith` when `serviceTypeId` changes, or move the type change into
a method that requires the new due dates.

**S4. Normalise blank address fields to null in `saveClient`**
(`packages/rewizyta_services/lib/src/client/clients_service_impl.dart:49-51`, `:66`)
`phone` maps blank input to null, but `addressLine`, `town`, `postalCode` and `note` store `''`.
The local and server rows then hold two spellings of "no value". An empty form field also
compares unequal to a stored null in `keepsCoordinates`.
Fix: use one `_blankToNull(String?)` helper (trim, then null when empty) for every optional
text field.

**S5. The local `user_id` column is unreachable**
(`packages/rewizyta_repositories/lib/src/database/tables/synced_columns.dart:5-10`; `fromDomain({String? userId})` in every DTO)
The comment says a pull fills `user_id` in. The models carry no `userId`, though, so the only
path (DTO -> domain -> `toCompanion()`) drops it, and no repository passes `userId` to
`fromDomain`. The server forces `user_id = auth.uid()` anyway (BACKEND_SCHEMA.md, "Sync support").
Fix: drop the local column and the unused `userId` parameter (YAGNI). Otherwise give the pull
a DTO -> companion path that keeps it, and fix the comment.

## Notes (not findings)

- The new repositories are not registered in `apps/mobile/lib/app/dependency/dependencies.dart`.
  IMPLEMENTATION_PLAN.md M1 tracks this, and nothing consumes them yet.
- `rewizyta_repositories/pubspec.yaml` lists `rewizyta_shared`, which nothing in `lib/` imports.
  The file is outside the scope.

## Verdict

The architecture is clean: no layer or dependency violations, and the outbox, FK and
converter design follows the hard rules. Fix the four Important items before the services
and the sync build on this layer. I1 and I2 are the ones that become expensive once M1's
due-date services and M5's sync exist.
