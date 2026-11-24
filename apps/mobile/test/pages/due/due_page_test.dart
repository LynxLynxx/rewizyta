import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/pages/booking/booking_sheet.dart';
import 'package:rewizyta/pages/due/due_page.dart';
import 'package:rewizyta/router/routes/routing/due_route.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/fake_url_launcher.dart';
import '../../helpers/pump_app.dart';

class MockDueCubit() extends MockCubit<DueState> implements DueCubit;

class MockBookingCubit() extends MockCubit<BookingState> implements BookingCubit;

/// Registers into the get_it instance that `Dependencies` resolves from;
/// `register*` is protected to subclasses.
class _TestDependencies() extends DependencyProvider {
  void factory<T extends Object>(T Function() create) => registerFactory<T>(create);
}

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

  final booked = DueListItemViewModel(
    id: '1',
    name: 'Jan Kowalski',
    phone: '+48601234567',
    status: const DueStatusViewModel(kind: DueStatusKind.overdue, count: 12),
    bookingAt: DateTime(2026, 9, 29, 9, 30).toUtc(),
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

  MockBookingCubit registerBookingCubit(String clientId) {
    final bookingCubit = MockBookingCubit();
    when(() => bookingCubit.state).thenReturn(const BookingState());
    when(() => bookingCubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => bookingCubit.signalStream).thenAnswer((_) => const Stream.empty());
    when(() => bookingCubit.init(clientId)).thenReturn(null);
    _TestDependencies().factory<BookingCubit>(() => bookingCubit);
    addTearDown(() => Dependencies.instance.reset);
    return bookingCubit;
  }

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

  group('booking', () {
    testWidgets('a booked row shows the tag and Zmień termin', (tester) async {
      when(() => cubit.state).thenReturn(DueState(isLoading: false, overdue: [booked]));

      await tester.pumpApp(subject());

      expect(find.text('umówiony wt 29.09, 09:30'), findsOneWidget);
      expect(find.text('Zmień termin'), findsOneWidget);
      expect(find.text('Umów termin'), findsNothing);
    });

    testWidgets('an unbooked row has no tag and offers Umów termin, phone or not', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        const DueState(isLoading: false, overdue: [jan], upcoming: [anna]),
      );

      await tester.pumpApp(subject());

      expect(find.textContaining('umówiony'), findsNothing);
      expect(find.text('Umów termin'), findsNWidgets(2));
      expect(find.text('Zmień termin'), findsNothing);
      // Only Jan has a phone; Anna's row still offers the booking.
      expect(find.text('Dzwoń'), findsOneWidget);
    });

    testWidgets('the button is its own 48 dp button node, not merged into the row', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      when(() => cubit.state).thenReturn(const DueState(isLoading: false, upcoming: [anna]));

      await tester.pumpApp(subject());

      expect(
        tester.getSemantics(find.text('Umów termin')),
        isSemantics(label: 'Umów termin', isButton: true),
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Umów termin')).height,
        greaterThanOrEqualTo(48),
      );
      // Inside the body: the binding checks for live handles before tearDown.
      semantics.dispose();
    });

    testWidgets('the button opens the booking sheet for the client', (tester) async {
      final bookingCubit = registerBookingCubit('2');
      when(() => cubit.state).thenReturn(const DueState(isLoading: false, upcoming: [anna]));

      await tester.pumpApp(subject());
      await tester.tap(find.text('Umów termin'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BookingSheetView), findsOneWidget);
      verify(() => bookingCubit.init('2')).called(1);
    });

    testWidgets('the button does not open the card', (tester) async {
      registerBookingCubit('1');
      when(() => cubit.state).thenReturn(const DueState(isLoading: false, overdue: [jan]));
      final router = GoRouter(
        initialLocation: const DueRoute().location,
        routes: [
          GoRoute(path: const DueRoute().location, builder: (context, state) => subject()),
          GoRoute(path: '/clients/:id', builder: (context, state) => const Text('card')),
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
      await tester.tap(find.text('Umów termin'));
      // The sheet's spinner never settles.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BookingSheetView), findsOneWidget);
      expect(find.text('card'), findsNothing);
    });
  });
}
