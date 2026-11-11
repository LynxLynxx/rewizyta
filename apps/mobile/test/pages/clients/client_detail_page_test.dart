import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/pages/clients/client_detail_page.dart';
import 'package:rewizyta/pages/visits/visit_sheet.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/fake_url_launcher.dart';
import '../../helpers/pump_app.dart';

class MockClientDetailCubit() extends MockCubit<ClientDetailState> implements ClientDetailCubit;

class MockVisitFormCubit() extends MockCubit<VisitFormState> implements VisitFormCubit;

/// Registers into the get_it instance that `Dependencies` resolves from;
/// `register*` is protected to subclasses.
class _TestDependencies() extends DependencyProvider {
  void factory<T extends Object>(T Function() create) => registerFactory<T>(create);
}

const _withPhone = ClientDetailState(
  client: ClientDetailViewModel(
    id: 'c1',
    name: 'Jan',
    phone: '+48601234567',
    phoneLabel: '601 234 567',
    addressLabel: null,
    note: null,
  ),
);

void main() {
  late MockClientDetailCubit cubit;
  late FakeUrlLauncher launcher;

  setUp(() {
    launcher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
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
    expect(find.text('Zapisz wizytę'), findsNothing);
  });

  testWidgets('renders the name, address, phone and note', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan Kowalski',
          phone: '+48601234567',
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
          phone: null,
          phoneLabel: null,
          addressLabel: null,
          note: null,
        ),
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('Brak adresu'), findsOneWidget);
    expect(find.text('NOTATKA'), findsNothing);
    expect(find.text('Zadzwoń'), findsNothing);
    expect(find.text('SMS'), findsNothing);
  });

  testWidgets('Zadzwoń and SMS hand the number to the system apps', (tester) async {
    when(() => cubit.state).thenReturn(_withPhone);

    await tester.pumpApp(subject());
    await tester.tap(find.text('Zadzwoń'));
    await tester.tap(find.text('SMS'));
    await tester.pump();

    expect(launcher.launched, ['tel:+48601234567', 'sms:+48601234567']);
  });

  testWidgets('Zapisz wizytę is pinned below the card', (tester) async {
    when(() => cubit.state).thenReturn(_withPhone);

    await tester.pumpApp(subject());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      find.descendant(
        of: find.byWidget(scaffold.bottomNavigationBar!),
        matching: find.text('Zapisz wizytę'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('says so when no app can take the call', (tester) async {
    when(() => cubit.state).thenReturn(_withPhone);
    launcher.fails = true;

    await tester.pumpApp(subject());
    await tester.tap(find.text('Zadzwoń'));
    await tester.pump();

    expect(find.text('Nie udało się otworzyć aplikacji telefonu.'), findsOneWidget);
  });

  testWidgets('Usuń klienta deletes through the cubit', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan',
          phone: null,
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

  testWidgets('shows the status and each piece of equipment', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan',
          phone: null,
          phoneLabel: null,
          addressLabel: null,
          note: null,
          status: DueStatusViewModel(kind: DueStatusKind.overdue, count: 2),
          equipment: [
            ClientEquipmentViewModel(
              id: 'e1',
              status: DueStatusViewModel(kind: DueStatusKind.overdue, count: 2),
              serviceType: ServiceTypeViewModel(id: 's1', name: 'Komin', cycleMonths: 12),
              label: 'Kuchnia',
              lastVisitLabel: '02.11.2025',
              nextDueLabel: '02.11.2026',
            ),
            ClientEquipmentViewModel(
              id: 'e2',
              status: DueStatusViewModel(kind: DueStatusKind.none),
              serviceType: ServiceTypeViewModel(id: 's2', name: 'Kocioł', cycleMonths: 12),
            ),
          ],
        ),
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('URZĄDZENIA'), findsOneWidget);
    expect(find.text('Komin'), findsOneWidget);
    expect(find.text('Kuchnia'), findsOneWidget);
    expect(find.text('02.11.2025'), findsOneWidget);
    expect(find.text('02.11.2026'), findsOneWidget);
    expect(find.text('Kocioł'), findsOneWidget);
    expect(find.text('po terminie 2 dni'), findsNWidgets(2));
    expect(find.text('bez terminu'), findsOneWidget);
  });

  testWidgets('hides the section for a client with no equipment', (tester) async {
    when(() => cubit.state).thenReturn(
      const ClientDetailState(
        client: ClientDetailViewModel(
          id: 'c1',
          name: 'Jan',
          phone: null,
          phoneLabel: null,
          addressLabel: null,
          note: null,
        ),
      ),
    );

    await tester.pumpApp(subject());

    expect(find.text('URZĄDZENIA'), findsNothing);
  });

  group('history', () {
    const komin = ClientEquipmentViewModel(
      id: 'e1',
      status: DueStatusViewModel(kind: DueStatusKind.later),
      serviceType: ServiceTypeViewModel(id: 's1', name: 'Komin', cycleMonths: 12),
      label: 'Kuchnia',
    );
    const withHistory = ClientDetailState(
      client: ClientDetailViewModel(
        id: 'c1',
        name: 'Jan',
        phone: null,
        phoneLabel: null,
        addressLabel: null,
        note: null,
        history: [
          ClientVisitViewModel(
            id: 'v1',
            dateLabel: '02.10.2026',
            work: [komin],
            priceLabel: '180,50',
            note: 'Sadza w kominie',
          ),
          ClientVisitViewModel(id: 'v0', dateLabel: '03.03.2025'),
        ],
      ),
    );

    testWidgets('lists each visit with its work, price and note', (tester) async {
      when(() => cubit.state).thenReturn(withHistory);

      await tester.pumpApp(subject());

      expect(find.text('HISTORIA'), findsOneWidget);
      expect(find.text('02.10.2026'), findsOneWidget);
      expect(find.text('180,50 zł'), findsOneWidget);
      expect(find.text('Komin · Kuchnia'), findsOneWidget);
      expect(find.text('Sadza w kominie'), findsOneWidget);
      expect(find.text('03.03.2025'), findsOneWidget);
    });

    testWidgets('says how to start an empty history', (tester) async {
      when(() => cubit.state).thenReturn(_withPhone);

      await tester.pumpApp(subject());

      expect(find.textContaining('Nie ma jeszcze wizyt.'), findsOneWidget);
    });

    group('a tap opens the visit on the sheet', () {
      late MockVisitFormCubit visitCubit;
      late StreamController<VisitFormSignal> visitSignals;

      setUp(() {
        visitCubit = MockVisitFormCubit();
        visitSignals = StreamController<VisitFormSignal>.broadcast();
        when(() => visitCubit.state).thenReturn(
          const VisitFormState(isLoading: false, isEditing: true, date: '02.10.2026'),
        );
        when(() => visitCubit.errorStream).thenAnswer((_) => const Stream.empty());
        when(() => visitCubit.signalStream).thenAnswer((_) => visitSignals.stream);
        when(
          () => visitCubit.init('c1', visitId: 'v1'),
        ).thenAnswer((_) async {});
        _TestDependencies().factory<VisitFormCubit>(() => visitCubit);
      });

      tearDown(() async {
        await visitSignals.close();
        await Dependencies.instance.reset;
      });

      testWidgets('and a delete there offers the undo', (tester) async {
        when(() => cubit.state).thenReturn(withHistory);
        when(() => cubit.restoreVisit('v1')).thenAnswer((_) async {});

        await tester.pumpApp(subject());
        await tester.tap(find.text('02.10.2026'));
        await tester.pumpAndSettle();

        expect(find.byType(VisitSheetView), findsOneWidget);
        verify(() => visitCubit.init('c1', visitId: 'v1')).called(1);

        visitSignals.add(VisitFormSignal.deleted);
        await tester.pumpAndSettle();

        expect(find.byType(VisitSheetView), findsNothing);
        expect(find.text('Usunięto wizytę.'), findsOneWidget);
        await tester.tap(find.text('Cofnij'));
        verify(() => cubit.restoreVisit('v1')).called(1);
      });
    });
  });
}
