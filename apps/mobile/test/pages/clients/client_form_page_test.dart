import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/clients/client_form_page.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockClientFormCubit() extends MockCubit<ClientFormState> implements ClientFormCubit;

void main() {
  late MockClientFormCubit cubit;

  setUpAll(
    () => registerFallbackValue(const ClientFormEquipmentRow(rowKey: 0, serviceTypeId: '')),
  );

  setUp(() {
    cubit = MockClientFormCubit();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.signalStream).thenAnswer((_) => const Stream.empty());
  });

  Widget subject() =>
      BlocProvider<ClientFormCubit>.value(value: cubit, child: const ClientFormView());

  final save = find.widgetWithText(FilledButton, 'Zapisz klienta');

  testWidgets('a new form has its title and a disabled save', (tester) async {
    when(() => cubit.state).thenReturn(const ClientFormState());

    await tester.pumpApp(subject());

    expect(find.text('Nowy klient'), findsOneWidget);
    expect(find.text('Imię i nazwisko albo nazwa'), findsOneWidget);
    await tester.scrollUntilVisible(save, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('an edit shows the loaded fields and saves through the cubit', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientFormState(isEditing: true, name: 'Jan', phone: '601 234 567', town: 'Nysa'),
    );
    when(cubit.save).thenAnswer((_) async {});

    await tester.pumpApp(subject());

    expect(find.text('Edycja klienta'), findsOneWidget);
    expect(find.text('601 234 567'), findsOneWidget);
    expect(find.text('Nysa'), findsOneWidget);
    await tester.scrollUntilVisible(save, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(save);
    verify(cubit.save).called(1);
  });

  testWidgets('typing updates the cubit field by field', (tester) async {
    when(() => cubit.state).thenReturn(const ClientFormState());

    await tester.pumpApp(subject());
    await tester.enterText(find.byType(TextFormField).at(0), 'Jan');
    await tester.enterText(find.byType(TextFormField).at(1), '601');

    verify(() => cubit.update(name: 'Jan')).called(1);
    verify(() => cubit.update(phone: '601')).called(1);
  });

  testWidgets('a rejected phone shows under the phone field', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientFormState(name: 'Jan', phone: '123', error: ClientValidationError.phoneInvalid),
    );

    await tester.pumpApp(subject());

    expect(find.text('Nieprawidłowy numer telefonu.'), findsOneWidget);
  });

  testWidgets('shows a spinner while an edit loads', (tester) async {
    when(() => cubit.state).thenReturn(const ClientFormState(isEditing: true, isLoading: true));

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('equipment', () {
    const yearly = ServiceTypeViewModel(id: 's1', name: 'Komin', cycleMonths: 12);
    const quarterly = ServiceTypeViewModel(id: 's2', name: 'Kocioł', cycleMonths: 3);
    const row = ClientFormEquipmentRow(rowKey: 0, serviceTypeId: 's1');
    const form = ClientFormState(serviceTypes: [yearly, quarterly], equipment: [row]);
    final lastVisit = find.widgetWithText(TextFormField, 'dd.mm.rrrr');

    Future<void> pumpForm(WidgetTester tester, ClientFormState state) async {
      when(() => cubit.state).thenReturn(state);
      await tester.pumpApp(subject());
    }

    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(finder);
      await tester.pump();
    }

    testWidgets('a row shows its chips and the hint for an empty date', (tester) async {
      await pumpForm(tester, form);

      await scrollTo(tester, find.text('Komin'));
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Komin')).selected, isTrue);
      expect(
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Kocioł')).selected,
        isFalse,
      );
      await scrollTo(tester, find.textContaining('Nie pamiętasz?'));
      expect(find.textContaining('Nie pamiętasz?'), findsOneWidget);
    });

    testWidgets('picking a chip and typing go to the cubit by row', (tester) async {
      await pumpForm(tester, form);

      await scrollTo(tester, find.text('Kocioł'));
      await tester.tap(find.text('Kocioł'));
      verify(() => cubit.updateEquipment(0, serviceTypeId: 's2')).called(1);

      await scrollTo(tester, lastVisit);
      await tester.enterText(lastVisit, '14.10.2025');
      verify(() => cubit.updateEquipment(0, lastVisit: '14.10.2025')).called(1);
    });

    testWidgets('a date shows the next due date and its status', (tester) async {
      await pumpForm(
        tester,
        form.copyWith(
          equipment: const [
            ClientFormEquipmentRow(
              rowKey: 0,
              serviceTypeId: 's1',
              lastVisit: '14.10.2025',
              nextDueLabel: '14.10.2026',
              status: DueStatusViewModel(kind: DueStatusKind.overdue, count: 21),
            ),
          ],
        ),
      );

      await scrollTo(tester, find.text('14.10.2026'));
      expect(find.text('Następny przegląd'), findsOneWidget);
      expect(find.text('po terminie 21 dni'), findsOneWidget);
    });

    testWidgets('a bad date says why instead of the hint', (tester) async {
      await pumpForm(
        tester,
        form.copyWith(
          equipment: const [
            ClientFormEquipmentRow(
              rowKey: 0,
              serviceTypeId: 's1',
              lastVisit: '14.10',
              lastVisitError: LastVisitError.invalid,
            ),
          ],
        ),
      );

      await scrollTo(tester, find.text('Wpisz datę jak 14.10.2025.'));
      expect(find.textContaining('Nie pamiętasz?'), findsNothing);
    });

    testWidgets('a saved last visit is read-only', (tester) async {
      await pumpForm(
        tester,
        form.copyWith(
          equipment: const [
            ClientFormEquipmentRow(
              rowKey: 0,
              serviceTypeId: 's1',
              id: 'e1',
              lastVisit: '14.10.2025',
              isLastVisitLocked: true,
            ),
          ],
        ),
      );

      final field = find.widgetWithText(TextFormField, '14.10.2025');
      await scrollTo(tester, field);
      expect(
        tester
            .widget<TextField>(find.descendant(of: field, matching: find.byType(TextField)))
            .readOnly,
        isTrue,
      );
    });

    testWidgets('Dodaj urządzenie adds through the cubit', (tester) async {
      await pumpForm(tester, form);

      final add = find.text('Dodaj urządzenie');
      await scrollTo(tester, add);
      await tester.tap(add);
      verify(cubit.addEquipment).called(1);
    });

    testWidgets('without a service type there is nothing to add', (tester) async {
      await pumpForm(tester, const ClientFormState());

      expect(find.text('Dodaj urządzenie'), findsNothing);
    });

    testWidgets('removing a row offers an undo that puts it back', (tester) async {
      await pumpForm(tester, form);

      final remove = find.text('Usuń urządzenie');
      await scrollTo(tester, remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      verify(() => cubit.removeEquipment(0)).called(1);
      expect(find.text('Usunięto urządzenie.'), findsOneWidget);

      await tester.tap(find.text('Cofnij'));
      verify(() => cubit.restoreEquipment(row, 0)).called(1);
    });
  });
}
