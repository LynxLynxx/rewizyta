import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/catalog/service_type_sheet.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

import '../../helpers/pump_app.dart';

class MockServiceTypeFormCubit()
    extends MockCubit<ServiceTypeFormState>
    implements ServiceTypeFormCubit;

void main() {
  const newType = ServiceTypeFormState(cycle: '12');
  const boiler = ServiceTypeFormState(
    isEditing: true,
    template: ServiceTypeTemplate.boilerService,
    cycle: '12',
    price: '180,50',
  );

  late MockServiceTypeFormCubit cubit;
  late StreamController<ServiceTypeFormSignal> signals;

  setUp(() {
    cubit = MockServiceTypeFormCubit();
    signals = StreamController<ServiceTypeFormSignal>.broadcast();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.signalStream).thenAnswer((_) => signals.stream);
    when(cubit.save).thenAnswer((_) async {});
  });

  tearDown(() => signals.close());

  Widget subject() => BlocProvider<ServiceTypeFormCubit>.value(
    value: cubit,
    child: const Scaffold(body: ServiceTypeSheetView()),
  );

  testWidgets('a new type: its title and hint, no archive, Zapisz off without a name', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(newType);

    await tester.pumpApp(subject());

    expect(find.text('Nowa usługa'), findsOneWidget);
    expect(find.text('np. Przegląd wentylacji'), findsOneWidget);
    expect(find.text('Zmiana przesunie terminy urządzeń z tą usługą.'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('a default shows its own name as the hint and can be archived', (tester) async {
    when(() => cubit.state).thenReturn(boiler);

    await tester.pumpApp(subject());

    expect(find.text('Usługa'), findsOneWidget);
    expect(find.text('Przegląd kotła'), findsOneWidget);
    expect(find.text('180,50'), findsOneWidget);
    expect(find.text('W archiwum'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    verify(() => cubit.update(isArchived: true)).called(1);
  });

  testWidgets('typing updates the cubit', (tester) async {
    when(() => cubit.state).thenReturn(boiler);

    await tester.pumpApp(subject());
    await tester.enterText(find.byType(TextFormField).at(0), 'Kocioł');
    await tester.enterText(find.byType(TextFormField).at(1), '24');
    await tester.enterText(find.byType(TextFormField).at(2), '250');

    verify(() => cubit.update(name: 'Kocioł')).called(1);
    verify(() => cubit.update(cycle: '24')).called(1);
    verify(() => cubit.update(price: '250')).called(1);
  });

  testWidgets('shows the cycle and price errors inline and keeps Zapisz off', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(const ServiceTypeFormState(name: 'Komin', cycle: '0', price: 'abc'));

    await tester.pumpApp(subject());

    expect(find.text('Wpisz liczbę miesięcy od 1 do 120.'), findsOneWidget);
    expect(find.text('Wpisz kwotę jak 180 albo 180,50.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('Zapisz saves, and the saved signal closes the sheet', (tester) async {
    when(() => cubit.state).thenReturn(boiler);
    // The editor's Scaffold, which the snackbar shows on.
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) => BlocProvider<ServiceTypeFormCubit>.value(
                value: cubit,
                child: const ServiceTypeSheetView(),
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

    signals.add(ServiceTypeFormSignal.saved);
    await tester.pumpAndSettle();

    expect(find.byType(ServiceTypeSheetView), findsNothing);
    expect(find.text('Zapisano.'), findsOneWidget);
  });
}
