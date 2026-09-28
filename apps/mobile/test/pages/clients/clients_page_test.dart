import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/clients/clients_page.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockClientsCubit() extends MockCubit<ClientsState> implements ClientsCubit;

void main() {
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

  testWidgets('shows the empty message when there are no clients', (tester) async {
    when(() => cubit.state).thenReturn(const ClientsState(isLoading: false));

    await tester.pumpApp(subject());

    expect(find.text('Nie masz jeszcze żadnych klientów.'), findsOneWidget);
  });

  testWidgets('renders one tile per client with the formatted phone', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientsState(
        isLoading: false,
        items: [
          ClientListItemViewModel(
            id: '1',
            name: 'Jan Kowalski',
            phoneLabel: '601 234 567',
            town: 'Nysa',
          ),
          ClientListItemViewModel(id: '2', name: 'Anna Nowak', phoneLabel: null, town: null),
        ],
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('601 234 567'), findsOneWidget);
    expect(find.text('Brak numeru'), findsOneWidget);
  });
}
