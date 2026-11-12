import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

class MockClientsService() extends Mock implements ClientsService;

class MockEquipmentService() extends Mock implements EquipmentService;

class MockCatalogService() extends Mock implements CatalogService;

class MockVisitsService() extends Mock implements VisitsService;

void main() {
  final now = DateTime.utc(2026);
  final jan = Client(id: 'c1', name: 'Jan', phone: '+48601234567', createdAt: now, updatedAt: now);

  final today = DateTime.utc(2026, 11, 4);
  final kitchen = Equipment(
    id: 'e1',
    clientId: 'c1',
    serviceTypeId: 's1',
    createdAt: now,
    updatedAt: now,
  );
  final komin = ServiceType(
    id: 's1',
    name: 'Komin',
    cycleMonths: 12,
    createdAt: now,
    updatedAt: now,
  );

  late MockClientsService service;
  late MockEquipmentService equipmentService;
  late MockCatalogService catalogService;
  late MockVisitsService visitsService;
  late StreamController<Client> client;
  late StreamController<List<Equipment>> equipment;
  late StreamController<List<ServiceType>> serviceTypes;
  late StreamController<List<Visit>> visits;
  late StreamController<List<VisitItem>> visitItems;

  ClientDetailCubit build() => ClientDetailCubit(
    service,
    equipmentService,
    catalogService,
    visitsService,
    now: () => today,
  );

  ClientDetailState stateOf(
    Client client, [
    List<Equipment> equipment = const [],
    List<Visit> visits = const [],
    List<VisitItem> visitItems = const [],
  ]) => ClientDetailState(
    client: ClientDetailViewModel.fromDomain(
      client,
      equipment: equipment,
      serviceTypes: [komin],
      visits: visits,
      visitItems: visitItems,
      today: today,
    ),
  );

  /// Everything but the client row, which each test sends itself.
  void loadRest() {
    equipment.add(const []);
    serviceTypes.add([komin]);
    visits.add(const []);
    visitItems.add(const []);
  }

  setUp(() {
    service = MockClientsService();
    equipmentService = MockEquipmentService();
    catalogService = MockCatalogService();
    visitsService = MockVisitsService();
    client = StreamController<Client>.broadcast();
    equipment = StreamController<List<Equipment>>.broadcast();
    serviceTypes = StreamController<List<ServiceType>>.broadcast();
    visits = StreamController<List<Visit>>.broadcast();
    visitItems = StreamController<List<VisitItem>>.broadcast();
    when(() => service.watchClient('c1')).thenAnswer((_) => client.stream);
    when(
      () => equipmentService.watchByClient('c1', includeDeleted: true),
    ).thenAnswer((_) => equipment.stream);
    when(catalogService.watchServiceTypes).thenAnswer((_) => serviceTypes.stream);
    when(() => visitsService.watchByClient('c1')).thenAnswer((_) => visits.stream);
    when(() => visitsService.watchItemsByClient('c1')).thenAnswer((_) => visitItems.stream);
  });

  tearDown(() async {
    await client.close();
    await equipment.close();
    await serviceTypes.close();
    await visits.close();
    await visitItems.close();
  });

  blocTest<ClientDetailCubit, ClientDetailState>(
    'init maps every change of the client to the view model',
    build: build,
    act: (cubit) {
      cubit.init('c1');
      loadRest();
      client
        ..add(jan)
        ..add(jan.copyWith(name: 'Jan Kowalski'));
    },
    expect: () => [stateOf(jan), stateOf(jan.copyWith(name: 'Jan Kowalski'))],
  );

  blocTest<ClientDetailCubit, ClientDetailState>(
    'waits for the equipment and the service types, then follows the equipment',
    build: build,
    act: (cubit) async {
      cubit.init('c1');
      client.add(jan);
      visits.add(const []);
      visitItems.add(const []);
      await Future<void>.delayed(Duration.zero);
      equipment.add([kitchen]);
      await Future<void>.delayed(Duration.zero);
      serviceTypes.add([komin]);
      await Future<void>.delayed(Duration.zero);
      equipment.add(const []);
    },
    expect: () => [
      stateOf(jan, [kitchen]),
      stateOf(jan),
    ],
  );

  test('an unknown id goes to the error channel', () async {
    final cubit = build()..init('c1');
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    client.addError(const ClientNotFoundException('c1'));
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    await sub.cancel();
    await cubit.close();
  });

  test('deleteClient soft-deletes and signals the page', () async {
    when(() => service.deleteClient('c1')).thenAnswer((_) async {});
    final cubit = build()..init('c1');
    final signals = <ClientDetailSignal>[];
    final sub = cubit.signalStream.listen(signals.add);
    loadRest();
    client.add(jan);
    await Future<void>.delayed(Duration.zero);

    await cubit.deleteClient();
    await Future<void>.delayed(Duration.zero);

    verify(() => service.deleteClient('c1')).called(1);
    expect(signals, [ClientDetailSignal.deleted]);
    await sub.cancel();
    await cubit.close();
  });

  test('deleteClient does nothing before the client has loaded', () async {
    final cubit = build();

    await cubit.deleteClient();

    verifyNever(() => service.deleteClient(any()));
    await cubit.close();
  });

  blocTest<ClientDetailCubit, ClientDetailState>(
    'waits for the visits and their items, then follows the history',
    build: build,
    act: (cubit) async {
      final done = Visit(id: 'v1', clientId: 'c1', doneAt: today, createdAt: now, updatedAt: now);
      final item = VisitItem(
        id: 'i1',
        visitId: 'v1',
        equipmentId: 'e1',
        createdAt: now,
        updatedAt: now,
      );
      cubit.init('c1');
      client.add(jan);
      equipment.add([kitchen]);
      serviceTypes.add([komin]);
      visits.add([done]);
      await Future<void>.delayed(Duration.zero);
      visitItems.add([item]);
      await Future<void>.delayed(Duration.zero);
      visits.add(const []);
    },
    expect: () => [
      isA<ClientDetailState>().having(
        (s) => s.client?.history.single.work.single.id,
        'serviced',
        'e1',
      ),
      isA<ClientDetailState>().having((s) => s.client?.history, 'history', isEmpty),
    ],
  );

  group('restoreVisit', () {
    test('restores through the service', () async {
      when(() => visitsService.restoreVisit('v1')).thenAnswer((_) async {});
      final cubit = build();

      await cubit.restoreVisit('v1');

      verify(() => visitsService.restoreVisit('v1')).called(1);
      await cubit.close();
    });

    test('a failure goes to the error channel', () async {
      when(
        () => visitsService.restoreVisit('v1'),
      ).thenThrow(const VisitNotFoundException('v1'));
      final cubit = build();
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);

      await cubit.restoreVisit('v1');
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      await sub.cancel();
      await cubit.close();
    });
  });
}
