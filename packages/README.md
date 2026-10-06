# packages/

The layers of the app, one pub-workspace package each. Dependencies point
down only; `melos run layering` fails on an upward import.

| Package | Layer | May depend on |
|---|---|---|
| `rewizyta_models` | domain entities, typed exceptions, pure rules | nothing |
| `rewizyta_shared` | `DependencyProvider`, `Optional` | nothing |
| `rewizyta_localization` | ARB + generated `AppLocalizations` | nothing |
| `rewizyta_repositories` | drift database, DTOs, repositories, outbox | models, shared |
| `rewizyta_services` | services, observers, sync managers, adapter interfaces | models, repositories, shared |
| `rewizyta_view_models` | view models, formatters, `LocalizedException` | models, localization |
| `rewizyta_blocs` | cubits, states, side-channel mixins, `AppBlocObserver` | models, services, view_models, shared |

Every package has `lib/<name>.dart` as its only public file and `lib/src/<feature>/`
for the code, an `analysis_options.yaml` that includes the root one, and a
`test/` folder that mirrors `lib/src`. Read the `Client` slice across all of
them before adding a new entity; `docs/TRD.md` explains the layers.
