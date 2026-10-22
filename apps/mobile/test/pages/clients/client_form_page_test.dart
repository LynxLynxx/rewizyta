import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/clients/client_form_page.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

import '../../helpers/pump_app.dart';

class MockClientFormCubit() extends MockCubit<ClientFormState> implements ClientFormCubit;

void main() {
  late MockClientFormCubit cubit;

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
}
