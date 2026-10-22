import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/pages/clients/clients_page.dart';
import 'package:rewizyta/router/route_paths.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockClientsCubit() extends MockCubit<ClientsState> implements ClientsCubit;

void main() {
  const jan = ClientListItemViewModel(
    id: '1',
    name: 'Jan Kowalski',
    addressLabel: 'ul. Leśna 12, Nysa',
    phoneDigits: '48601234567',
  );
  const anna = ClientListItemViewModel(id: '2', name: 'Anna Nowak', addressLabel: null);

  late MockClientsCubit cubit;

  setUp(() {
    cubit = MockClientsCubit();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
  });

  Widget subject() => BlocProvider<ClientsCubit>.value(value: cubit, child: const ClientsView());

  testWidgets('shows a spinner while loading', (tester) async {
    when(() => cubit.state).thenReturn(const ClientsState());

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty message and no search when there are no clients', (tester) async {
    when(() => cubit.state).thenReturn(const ClientsState(isLoading: false));

    await tester.pumpApp(subject());

    expect(find.text('Nie masz jeszcze żadnych klientów.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('renders the count and one tile per client with its address', (tester) async {
    when(() => cubit.state).thenReturn(const ClientsState(isLoading: false, items: [jan, anna]));

    await tester.pumpApp(subject());

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('ul. Leśna 12, Nysa'), findsOneWidget);
    expect(find.text('Brak adresu'), findsOneWidget);
  });

  testWidgets('typing in the search field searches', (tester) async {
    when(() => cubit.state).thenReturn(const ClientsState(isLoading: false, items: [jan, anna]));

    await tester.pumpApp(subject());
    await tester.enterText(find.byType(TextField), 'jan');

    verify(() => cubit.search('jan')).called(1);
  });

  testWidgets('a search that matches nobody says so', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(const ClientsState(isLoading: false, items: [jan], query: 'xyz'));

    await tester.pumpApp(subject());

    expect(find.text('Nikogo nie znaleziono.'), findsOneWidget);
    expect(find.text('Jan Kowalski'), findsNothing);
  });

  testWidgets('a client deleted on its card comes back with Cofnij', (tester) async {
    when(() => cubit.state).thenReturn(const ClientsState(isLoading: false, items: [jan]));
    when(() => cubit.restoreClient('1')).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: RoutePaths.clients,
      routes: [
        GoRoute(
          path: RoutePaths.clients,
          builder: (context, state) => subject(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => TextButton(
                onPressed: () => context.pop(true),
                child: const Text('delete'),
              ),
            ),
          ],
        ),
      ],
    );
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
    await tester.tap(find.text('Jan Kowalski'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();

    expect(find.text('Usunięto klienta.'), findsOneWidget);
    await tester.tap(find.text('Cofnij'));
    verify(() => cubit.restoreClient('1')).called(1);
  });
}
