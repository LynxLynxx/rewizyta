import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rewizyta/pages/clients/client_detail_page.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/pump_app.dart';

class MockClientDetailCubit() extends MockCubit<ClientDetailState> implements ClientDetailCubit;

/// Records launched URLs; `fails` makes it throw as Android does without a
/// matching app.
class _FakeUrlLauncher() extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<String> launched = [];
  bool fails = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (fails) throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
    launched.add(url);
    return true;
  }
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
  late _FakeUrlLauncher launcher;

  setUp(() {
    launcher = _FakeUrlLauncher();
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
}
