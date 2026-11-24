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

class MockAppointmentsService() extends Mock implements AppointmentsService;

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
  Appointment booking(String clientId, DateTime startsAt) => Appointment(
    id: 'a$clientId',
    clientId: clientId,
    startsAt: startsAt,
    createdAt: now,
    updatedAt: now,
  );

  late MockClientsService clientsService;
  late MockEquipmentService equipmentService;
  late MockCatalogService catalogService;
  late MockAppointmentsService appointmentsService;
  late StreamController<List<Client>> clients;
  late StreamController<List<Equipment>> equipment;
  late StreamController<List<ServiceType>> serviceTypes;
  late StreamController<Map<String, Appointment>> bookings;

  DueCubit build() => DueCubit(
    clientsService,
    equipmentService,
    catalogService,
    appointmentsService,
    now: () => today,
  );

  setUp(() {
    clientsService = MockClientsService();
    equipmentService = MockEquipmentService();
    catalogService = MockCatalogService();
    appointmentsService = MockAppointmentsService();
    // Broadcast: a single-subscription controller's close() never completes
    // without a listener, which would hang tearDown.
    clients = StreamController<List<Client>>.broadcast();
    equipment = StreamController<List<Equipment>>.broadcast();
    serviceTypes = StreamController<List<ServiceType>>.broadcast();
    bookings = StreamController<Map<String, Appointment>>.broadcast();
    when(clientsService.watchClients).thenAnswer((_) => clients.stream);
    when(equipmentService.watchAll).thenAnswer((_) => equipment.stream);
    when(catalogService.watchServiceTypes).thenAnswer((_) => serviceTypes.stream);
    when(appointmentsService.watchOpenBookings).thenAnswer((_) => bookings.stream);
  });

  tearDown(() async {
    await clients.close();
    await equipment.close();
    await serviceTypes.close();
    await bookings.close();
  });

  test('initial state is loading', () {
    final cubit = build();
    expect(cubit.state, const DueState());
    expect(cubit.state.isEmpty, isFalse);
    unawaited(cubit.close());
  });

  blocTest<DueCubit, DueState>(
    'waits for all four streams, then groups and orders the due clients',
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
      serviceTypes.add(const []);
      await Future<void>.delayed(Duration.zero);
      // Still loading: an early emit here would equal the final state, which
      // emit drops, so the expect list alone would not catch it.
      expect(cubit.state.isLoading, isTrue);
      bookings.add(const {});
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
      bookings.add(const {});
    },
    expect: () => [const DueState(isLoading: false)],
    verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
  );

  blocTest<DueCubit, DueState>(
    "tags a row with its client's open booking, and a new booking re-tags it",
    build: build,
    act: (cubit) async {
      cubit.init();
      clients.add([client('a', 'Anna'), client('b', 'Bartek')]);
      equipment.add([dueIn('a', -3), dueIn('b', 5)]);
      serviceTypes.add(const []);
      bookings.add({'a': booking('a', DateTime.utc(2026, 11, 5, 8))});
      await Future<void>.delayed(Duration.zero);
      bookings.add({'b': booking('b', DateTime.utc(2026, 11, 6, 9))});
    },
    expect: () => [
      isA<DueState>()
          .having((s) => s.overdue.single.bookingAt, 'Anna', DateTime.utc(2026, 11, 5, 8))
          .having((s) => s.upcoming.single.bookingAt, 'Bartek', isNull),
      isA<DueState>()
          .having((s) => s.overdue.single.bookingAt, 'Anna', isNull)
          .having((s) => s.upcoming.single.bookingAt, 'Bartek', DateTime.utc(2026, 11, 6, 9)),
    ],
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

  test('a failing bookings stream goes to the error channel', () async {
    final cubit = build()..init();
    addTearDown(cubit.close);
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);
    addTearDown(sub.cancel);

    bookings.addError(const AppointmentNotFoundException('x'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const DueState(isLoading: false));
    expect(errors.single, isA<LocalizedAppointmentNotFoundException>());
  });

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
    expect(bookings.hasListener, isFalse);
  });
}
