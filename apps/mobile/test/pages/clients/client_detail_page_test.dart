import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/clients/client_detail_page.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockClientDetailCubit() extends MockCubit<ClientDetailState> implements ClientDetailCubit;

void main() {
  late MockClientDetailCubit cubit;

  setUp(() {
    cubit = MockClientDetailCubit();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.signalStream).thenAnswer((_) => const Stream.empty());
  });

  Widget subject() =>
      BlocProvider<ClientDetailCubit>.value(value: cubit, child: const ClientDetailView());

  testWidgets('shows a spinner until the client loads', (tester) async {
    when(() => cubit.state).thenReturn(const ClientDetailState());

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Edytuj'), findsNothing);
  });

  testWidgets('renders the name, address, phone and note', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan Kowalski',
          phoneLabel: '601 234 567',
          addressLabel: 'ul. Leśna 12, Nysa',
          note: 'Pies na podwórku',
        ),
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('ul. Leśna 12, Nysa'), findsOneWidget);
    expect(find.text('601 234 567'), findsOneWidget);
    expect(find.text('NOTATKA'), findsOneWidget);
    expect(find.text('Pies na podwórku'), findsOneWidget);
    expect(find.text('Edytuj'), findsOneWidget);
  });

  testWidgets('says when there is no address and hides an empty note', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan',
          phoneLabel: null,
          addressLabel: null,
          note: null,
        ),
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('Brak adresu'), findsOneWidget);
    expect(find.text('NOTATKA'), findsNothing);
  });

  testWidgets('Usuń klienta deletes through the cubit', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan',
          phoneLabel: null,
          addressLabel: null,
          note: null,
        ),
      ),
    );
    when(cubit.deleteClient).thenAnswer((_) async {});

    await tester.pumpApp(subject());
    await tester.tap(find.text('Usuń klienta'));

    verify(cubit.deleteClient).called(1);
  });
}
