import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/pages/catalog/catalog_page.dart';
import 'package:rewizyta/pages/catalog/service_type_sheet.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockCatalogCubit() extends MockCubit<CatalogState> implements CatalogCubit;

class MockServiceTypeFormCubit()
    extends MockCubit<ServiceTypeFormState>
    implements ServiceTypeFormCubit;

/// Registers into the get_it instance that `Dependencies` resolves from;
/// `register*` is protected to subclasses.
class _TestDependencies() extends DependencyProvider {
  void factory<T extends Object>(T Function() create) => registerFactory<T>(create);
}

void main() {
  const inspection = ServiceTypeViewModel(
    id: 's1',
    cycleMonths: 12,
    template: ServiceTypeTemplate.chimneyInspection,
  );
  const coal = ServiceTypeViewModel(
    id: 's2',
    cycleMonths: 3,
    name: 'Kocioł węglowy',
    defaultPriceGrosze: 18050,
    isArchived: true,
  );
  const loaded = CatalogState(
    isLoading: false,
    trades: [
      CatalogTradeViewModel(
        id: 't1',
        template: TradeTemplate.chimney,
        serviceTypes: [inspection, coal],
      ),
      CatalogTradeViewModel(id: 't2', name: 'Wentylacja'),
    ],
  );

  late MockCatalogCubit cubit;
  late StreamController<CatalogSignal> signals;

  setUp(() {
    cubit = MockCatalogCubit();
    signals = StreamController<CatalogSignal>.broadcast();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.signalStream).thenAnswer((_) => signals.stream);
    when(cubit.restoreDefaults).thenAnswer((_) async {});
    when(() => cubit.addTrade(any())).thenAnswer((_) async {});
  });

  tearDown(() => signals.close());

  Widget subject() => BlocProvider<CatalogCubit>.value(value: cubit, child: const CatalogView());

  testWidgets('shows a spinner while loading', (tester) async {
    when(() => cubit.state).thenReturn(const CatalogState());

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('groups the service types under upper-case trades', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());

    expect(find.text('Usługi i cykle'), findsOneWidget);
    expect(find.text('KOMINIARZ'), findsOneWidget);
    expect(find.text('Przegląd przewodów kominowych'), findsOneWidget);
    expect(find.text('co 12 mies.'), findsOneWidget);
    expect(find.text('Kocioł węglowy'), findsOneWidget);
    expect(find.text('co 3 mies. · 180,50 zł · w archiwum'), findsOneWidget);
    expect(find.text('WENTYLACJA'), findsOneWidget);
    expect(find.text('Dodaj usługę'), findsNWidgets(2));
    expect(find.textContaining('Nie masz jeszcze usług.'), findsNothing);
  });

  testWidgets('an empty catalogue says what to do, and restores the defaults', (tester) async {
    when(() => cubit.state).thenReturn(const CatalogState(isLoading: false));

    await tester.pumpApp(subject());
    await tester.tap(find.text('Przywróć domyślne'));

    expect(
      find.text('Nie masz jeszcze usług. Przywróć domyślne albo dodaj własną branżę.'),
      findsOneWidget,
    );
    verify(cubit.restoreDefaults).called(1);
  });

  testWidgets('the restored signal says so', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());
    signals.add(CatalogSignal.defaultsRestored);
    await tester.pumpAndSettle();

    expect(find.text('Przywrócono domyślne usługi.'), findsOneWidget);
  });

  testWidgets('Dodaj branżę asks for a name, then adds the trade', (tester) async {
    when(() => cubit.state).thenReturn(const CatalogState(isLoading: false));

    await tester.pumpApp(subject());
    await tester.tap(find.text('Dodaj branżę'));
    await tester.pumpAndSettle();

    expect(find.text('Nowa branża'), findsOneWidget);
    FilledButton save() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Zapisz'));
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  ');
    await tester.pump();
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextField), ' Wentylacja ');
    await tester.pump();
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(find.text('Nowa branża'), findsNothing);
    verify(() => cubit.addTrade('Wentylacja')).called(1);
  });

  testWidgets('a dismissed trade sheet adds nothing', (tester) async {
    when(() => cubit.state).thenReturn(const CatalogState(isLoading: false));

    await tester.pumpApp(subject());
    await tester.tap(find.text('Dodaj branżę'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.addTrade(any()));
  });

  group('the service type sheet', () {
    late MockServiceTypeFormCubit formCubit;

    setUp(() {
      formCubit = MockServiceTypeFormCubit();
      when(() => formCubit.state).thenReturn(const ServiceTypeFormState(cycle: '12'));
      when(() => formCubit.errorStream).thenAnswer((_) => const Stream.empty());
      when(() => formCubit.signalStream).thenAnswer((_) => const Stream.empty());
      _TestDependencies().factory<ServiceTypeFormCubit>(() => formCubit);
    });

    tearDown(() => Dependencies.instance.reset);

    testWidgets('opens on a tapped row with that type', (tester) async {
      when(() => cubit.state).thenReturn(loaded);

      await tester.pumpApp(subject());
      await tester.tap(find.text('Kocioł węglowy'));
      await tester.pumpAndSettle();

      expect(find.byType(ServiceTypeSheetView), findsOneWidget);
      verify(() => formCubit.init(tradeId: 't1', type: coal)).called(1);
    });

    testWidgets('Dodaj usługę opens it empty under that trade', (tester) async {
      when(() => cubit.state).thenReturn(loaded);

      await tester.pumpApp(subject());
      final addToVentilation = find.text('Dodaj usługę').last;
      await tester.ensureVisible(addToVentilation);
      await tester.tap(addToVentilation);
      await tester.pumpAndSettle();

      expect(find.byType(ServiceTypeSheetView), findsOneWidget);
      verify(() => formCubit.init(tradeId: 't2')).called(1);
    });
  });
}
