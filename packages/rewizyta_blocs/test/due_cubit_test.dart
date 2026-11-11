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

void main() {
  final now = DateTime.utc(2026);
  final today = DateTime.utc(2026, 11, 4);

  Client client(String id, String name) =>
      Client(id: id, name: name, createdAt: now, updatedAt: now);
  Equipment dueIn(String clientId, int days) => Equipment(
    id: 'e$clientId',
    clientId: clientId,
    serviceTypeId: 's1',
    nextDueAt: today.add(Duration(days: days)),
    createdAt: now,
    updatedAt: now,
  );

  late MockClientsService clientsService;
  late MockEquipmentService equipmentService;
  late MockCatalogService catalogService;
  late StreamController<List<Client>> clients;
  late StreamController<List<Equipment>> equipment;
  late StreamController<List<ServiceType>> serviceTypes;

  DueCubit build() => DueCubit(clientsService, equipmentService, catalogService, now: () => today);

  setUp(() {
    clientsService = MockClientsService();
    equipmentService = MockEquipmentService();
    catalogService = MockCatalogService();
    // Broadcast: a single-subscription controller's close() never completes
    // without a listener, which would hang tearDown.
    clients = StreamController<List<Client>>.broadcast();
    equipment = StreamController<List<Equipment>>.broadcast();
    serviceTypes = StreamController<List<ServiceType>>.broadcast();
    when(clientsService.watchClients).thenAnswer((_) => clients.stream);
    when(equipmentService.watchAll).thenAnswer((_) => equipment.stream);
    when(catalogService.watchServiceTypes).thenAnswer((_) => serviceTypes.stream);
  });

  tearDown(() async {
    await clients.close();
    await equipment.close();
    await serviceTypes.close();
  });

  test('initial state is loading', () {
    final cubit = build();
    expect(cubit.state, const DueState());
    expect(cubit.state.isEmpty, isFalse);
    unawaited(cubit.close());
  });

  blocTest<DueCubit, DueState>(
    'waits for all three streams, then groups and orders the due clients',
    build: build,
    act: (cubit) async {
      cubit.init();
      clients.add([
        client('a', 'Anna'),
        client('b', 'Bartek'),
        client('c', 'Celina'),
        client('d', 'Dorota'),
        client('e', 'Edward'),
        client('f', 'Franek'),
      ]);
      equipment.add([
        dueIn('a', 30),
        dueIn('b', -3),
        dueIn('c', -10),
        dueIn('d', 0),
        dueIn('e', 61),
        dueIn('f', -3),
      ]);
      await Future<void>.delayed(Duration.zero);
      serviceTypes.add(const []);
    },
    expect: () => [
      isA<DueState>()
          .having((s) => s.isLoading, 'isLoading', isFalse)
          .having((s) => s.overdue.map((i) => i.name), 'overdue', ['Celina', 'Bartek', 'Franek'])
          .having((s) => s.upcoming.map((i) => i.name), 'upcoming', ['Dorota', 'Anna'])
          .having((s) => s.count, 'count', 5),
    ],
  );

  blocTest<DueCubit, DueState>(
    'is empty when nobody is due',
    build: build,
    act: (cubit) {
      cubit.init();
      clients.add([client('a', 'Anna')]);
      equipment.add(const []);
      serviceTypes.add(const []);
    },
    expect: () => [const DueState(isLoading: false)],
    verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
  );

  blocTest<DueCubit, DueState>(
    'a failing stream stops the spinner and goes to the error channel',
    build: build,
    act: (cubit) {
      cubit.init();
      clients.addError(const ClientNotFoundException('x'));
    },
    expect: () => [const DueState(isLoading: false)],
  );

  test('restoreClient undoes a delete through the service', () async {
    when(() => clientsService.restoreClient('a')).thenAnswer((_) async {});
    final cubit = build();

    await cubit.restoreClient('a');

    verify(() => clientsService.restoreClient('a')).called(1);
    await cubit.close();
  });

  test('a failing restore goes to the error channel', () async {
    when(
      () => clientsService.restoreClient('x'),
    ).thenThrow(const ClientNotFoundException('x'));
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.restoreClient('x');
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    await sub.cancel();
    await cubit.close();
  });

  test('close cancels the subscriptions', () async {
    final cubit = build()..init();
    await cubit.close();
    expect(clients.hasListener, isFalse);
    expect(equipment.hasListener, isFalse);
    expect(serviceTypes.hasListener, isFalse);
  });
}
