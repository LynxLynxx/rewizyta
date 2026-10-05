# Code Review — working tree (M1 local data layer, uncommitted on `main`)

21 findings · 🔴 0 critical · 🟡 7 important · 🔵 14 suggestions
Across 16 files. Agents: vgv-review-agent, architecture-review-agent, test-quality-review-agent, code-simplicity-review-agent.

## Findings Index

| ID | Severity | Rule | Location | Finding |
|----|----------|------|----------|---------|
| FINDING-01 | 🟡 Important | `vgv/nullable-copywith-cannot-clear` | `packages/rewizyta_models/lib/src/catalog/trade.dart:21` | Give models a way to clear nullable fields, including deletedAt |
| FINDING-02 | 🟡 Important | `vgv/enum-forward-compatibility` | `packages/rewizyta_repositories/lib/src/database/converters.dart:42` | Stop unknown server enum values from breaking older builds' pulls |
| FINDING-03 | 🟡 Important | `vgv/missing-transaction-seam` | `packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:28` | Add a transaction interface services can use without importing drift |
| FINDING-04 | 🟡 Important | `vgv/server-owned-columns-in-push` | `packages/rewizyta_repositories/lib/src/reminder/dto/reminder_dto.dart:31` | Keep reminder delivery columns the server owns out of the phone's push |
| FINDING-05 | 🟡 Important | `tests/untested-money-field` | `packages/rewizyta_repositories/test/helpers/fixtures.dart` | Money-in-grosze fields never round-tripped with a non-null value |
| FINDING-06 | 🟡 Important | `vgv/normalize-blank-input` | `packages/rewizyta_services/lib/src/client/clients_service_impl.dart:49` | Turn blank address and note fields into null before comparing and storing |
| FINDING-07 | 🟡 Important | `tests/missing-method-test` | `packages/rewizyta_services/test/clients_service_impl_test.dart` | ClientsServiceImpl.watchClients() has no test |
| FINDING-08 | 🔵 Suggestion | `vgv/doc-accuracy` | `packages/rewizyta_models/lib/src/client/client.dart:6` | Reword the Client lat/lng doc, which describes geocoding that does not exist yet |
| FINDING-09 | 🔵 Suggestion | `architecture/derived-cache-integrity` | `packages/rewizyta_models/lib/src/equipment/equipment.dart:26` | Clear due-date caches when the equipment's service type changes |
| FINDING-10 | 🔵 Suggestion | `vgv/model-unit-tests` | `packages/rewizyta_models/lib/src/equipment/equipment.dart:51` | Add direct tests for the new models' behaviour |
| FINDING-11 | 🔵 Suggestion | `architecture/barrel-surface` | `packages/rewizyta_repositories/lib/rewizyta_repositories.dart:8` | Stop exporting DTOs and OutboxOp from the repositories barrel |
| FINDING-12 | 🔵 Suggestion | `vgv/nullable-helper-over-force-unwrap` | `packages/rewizyta_repositories/lib/src/client/dto/client_dto.dart:42` | Replace repeated null-check-then-`!` ternaries with nullable converter helpers |
| FINDING-13 | 🔵 Suggestion | `vgv/timestamp-text-ordering` | `packages/rewizyta_repositories/lib/src/database/converters.dart:20` | Make stored timestamp text sort in time order |
| FINDING-14 | 🔵 Suggestion | `vgv/hoist-regex` | `packages/rewizyta_repositories/lib/src/database/converters.dart:26` | Create the enumToSql regex once instead of on every call |
| FINDING-15 | 🔵 Suggestion | `architecture/outbox-ack-contract` | `packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:30` | Document that outbox acks delete by outbox id |
| FINDING-16 | 🔵 Suggestion | `vgv/dead-plumbing` | `packages/rewizyta_repositories/lib/src/database/tables/synced_columns.dart:5` | Remove or finish the user_id path in the DTOs and local tables |
| FINDING-17 | 🔵 Suggestion | `vgv/seed-sync-conflict` | `packages/rewizyta_repositories/lib/src/database/tables/trades.dart:7` | Prevent default-catalog seeding from conflicting with synced defaults |
| FINDING-18 | 🔵 Suggestion | `simplicity/duplicate-key-value-repository` | `packages/rewizyta_repositories/lib/src/settings/app_settings_repository_impl.dart` | Unify the two key-value repository implementations |
| FINDING-19 | 🔵 Suggestion | `vgv/await-async-expectations` | `packages/rewizyta_repositories/test/catalog_repositories_impl_test.dart:50` | Use await expectLater for async throw assertions |
| FINDING-20 | 🔵 Suggestion | `vgv/one-behaviour-per-test` | `packages/rewizyta_repositories/test/dto_test.dart:15` | Split the DTO round-trip test into one test per entity |
| FINDING-21 | 🔵 Suggestion | `tests/missing-happy-path-test` | `packages/rewizyta_services/test/clients_service_impl_test.dart` | ClientsServiceImpl.getClient has no direct success-path test |

## Important

### FINDING-01 · `vgv/nullable-copywith-cannot-clear` · `packages/rewizyta_models/lib/src/catalog/trade.dart:21`
Give models a way to clear nullable fields, including deletedAt.
- **Why**: `x ?? this.x` in Trade, ServiceType, Client, Equipment, Appointment and Visit means "restore defaults" cannot undelete a row that `findByTemplateKey` returns, and `routePosition`, `appointmentId`, `tradeId`, `note` and price can never be set back to null. Two models already work around this in their own way (`withDue`, `withDeletedAt`).
- **Fix**: Use one pattern everywhere: either let models depend on `rewizyta_shared` and use `Optional<T>` (and record that in CLAUDE.md), or add consistent `withDeletedAt`/`restore()` and explicit nullable setters; add a model test for each.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md); architecture-review-agent (`architecture/model-copywith-nullable`, `appointment.dart:32`) · [details](raw/architecture-review.md)

### FINDING-02 · `vgv/enum-forward-compatibility` · `packages/rewizyta_repositories/lib/src/database/converters.dart:42`
Stop unknown server enum values from breaking older builds' pulls.
- **Why**: `EnumConverter.fromSql` throws on an unknown value, and `dto_test.dart` pins that. Adding an enum value on the server is an "expand" change under hard rule 12, yet it would make every older app's pull fail and crash its watch streams.
- **Fix**: Pick a policy and write it in DATABASE.md: either a fallback or unknown value with the row skipped or flagged on pull, or treat a new enum value as a contract change that ships in the app before the server writes it. Change the test to match.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md); architecture-review-agent (`architecture/expand-contract-compat`) · [details](raw/architecture-review.md)

### FINDING-03 · `vgv/missing-transaction-seam` · `packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:28`
Add a transaction interface services can use without importing drift.
- **Why**: TASKS.md says services wrap multi-repository writes in one drift transaction, but they can only do that through `AppDatabase`. That leaks drift into the service tier, and `check_layering.sh` would not catch it. Skipping the transaction instead risks a stale `next_due_at` (hard rule 3).
- **Fix**: Add a `TransactionRunner` interface with a drift implementation in rewizyta_repositories, register it in DI, inject it into the services, use a pass-through fake in tests, and add a layering rule that rejects `package:drift` in `rewizyta_services/lib`.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md); architecture-review-agent (`architecture/transaction-boundary`) · [details](raw/architecture-review.md)

### FINDING-04 · `vgv/server-owned-columns-in-push` · `packages/rewizyta_repositories/lib/src/reminder/dto/reminder_dto.dart:31`
Keep reminder delivery columns the server owns out of the phone's push.
- **Why**: Sync pushes the whole row and the newer `updated_at` wins. A phone that edits or cancels a stale `pending` copy overwrites the server's `sent` status, `provider_message_id`, `sent_at` and `error`.
- **Fix**: Before M5 builds `sync_push`, document that it ignores the server-owned reminder columns (allowing only pending→cancelled on `status`), or give reminders a push payload without them.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md); architecture-review-agent (`architecture/sync-column-ownership`) · [details](raw/architecture-review.md)

### FINDING-05 · `tests/untested-money-field` · `packages/rewizyta_repositories/test/helpers/fixtures.dart`
Money-in-grosze fields never round-tripped with a non-null value.
- **Why**: `ServiceType.defaultPriceGrosze` and `Visit.priceGrosze` are integer money fields under the "money is an integer in grosze" rule, yet no test builds either with a value, so a serialisation or scaling bug would go unnoticed.
- **Fix**: Give the `serviceType()` and `visit()` fixtures an optional price, and use a non-null value in dto_test.dart and the matching repository tests.
- **Reported by**: test-quality-review-agent · [details](raw/test-quality-review.md)

### FINDING-06 · `vgv/normalize-blank-input` · `packages/rewizyta_services/lib/src/client/clients_service_impl.dart:49`
Turn blank address and note fields into null before comparing and storing.
- **Why**: A form that sends '' where a null is stored fails the `keepsCoordinates` check, so geocoded lat/lng are dropped even though the address has not changed. '' also gets stored and synced instead of null.
- **Fix**: Add one `_blankToNull` helper for addressLine, town, postalCode and note (as `phone` already does), and a service test where '' arrives against a stored null.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md); architecture-review-agent (`architecture/input-normalisation`, Suggestion) · [details](raw/architecture-review.md)

### FINDING-07 · `tests/missing-method-test` · `packages/rewizyta_services/test/clients_service_impl_test.dart`
ClientsServiceImpl.watchClients() has no test.
- **Why**: Coverage shows line 17 of the service is never run. CLAUDE.md requires a test for every service method, and a regression here (filtering the stream by mistake, say) would go unnoticed.
- **Fix**: Add a test that stubs `repository.watchAll()` and asserts `service.watchClients()` passes the stream through unchanged.
- **Reported by**: test-quality-review-agent · [details](raw/test-quality-review.md)

## Suggestions

### FINDING-08 · `vgv/doc-accuracy` · `packages/rewizyta_models/lib/src/client/client.dart:6`
Reword the Client lat/lng doc, which describes geocoding that does not exist yet.
- **Why**: The doc says lat/lng are geocoded on save, but no code sets them; `saveClient` can only keep or drop them.
- **Fix**: Describe it as the intended contract: set by geocoding after a save, cleared when the address changes.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-09 · `architecture/derived-cache-integrity` · `packages/rewizyta_models/lib/src/equipment/equipment.dart:26`
Clear due-date caches when the equipment's service type changes.
- **Why**: `copyWith(serviceTypeId:)` keeps a `nextDueAt` computed from the old cycle, and the repository saves it as given. Hard rule 3 then depends on every caller remembering `withDue`.
- **Fix**: Null `lastVisitAt` and `nextDueAt` in `copyWith` when `serviceTypeId` changes, or require the new dates in a dedicated method.
- **Reported by**: architecture-review-agent · [details](raw/architecture-review.md)

### FINDING-10 · `vgv/model-unit-tests` · `packages/rewizyta_models/lib/src/equipment/equipment.dart:51`
Add direct tests for the new models' behaviour.
- **Why**: `withDue`, `withDeletedAt`, `copyWith` field preservation and `isDeleted` are tested only indirectly through the repository tests.
- **Fix**: Add a models_test.dart, especially once the field-clearing helpers exist.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-11 · `architecture/barrel-surface` · `packages/rewizyta_repositories/lib/rewizyta_repositories.dart:8`
Stop exporting DTOs and OutboxOp from the repositories barrel.
- **Why**: Public DTOs invite a future SyncService in the services package to handle wire shapes. `OutboxOp` is exported only for tests.
- **Fix**: Keep `dto/*` and `OutboxOp` in `src/`, let tests import `src/`, and give repositories an apply-pulled-rows method for the sync to call.
- **Reported by**: architecture-review-agent · [details](raw/architecture-review.md)

### FINDING-12 · `vgv/nullable-helper-over-force-unwrap` · `packages/rewizyta_repositories/lib/src/client/dto/client_dto.dart:42`
Replace repeated null-check-then-`!` ternaries with nullable converter helpers.
- **Why**: About 20 copies of `x == null ? null : formatTimestamp(x!)` across the DTOs add a force-unwrap at each site and clutter the code.
- **Fix**: Add `formatTimestampOrNull`/`parseTimestampOrNull` and date equivalents to converters.dart.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-13 · `vgv/timestamp-text-ordering` · `packages/rewizyta_repositories/lib/src/database/converters.dart:20`
Make stored timestamp text sort in time order.
- **Why**: `toIso8601String()` omits the microsecond digits when they are zero, so `…00.001Z` sorts after `…00.001500Z`, and range bounds can exclude rows in the same millisecond.
- **Fix**: Truncate instants to milliseconds in `toCompanion` (or always write six fractional digits), or soften the "text comparison compares instants" comments.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-14 · `vgv/hoist-regex` · `packages/rewizyta_repositories/lib/src/database/converters.dart:26`
Create the enumToSql regex once instead of on every call.
- **Why**: Every enum encode builds a new RegExp, and `fromSql` recomputes the snake_case name of every enum value for each row it reads.
- **Fix**: Move the regex to a top-level final and optionally cache a `Map<String, T>` in `EnumConverter`.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-15 · `architecture/outbox-ack-contract` · `packages/rewizyta_repositories/lib/src/database/outbox_writer.dart:30`
Document that outbox acks delete by outbox id.
- **Why**: A write during a push replaces the in-flight entry, so an ack keyed on (entity, entity_id) would drop the newer change.
- **Fix**: State the rule in the `upsertSynced` doc and in ARCHITECTURE.md "Push", and add a test when SyncService lands.
- **Reported by**: architecture-review-agent · [details](raw/architecture-review.md)

### FINDING-16 · `vgv/dead-plumbing` · `packages/rewizyta_repositories/lib/src/database/tables/synced_columns.dart:5`
Remove or finish the user_id path in the DTOs and local tables.
- **Why**: Only tests pass the `userId` argument to `fromDomain`; `toDomain` and `toCompanion` drop it, so the local column can never be filled as its doc claims, and every push sends `"user_id": null`.
- **Fix**: Drop the DTO `userId` parameter and the local column, or wire them end to end when the pull is built (and correct the comment either way).
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md); architecture-review-agent (`architecture/dead-column`, `synced_columns.dart:10`) · [details](raw/architecture-review.md)

### FINDING-17 · `vgv/seed-sync-conflict` · `packages/rewizyta_repositories/lib/src/database/tables/trades.dart:7`
Prevent default-catalog seeding from conflicting with synced defaults.
- **Why**: A second phone that seeds defaults before its first pull creates different ids for the same template_key, so the unique index rejects the pull locally and the server rejects the push.
- **Fix**: In the DefaultCatalog seed service, seed only after the first pull or derive ids deterministically; record the choice in DATABASE.md.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-18 · `simplicity/duplicate-key-value-repository` · `packages/rewizyta_repositories/lib/src/settings/app_settings_repository_impl.dart`
Unify the two key-value repository implementations.
- **Why**: Both wrap structurally identical (key, value) drift tables with the same select and delete-or-upsert logic, about 10 duplicated lines each (see also `sync/sync_state_repository_impl.dart`).
- **Fix**: Add a shared key-value table mixin and a generic read/write helper on AppDatabase that both implementations call, with AppSettingsRepositoryImpl adding watch on top.
- **Reported by**: code-simplicity-review-agent · [details](raw/code-simplicity-review.md)

### FINDING-19 · `vgv/await-async-expectations` · `packages/rewizyta_repositories/test/catalog_repositories_impl_test.dart:50`
Use await expectLater for async throw assertions.
- **Why**: Several tests call `expect(() => future, throwsA(...))` without await, while app_database_test uses `await expectLater`; the two styles are mixed and the order relative to tearDown is implicit.
- **Fix**: Use `await expectLater(repo.upsert(...), throwsA(...))` everywhere.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-20 · `vgv/one-behaviour-per-test` · `packages/rewizyta_repositories/test/dto_test.dart:15`
Split the DTO round-trip test into one test per entity.
- **Why**: One test checks nine entities, so the first failure hides the others and the report does not say which entity broke.
- **Fix**: Generate one `test` per DTO from a table of cases.
- **Reported by**: vgv-review-agent · [details](raw/vgv-review.md)

### FINDING-21 · `tests/missing-happy-path-test` · `packages/rewizyta_services/test/clients_service_impl_test.dart`
ClientsServiceImpl.getClient has no direct success-path test.
- **Why**: Only the not-found path is tested directly; the success path is only exercised as a side effect of unrelated saveClient update tests.
- **Fix**: Add a direct test that `getClient` returns the client it finds, for symmetry with the existing not-found test.
- **Reported by**: test-quality-review-agent · [details](raw/test-quality-review.md)

## Why this matters

Nothing here blocks M1. The four important design findings (FINDING-01 to FINDING-04) are all about the sync contract and the services that come next. Fixing them now, while no build has shipped and no `sync_push` exists, costs a few lines. After release they become migrations and broken pulls on older phones. The cheapest win is the transaction interface plus the copyWith pattern, because every M1 service will be built on both.
