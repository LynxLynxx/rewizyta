# Code simplicity review — M1 data layer (working tree)

Scope: the 81 files in `docs/code-review/working-tree/scope.txt` — models,
drift tables, DTOs, repositories, row↔model mapping extensions, and their
tests, plus `tool/check_layering.sh`.

## Core purpose

Give the app an offline-first local data layer for M1: domain models for
every entity in `docs/BACKEND_SCHEMA.md`, drift tables that mirror the Postgres
schema, DTOs for the sync wire format, and repositories that read/write
drift while queuing an outbox row in the same transaction. Nothing here
talks to the network or does orchestration — that is M2+ (services).

## Method

Read every model (`rewizyta_models`), one full vertical slice of the
repository layer per entity (interface, impl, row mapping, DTO), the shared
database infrastructure (`app_database.dart`, `converters.dart`,
`outbox_writer.dart`, `synced_columns.dart`), the two key-value repositories
(`app_settings`, `sync_state`), the one service slice in scope
(`ClientsService`), and `tool/check_layering.sh`. CLAUDE.md mandates: no
codegen for models (hand-written `copyWith` + Equatable), interface + impl
per repository, a DTO per synced entity with `fromDomain`/`toDomain`, and an
outbox write in the same transaction as the row write. These patterns are
not simplification targets; the review looks for complexity *beyond* what
the conventions call for.

## Findings

### 1. `AppSettingsRepositoryImpl` and `SyncStateRepositoryImpl` duplicate the same key-value logic

`packages/rewizyta_repositories/lib/src/settings/app_settings_repository_impl.dart`
and `packages/rewizyta_repositories/lib/src/sync/sync_state_repository_impl.dart`
both wrap a two-column `(key, value)` drift table with: select-by-key,
delete-when-null-else-insertOnConflictUpdate. The table definitions
(`packages/rewizyta_repositories/lib/src/database/tables/key_value.dart`) are
also structurally identical (`SyncState` and `AppSettings` differ only in
`@DataClassName` and table name). `AppSettingsRepositoryImpl` additionally
exposes `watch`, which `SyncStateRepositoryImpl` does not need (sync
bookkeeping is read once per operation, never streamed).

This is the one place in the scoped diff where the "interface + impl per
entity" convention produces two near-identical implementations without a
shared instance behind them, unlike `SyncedColumns`, which already factors
out the repeated synced-row columns for every other table. A tiny shared
helper — e.g. a `KeyValueTable` mixin for the two drift tables, and a
generic `read`/`write` pair on `AppDatabase` that both repository impls
call, with `AppSettingsRepositoryImpl` adding `watch` on top — would cut
roughly 15–20 lines without weakening either interface. This is a
borderline call, not a clear violation: two tiny classes duplicating ~10
lines each is well within what the "interface per entity" convention asks
for, and a shared base here is the only place in the diff where one would
plausibly earn its keep (two call sites, identical shape). Low priority.

### No other complexity beyond the mandated conventions

Everything else in scope is as lean as the conventions allow:

- **Models** (`appointment.dart`, `client.dart`, `equipment.dart`,
  `reminder.dart`, `visit.dart`, `visit_item.dart`, `service_type.dart`,
  `trade.dart`, `device.dart`): each is a flat Equatable value class with a
  hand-written `copyWith` that only exposes the fields that are actually
  mutable in practice (e.g. `Client.copyWith` has no `id`/`createdAt`
  parameters because those never change; `Appointment`/`Reminder` correctly
  omit immutable foreign keys from `copyWith` too). `Equipment.withDue` and
  `VisitItem.withDeletedAt` are separate from `copyWith` for a real reason
  stated in their doc comments (nullable fields that `copyWith`'s
  `??`-pattern cannot clear) — not speculative API surface.
- **Repository interfaces**: every method is used by a real M1–M5 need
  (`docs/BACKEND_SCHEMA.md`'s "Due dates" section explains `lastDoneAt`;
  `findByTemplateKey` matches the documented "restore defaults" flow for
  trades/service types). No interface exposes more than the single impl
  needs; no unused generic query builder or repository base class was
  introduced.
- **DTOs**: each is a flat `fromDomain`/`toJson`/`fromJson`/`toDomain`
  quartet with a `userId` field the server fills in — exactly the
  CLAUDE.md-mandated shape, not more.
- **Shared database infra**: `converters.dart` (`DateConverter`,
  `EnumConverter<T>`, `formatDate`/`parseDate`/`formatTimestamp`/
  `parseTimestamp`/`enumToSql`) is used by essentially every table and DTO
  in scope — a real, load-bearing abstraction, not a premature one.
  `outbox_writer.dart`'s `upsertSynced` is the one place the "outbox in the
  same transaction" rule is implemented, and every repository impl calls it
  instead of reimplementing the transaction — correct reuse, not an
  unnecessary layer.
- **`tool/check_layering.sh`**: five grep-based checks, each tied to a
  specific hard rule in CLAUDE.md §10. No speculative checks for rules that
  do not exist yet.
- **Tests**: `fixtures.dart` builds one minimal valid instance per entity
  plus the handful of query-relevant variants each test file needs; no
  unused fixture builders were found in the scoped files.

## Final assessment

Total potential LOC reduction: under 1% (the one borderline key-value
duplication, ~15–20 lines).
Complexity score: Low.
Recommended action: Already minimal — optionally fold the two key-value
repositories onto one shared implementation, but this is a nice-to-have,
not a blocker.
