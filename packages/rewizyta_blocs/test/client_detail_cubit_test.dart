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
  late StreamController<Client> client;
  late StreamController<List<Equipment>> equipment;
  late StreamController<List<ServiceType>> serviceTypes;

  ClientDetailCubit build() =>
      ClientDetailCubit(service, equipmentService, catalogService, now: () => today);

  ClientDetailState stateOf(Client client, [List<Equipment> equipment = const []]) =>
      ClientDetailState(
        client: ClientDetailViewModel.fromDomain(
          client,
          equipment: equipment,
          serviceTypes: [komin],
          today: today,
        ),
      );

  setUp(() {
    service = MockClientsService();
    equipmentService = MockEquipmentService();
    catalogService = MockCatalogService();
    client = StreamController<Client>.broadcast();
    equipment = StreamController<List<Equipment>>.broadcast();
    serviceTypes = StreamController<List<ServiceType>>.broadcast();
    when(() => service.watchClient('c1')).thenAnswer((_) => client.stream);
    when(() => equipmentService.watchByClient('c1')).thenAnswer((_) => equipment.stream);
    when(catalogService.watchServiceTypes).thenAnswer((_) => serviceTypes.stream);
  });

  tearDown(() async {
    await client.close();
    await equipment.close();
    await serviceTypes.close();
  });

  blocTest<ClientDetailCubit, ClientDetailState>(
    'init maps every change of the client to the view model',
    build: build,
    act: (cubit) {
      cubit.init('c1');
      equipment.add(const []);
      serviceTypes.add([komin]);
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
    equipment.add(const []);
    serviceTypes.add([komin]);
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
}
