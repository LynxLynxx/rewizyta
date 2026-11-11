import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/pages/due/due_page.dart';
import 'package:rewizyta/router/routes/routing/due_route.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/fake_url_launcher.dart';
import '../../helpers/pump_app.dart';

class MockDueCubit() extends MockCubit<DueState> implements DueCubit;

void main() {
  const jan = DueListItemViewModel(
    id: '1',
    name: 'Jan Kowalski',
    town: 'Nysa',
    phone: '+48601234567',
    status: DueStatusViewModel(kind: DueStatusKind.overdue, count: 12),
  );
  const anna = DueListItemViewModel(
    id: '2',
    name: 'Anna Nowak',
    status: DueStatusViewModel(kind: DueStatusKind.soon, count: 5),
  );

  late MockDueCubit cubit;
  late FakeUrlLauncher launcher;

  setUp(() {
    launcher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    cubit = MockDueCubit();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
  });

  Widget subject() => BlocProvider<DueCubit>.value(value: cubit, child: const DueView());

  testWidgets('shows a spinner while loading', (tester) async {
    when(() => cubit.state).thenReturn(const DueState());

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('says so when nobody is due', (tester) async {
    when(() => cubit.state).thenReturn(const DueState(isLoading: false));

    await tester.pumpApp(subject());

    expect(find.text('Nikt nie czeka na przegląd w najbliższych 60 dniach.'), findsOneWidget);
  });

  testWidgets('groups the clients under their labels with the count', (tester) async {
    when(() => cubit.state).thenReturn(
      const DueState(isLoading: false, overdue: [jan], upcoming: [anna]),
    );

    await tester.pumpApp(subject());

    expect(find.text('2 klientów do obsłużenia'), findsOneWidget);
    expect(find.text('PO TERMINIE'), findsOneWidget);
    expect(find.text('NAJBLIŻSZE 60 DNI'), findsOneWidget);
    expect(find.text('Nysa'), findsOneWidget);
    expect(find.text('po terminie 12 dni'), findsOneWidget);
    expect(find.text('za 5 dni'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Jan Kowalski')).dy,
      lessThan(tester.getTopLeft(find.text('Anna Nowak')).dy),
    );
  });

  testWidgets('hides an empty group', (tester) async {
    when(() => cubit.state).thenReturn(const DueState(isLoading: false, upcoming: [anna]));

    await tester.pumpApp(subject());

    expect(find.text('1 klient do obsłużenia'), findsOneWidget);
    expect(find.text('PO TERMINIE'), findsNothing);
  });

  testWidgets('Dzwoń opens the dialer, and only for a client with a phone', (tester) async {
    when(() => cubit.state).thenReturn(
      const DueState(isLoading: false, overdue: [jan], upcoming: [anna]),
    );

    await tester.pumpApp(subject());
    expect(find.text('Dzwoń'), findsOneWidget);
    await tester.tap(find.text('Dzwoń'));
    await tester.pump();

    expect(launcher.launched, ['tel:+48601234567']);
  });

  testWidgets('a client deleted on its card comes back with Cofnij', (tester) async {
    when(() => cubit.state).thenReturn(const DueState(isLoading: false, overdue: [jan]));
    when(() => cubit.restoreClient('1')).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: const DueRoute().location,
      routes: [
        GoRoute(path: const DueRoute().location, builder: (context, state) => subject()),
        GoRoute(
          path: '/clients/:id',
          builder: (context, state) => TextButton(
            onPressed: () => context.pop(true),
            child: const Text('delete'),
          ),
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
