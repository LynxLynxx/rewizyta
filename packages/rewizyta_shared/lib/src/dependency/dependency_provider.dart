import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

/// Thin wrapper over get_it. The app's `Dependencies` container is the only
/// subclass; `register*` is protected so nothing else can grow the DI graph.
///
/// ```dart
/// final class Dependencies extends DependencyProvider {
///   static final Dependencies instance = Dependencies._();
///   Dependencies._();
/// }
/// ```
///
/// Resolve with `DependencyProvider.instance.get<MyDependency>()` - and only at
/// the page boundary, inside `BlocProvider(create: ...)`.
abstract class DependencyProvider() {
  static final _getIt = GetIt.instance;
  static DependencyProvider? _instance;

  /// The active provider, for static contexts (bootstrap, router, pages).
  static DependencyProvider get instance {
    assert(_instance != null, 'Set DependencyProvider.instance before using it.');
    return _instance!;
  }

  static set instance(DependencyProvider instance) => _instance = instance;

  /// Clears every registration, running each `dispose:` hook. Call in tests' tearDown.
  Future<void> get reset => _getIt.reset();

  @protected
  Future<void> allReady() => _getIt.allReady();

  T get<T extends Object>({String? instanceName}) => _getIt.get<T>(instanceName: instanceName);

  Future<T> getAsync<T extends Object>() => _getIt.getAsync<T>();

  T getWithParam<T extends Object, P extends Object>({P? param}) => _getIt.get<T>(param1: param);

  bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// A fresh [T] on every resolve. Use for per-page cubits; the page's
  /// `BlocProvider` closes them. `dispose:` is not supported here.
  @protected
  void registerFactory<T extends Object>(T Function() factoryFunc, {String? instanceName}) {
    _getIt.registerFactory(factoryFunc, instanceName: instanceName);
  }

  /// Built on first resolve, then cached. Pass [dispose] whenever the instance
  /// owns a stream, subscription, database handle or is a Cubit.
  @protected
  void registerLazySingleton<T extends Object>(
    T Function() factoryFunc, {
    String? instanceName,
    DisposingFunc<T>? dispose,
  }) {
    _getIt.registerLazySingleton(factoryFunc, instanceName: instanceName, dispose: dispose);
  }

  /// An already-built value. Eager, so config values only.
  @protected
  void registerSingleton<T extends Object>(T instance, {String? instanceName}) {
    _getIt.registerSingleton(instance, instanceName: instanceName);
  }

  @protected
  void registerSingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    Iterable<Type>? dependsOn,
  }) {
    _getIt.registerSingletonAsync(factoryFunc, instanceName: instanceName, dependsOn: dependsOn);
  }
}
