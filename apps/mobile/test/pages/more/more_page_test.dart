import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/pages/catalog/catalog_page.dart';
import 'package:rewizyta/router/app_router_factory.dart';
import 'package:rewizyta/router/routes/routing/more_route.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

class MockCatalogCubit() extends MockCubit<CatalogState> implements CatalogCubit;

/// Registers into the get_it instance that `Dependencies` resolves from;
/// `register*` is protected to subclasses.
class _TestDependencies() extends DependencyProvider {
  void factory<T extends Object>(T Function() create) => registerFactory<T>(create);
}

void main() {
  tearDown(() => Dependencies.instance.reset);

  // The app's own router, so the tab, its branch and the nested route are
  // what the user gets.
  testWidgets('Usługi i cykle opens the editor inside the Więcej tab', (tester) async {
    final catalog = MockCatalogCubit();
    when(() => catalog.state).thenReturn(const CatalogState(isLoading: false));
    when(() => catalog.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => catalog.signalStream).thenAnswer((_) => const Stream.empty());
    _TestDependencies().factory<CatalogCubit>(() => catalog);
    final router = AppRouterFactory.create(initialLocation: const MoreRoute().location);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // The app bar title and the tab.
    expect(find.text('Więcej'), findsNWidgets(2));
    await tester.tap(find.text('Usługi i cykle'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogView), findsOneWidget);
    expect(router.state.uri.path, '/more/services');
    verify(catalog.init).called(1);
    // Under the tab bar, not over it.
    expect(find.text('Więcej'), findsOneWidget);
  });
}
