import 'package:drift_flutter/drift_flutter.dart';
import 'package:rewizyta/app/config/app_config.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// The single DI container. Manual registration, strictly bottom-up: a tier
/// may only resolve types registered in an earlier tier. Reading [init] top to
/// bottom is the architecture diagram.
///
/// Register against the interface (`registerLazySingleton<ClientsRepository>`)
/// so tests can substitute fakes; add `dispose:` to anything that owns a
/// stream, a database handle or is a cubit.
final class Dependencies._() extends DependencyProvider {
  static final Dependencies instance = Dependencies._();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  @override
  Future<void> get reset => super.reset.whenComplete(() => _isInitialized = false);

  Future<void> init({required AppConfig config}) async {
    // Async so that registerSingletonAsync + allReady() can slot in later.
    await Future<void>.value();
    DependencyProvider.instance = this;

    // Tier 0 - config. The only eager registration.
    registerSingleton<AppConfig>(config);

    _registerDatabases();
    _registerObservers();
    _registerNetwork();
    _registerRepositories();
    _registerSyncManagers();
    _registerReporting();
    _registerServices();
    _registerBlocs();

    _isInitialized = true;
  }

  /// Tier 1 - the local database, the deepest resource.
  void _registerDatabases() {
    registerLazySingleton<AppDatabase>(
      () => AppDatabase(driftDatabase(name: 'rewizyta')),
      dispose: (db) => db.close(),
    );
  }

  /// Tier 2 - broadcast holders of shared domain state (session, sync status).
  /// Services write to them, cubits read through services.
  void _registerObservers() {
    // M5: UserSessionObserver, SyncStatusObserver.
  }

  /// Tier 3 - the Supabase client and the sync RPC surface. The only mock
  /// seam: everything above stays identical in a mocked build.
  void _registerNetwork() {
    // M5: registerLazySingleton<SyncApi>(() => config.hasSupabase ? SupabaseSyncApi(...) : NoopSyncApi()).
  }

  /// Tier 4 - repositories over the database. No caching, no orchestration.
  void _registerRepositories() {
    registerLazySingleton<ClientsRepository>(() => ClientsRepositoryImpl(get<AppDatabase>()));
  }

  /// Tier 5 - the outbox pusher and puller (SyncService's helpers).
  void _registerSyncManagers() {
    // M5.
  }

  /// Tier 6 - analytics, crash reporting, push. Vendor adapters are chosen
  /// here and nowhere else; an empty key in AppConfig means the no-op.
  void _registerReporting() {
    registerLazySingleton<ReportingService>(NoopReportingService.new);
    registerLazySingleton<AnalyticsService>(NoopAnalyticsService.new);
    registerLazySingleton<PushNotificationsService>(NoopPushNotificationsService.new);
  }

  /// Tier 7 - domain services, the only tier cubits may inject.
  void _registerServices() {
    registerLazySingleton<ClientsService>(() => ClientsServiceImpl(get<ClientsRepository>()));
  }

  /// Tier 8 - cubits. Per-page cubits are factories (the page's BlocProvider
  /// closes them); app-wide ones are lazy singletons with a dispose hook.
  void _registerBlocs() {
    registerFactory<ClientsCubit>(() => ClientsCubit(get<ClientsService>()));
  }
}
