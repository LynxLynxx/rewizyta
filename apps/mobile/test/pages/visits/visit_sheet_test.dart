import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/visits/visit_sheet.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockVisitFormCubit() extends MockCubit<VisitFormState> implements VisitFormCubit;

void main() {
  const chimney = ClientEquipmentViewModel(
    id: 'e1',
    status: DueStatusViewModel(kind: DueStatusKind.overdue, count: 3),
    serviceType: ServiceTypeViewModel(id: 's1', cycleMonths: 12, name: 'Komin'),
    label: 'w kuchni',
  );
  const boiler = ClientEquipmentViewModel(
    id: 'e2',
    status: DueStatusViewModel(kind: DueStatusKind.none),
    serviceType: ServiceTypeViewModel(id: 's2', cycleMonths: 12, name: 'Kocioł'),
  );
  const loaded = VisitFormState(
    isLoading: false,
    equipment: [chimney, boiler],
    ticked: {'e1'},
    date: '04.11.2026',
    nextDueLabel: '04.11.2027',
  );

  late MockVisitFormCubit cubit;
  late StreamController<VisitFormSignal> signals;

  setUp(() {
    cubit = MockVisitFormCubit();
    signals = StreamController<VisitFormSignal>.broadcast();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.signalStream).thenAnswer((_) => signals.stream);
    when(cubit.save).thenAnswer((_) async {});
  });

  tearDown(() => signals.close());

  Widget subject() => BlocProvider<VisitFormCubit>.value(
    value: cubit,
    child: const Scaffold(body: VisitSheetView()),
  );

  testWidgets('shows a spinner while loading', (tester) async {
    when(() => cubit.state).thenReturn(const VisitFormState());

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a chip per piece of equipment, ticked as the state says', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());

    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
    expect(chips.map((chip) => chip.selected), [true, false]);
    expect(find.text('Komin · w kuchni'), findsOneWidget);
    expect(find.text('04.11.2026'), findsOneWidget);
    expect(find.text('04.11.2027'), findsOneWidget);

    await tester.tap(find.text('Kocioł'));
    verify(() => cubit.toggle('e2')).called(1);
  });

  testWidgets('typing updates the cubit', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());
    await tester.enterText(find.widgetWithText(TextFormField, '04.11.2026'), '03.11.2026');
    await tester.enterText(find.byType(TextFormField).at(1), '180');
    await tester.enterText(find.byType(TextFormField).at(2), 'Ciąg dobry');

    verify(() => cubit.update(date: '03.11.2026')).called(1);
    verify(() => cubit.update(price: '180')).called(1);
    verify(() => cubit.update(note: 'Ciąg dobry')).called(1);
  });

  testWidgets('shows the field errors and keeps Zapisz off', (tester) async {
    when(() => cubit.state).thenReturn(
      const VisitFormState(
        isLoading: false,
        date: '31.02.2026',
        dateError: LastVisitError.invalid,
        price: 'abc',
        isPriceInvalid: true,
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('Wpisz datę jak 14.10.2025.'), findsOneWidget);
    expect(find.text('Wpisz kwotę jak 180 albo 180,50.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('Zapisz saves, and the saved signal closes the sheet', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    // The card's Scaffold, which the snackbar shows on.
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) => BlocProvider<VisitFormCubit>.value(
                value: cubit,
                child: const VisitSheetView(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zapisz'));
    verify(cubit.save).called(1);

    signals.add(VisitFormSignal.saved);
    await tester.pumpAndSettle();

    expect(find.byType(VisitSheetView), findsNothing);
    expect(find.text('Zapisano wizytę.'), findsOneWidget);
  });
}
