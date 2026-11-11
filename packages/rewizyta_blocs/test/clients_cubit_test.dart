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

void main() {
  final now = DateTime.utc(2026);
  final jan = Client(id: '1', name: 'Jan', phone: '+48601234567', createdAt: now, updatedAt: now);

  final today = DateTime.utc(2026, 11, 4);
  final due = Equipment(
    id: 'e1',
    clientId: '1',
    serviceTypeId: 's1',
    nextDueAt: DateTime.utc(2026, 11, 5),
    createdAt: now,
    updatedAt: now,
  );

  late MockClientsService service;
  late MockEquipmentService equipmentService;
  late StreamController<List<Client>> clients;
  late StreamController<List<Equipment>> equipment;

  ClientsCubit build() => ClientsCubit(service, equipmentService, now: () => today);

  setUp(() {
    service = MockClientsService();
    equipmentService = MockEquipmentService();
    // Broadcast: a single-subscription controller's close() never completes
    // without a listener, which would hang tearDown.
    clients = StreamController<List<Client>>.broadcast();
    equipment = StreamController<List<Equipment>>.broadcast();
    when(service.watchClients).thenAnswer((_) => clients.stream);
    when(equipmentService.watchAll).thenAnswer((_) => equipment.stream);
  });

  tearDown(() async {
    await clients.close();
    await equipment.close();
  });

  test('initial state is loading with no items', () {
    final cubit = build();
    expect(cubit.state, const ClientsState());
    expect(cubit.state.isEmpty, isFalse);
    unawaited(cubit.close());
  });

  blocTest<ClientsCubit, ClientsState>(
    'init maps every stream event to view models',
    build: build,
    act: (cubit) {
      cubit.init();
      equipment.add(const []);
      clients
        ..add([jan])
        ..add([]);
    },
    expect: () => [
      ClientsState(
        items: [ClientListItemViewModel.fromDomain(jan, today: today)],
        isLoading: false,
      ),
      const ClientsState(isLoading: false),
    ],
  );

  blocTest<ClientsCubit, ClientsState>(
    'waits for the equipment, then gives each client its status',
    build: build,
    act: (cubit) async {
      cubit.init();
      clients.add([
        jan,
        Client(id: '2', name: 'Anna', createdAt: now, updatedAt: now),
      ]);
      await Future<void>.delayed(Duration.zero);
      equipment.add([due]);
    },
    verify: (cubit) {
      expect(cubit.state.isLoading, isFalse);
      expect(
        cubit.state.items.first.status,
        const DueStatusViewModel(kind: DueStatusKind.soon, count: 1),
      );
      expect(cubit.state.items.last.status, isNull);
    },
  );

  blocTest<ClientsCubit, ClientsState>(
    'search keeps every item and filters the visible ones',
    build: build,
    seed: () => ClientsState(
      isLoading: false,
      items: [
        ClientListItemViewModel.fromDomain(jan, today: today),
        ClientListItemViewModel.fromDomain(
          Client(id: '2', name: 'Anna', createdAt: now, updatedAt: now),
          today: today,
        ),
      ],
    ),
    act: (cubit) => cubit.search('jan'),
    verify: (cubit) {
      expect(cubit.state.items, hasLength(2));
      expect(cubit.state.visibleItems.map((item) => item.name), ['Jan']);
    },
  );

  test('restoreClient undoes a delete through the service', () async {
    when(() => service.restoreClient('1')).thenAnswer((_) async {});
    final cubit = build();

    await cubit.restoreClient('1');

    verify(() => service.restoreClient('1')).called(1);
    await cubit.close();
  });

  test('a failing delete goes to the error channel, not to state', () async {
    when(() => service.deleteClient('x')).thenThrow(const ClientNotFoundException('x'));
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.deleteClient('x');
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    expect(cubit.state, const ClientsState());
    await sub.cancel();
    await cubit.close();
  });

  test('close cancels the subscription', () async {
    final cubit = build()..init();
    await cubit.close();
    expect(clients.hasListener, isFalse);
    expect(equipment.hasListener, isFalse);
  });
}
