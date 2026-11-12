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

class MockContactsService() extends Mock implements ContactsService;

void main() {
  final now = DateTime.utc(2026);
  final today = DateTime(2026, 11, 4, 9);
  final jan = Client(
    id: 'c1',
    name: 'Jan',
    phone: '+48601234567',
    town: 'Nysa',
    createdAt: now,
    updatedAt: now,
  );
  ServiceType type(String id, int cycleMonths, {bool isArchived = false}) => ServiceType(
    id: id,
    name: id,
    cycleMonths: cycleMonths,
    isArchived: isArchived,
    createdAt: now,
    updatedAt: now,
  );
  final yearly = type('yearly', 12);
  final quarterly = type('quarterly', 3);
  final archived = type('archived', 6, isArchived: true);
  final kitchen = Equipment(
    id: 'e1',
    clientId: 'c1',
    serviceTypeId: 'yearly',
    label: 'Kuchnia',
    lastVisitAt: DateTime.utc(2025, 10, 14),
    nextDueAt: DateTime.utc(2026, 10, 14),
    createdAt: now,
    updatedAt: now,
  );

  late MockClientsService clients;
  late MockEquipmentService equipment;
  late MockCatalogService catalog;
  late MockContactsService contacts;

  ClientFormCubit build() =>
      ClientFormCubit(clients, equipment, catalog, contacts, now: () => today);

  void stubSave(Future<Client> Function() answer) {
    when(
      () => clients.saveClientWithEquipment(
        id: any(named: 'id'),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        addressLine: any(named: 'addressLine'),
        postalCode: any(named: 'postalCode'),
        town: any(named: 'town'),
        note: any(named: 'note'),
        equipment: any(named: 'equipment'),
      ),
    ).thenAnswer((_) => answer());
  }

  List<EquipmentDraft> savedDrafts() =>
      verify(
            () => clients.saveClientWithEquipment(
              id: any(named: 'id'),
              name: any(named: 'name'),
              phone: any(named: 'phone'),
              addressLine: any(named: 'addressLine'),
              postalCode: any(named: 'postalCode'),
              town: any(named: 'town'),
              note: any(named: 'note'),
              equipment: captureAny(named: 'equipment'),
            ),
          ).captured.single
          as List<EquipmentDraft>;

  setUpAll(() => registerFallbackValue(<EquipmentDraft>[]));

  setUp(() {
    clients = MockClientsService();
    equipment = MockEquipmentService();
    catalog = MockCatalogService();
    contacts = MockContactsService();
    when(catalog.ensureDefaults).thenAnswer((_) async {});
    when(
      catalog.watchServiceTypes,
    ).thenAnswer((_) => Stream.value([archived, yearly, quarterly]));
    when(() => clients.getClient('c1')).thenAnswer((_) async => jan);
    when(() => equipment.findByClient('c1')).thenAnswer((_) async => [kitchen]);
  });

  group('canSave', () {
    test('needs a name of two characters and a phone of nine digits', () {
      const valid = ClientFormState(name: 'Jo', phone: '601 234 567');
      expect(valid.canSave, isTrue);
      expect(valid.copyWith(name: ' J ').canSave, isFalse);
      expect(valid.copyWith(phone: '601 234 56').canSave, isFalse);
      expect(valid.copyWith(isSaving: true).canSave, isFalse);
    });

    test('is blocked by a last visit that is not a date', () {
      const valid = ClientFormState(name: 'Jo', phone: '601 234 567');
      const row = ClientFormEquipmentRow(rowKey: 0, serviceTypeId: 's');
      expect(valid.copyWith(equipment: [row]).canSave, isTrue);
      expect(
        valid
            .copyWith(
              equipment: [
                const ClientFormEquipmentRow(
                  rowKey: 0,
                  serviceTypeId: 's',
                  lastVisitError: LastVisitError.invalid,
                ),
              ],
            )
            .canSave,
        isFalse,
      );
    });
  });

  test('a new form seeds the catalogue and starts with one row on the first live type', () async {
    final cubit = build();

    await cubit.init(null);

    verify(catalog.ensureDefaults).called(1);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isEditing, isFalse);
    expect(cubit.state.serviceTypes, hasLength(3));
    expect(cubit.state.equipment.single.serviceTypeId, 'yearly');
    expect(cubit.state.equipment.single.id, isNull);
    await cubit.close();
  });

  test('a new form without any live type has no row and cannot add one', () async {
    when(catalog.watchServiceTypes).thenAnswer((_) => Stream.value([archived]));
    final cubit = build();

    await cubit.init(null);
    cubit.addEquipment();

    expect(cubit.state.equipment, isEmpty);
    expect(cubit.state.canAddEquipment, isFalse);
    await cubit.close();
  });

  test('an edit loads the client, the phone formatted, and locks a saved last visit', () async {
    final cubit = build();

    await cubit.init('c1');

    expect(cubit.state.isEditing, isTrue);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.name, 'Jan');
    expect(cubit.state.phone, '601 234 567');
    final row = cubit.state.equipment.single;
    expect(row.id, 'e1');
    expect(row.label, 'Kuchnia');
    expect(row.lastVisit, '14.10.2025');
    expect(row.isLastVisitLocked, isTrue);
    expect(row.nextDueLabel, '14.10.2026');
    expect(row.status, const DueStatusViewModel(kind: DueStatusKind.overdue, count: 21));
    await cubit.close();
  });

  test('a saved row without a last visit stays editable', () async {
    when(() => equipment.findByClient('c1')).thenAnswer(
      (_) async => [
        Equipment(
          id: 'e2',
          clientId: 'c1',
          serviceTypeId: 'yearly',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final cubit = build();

    await cubit.init('c1');

    expect(cubit.state.equipment.single.isLastVisitLocked, isFalse);
    expect(cubit.state.equipment.single.nextDueLabel, isNull);
    await cubit.close();
  });

  blocTest<ClientFormCubit, ClientFormState>(
    'update clears the validation error',
    build: build,
    seed: () => const ClientFormState(error: ClientValidationError.phoneInvalid),
    act: (cubit) => cubit.update(phone: '6'),
    expect: () => [const ClientFormState(phone: '6')],
  );

  group('pickContact', () {
    const typed = ClientFormState(
      name: 'Ja',
      phone: '601',
      postalCode: '48-300',
      error: ClientValidationError.phoneInvalid,
    );

    setUp(() => when(contacts.requestPermission).thenAnswer((_) async => true));

    blocTest<ClientFormCubit, ClientFormState>(
      'fills the fields from the contact, emptying what it lacks',
      setUp: () => when(contacts.pickContact).thenAnswer(
        (_) async => const PickedContact(
          name: 'Jan Kowalski',
          phone: '+48 601 234 567',
          addressLine: 'ul. Leśna 12',
          town: 'Nysa',
        ),
      ),
      build: build,
      seed: () => typed,
      act: (cubit) => cubit.pickContact(),
      expect: () => [
        const ClientFormState(
          name: 'Jan Kowalski',
          phone: '+48 601 234 567',
          addressLine: 'ul. Leśna 12',
          town: 'Nysa',
          fieldsVersion: 1,
        ),
      ],
    );

    blocTest<ClientFormCubit, ClientFormState>(
      'backing out keeps what was typed',
      setUp: () => when(contacts.pickContact).thenAnswer((_) async => null),
      build: build,
      seed: () => typed,
      act: (cubit) => cubit.pickContact(),
      expect: () => <ClientFormState>[],
    );

    test('a refused permission keeps what was typed, says so and opens no picker', () async {
      when(contacts.requestPermission).thenAnswer((_) async => false);
      final cubit = build()..emit(typed);
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);

      await cubit.pickContact();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, typed);
      expect(errors.single, isA<LocalizedContactsPermissionDeniedException>());
      verifyNever(contacts.pickContact);
      await sub.cancel();
      await cubit.close();
    });

    test('a failing picker keeps what was typed and goes to the error channel', () async {
      when(contacts.pickContact).thenThrow(Exception('picker'));
      final cubit = build()..emit(typed);
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);

      await cubit.pickContact();
      await Future<void>.delayed(Duration.zero);

      expect(errors.single, isA<LocalizedUnknownException>());
      expect(cubit.state, typed);
      await sub.cancel();
      await cubit.close();
    });

    test('a second tap while the picker opens is ignored, a later one is not', () async {
      final permission = Completer<bool>();
      when(contacts.requestPermission).thenAnswer((_) => permission.future);
      when(contacts.pickContact).thenAnswer((_) async => null);
      final cubit = build();

      final first = cubit.pickContact();
      await cubit.pickContact();
      permission.complete(true);
      await first;
      await cubit.pickContact();

      verify(contacts.requestPermission).called(2);
      verify(contacts.pickContact).called(2);
      await cubit.close();
    });
  });

  group('the next due date while typing', () {
    Future<ClientFormEquipmentRow> afterTyping(String text, {String? serviceTypeId}) async {
      final cubit = build();
      await cubit.init(null);
      final key = cubit.state.equipment.single.rowKey;
      if (serviceTypeId != null) cubit.updateEquipment(key, serviceTypeId: serviceTypeId);
      cubit.updateEquipment(key, lastVisit: text);
      final row = cubit.state.equipment.single;
      await cubit.close();
      return row;
    }

    test('a date gives the next due date and its status', () async {
      final row = await afterTyping('14.10.2025');

      expect(row.lastVisitError, isNull);
      expect(row.nextDueLabel, '14.10.2026');
      expect(row.status?.kind, DueStatusKind.overdue);
    });

    test('follows the cycle of the picked service type', () async {
      final row = await afterTyping('01.10.2026', serviceTypeId: 'quarterly');

      expect(row.nextDueLabel, '01.01.2027');
      expect(row.status, const DueStatusViewModel(kind: DueStatusKind.soon, count: 58));
    });

    test('half a date is an error and shows no due date', () async {
      final row = await afterTyping('14.10');

      expect(row.lastVisitError, LastVisitError.invalid);
      expect(row.nextDueLabel, isNull);
      expect(row.status, isNull);
    });

    test('a date after today is an error', () async {
      final row = await afterTyping('05.11.2026');

      expect(row.lastVisitError, LastVisitError.future);
      expect(row.nextDueLabel, isNull);
    });
  });

  group('rows', () {
    test('add appends a row with its own key and remove takes only that row', () async {
      final cubit = build();
      await cubit.init(null);

      cubit.addEquipment();
      final [first, second] = cubit.state.equipment;
      expect(first.rowKey, isNot(second.rowKey));

      cubit.removeEquipment(first.rowKey);
      expect(cubit.state.equipment, [second]);
      await cubit.close();
    });

    test('restore puts the row back where it was', () async {
      final cubit = build();
      await cubit.init(null);
      cubit.addEquipment();
      final [first, second] = cubit.state.equipment;

      cubit
        ..removeEquipment(first.rowKey)
        ..restoreEquipment(first, 0);

      expect(cubit.state.equipment, [first, second]);
      await cubit.close();
    });

    test('restore after the page has closed does nothing', () async {
      final cubit = build();
      await cubit.init(null);
      final row = cubit.state.equipment.single;
      await cubit.close();

      expect(() => cubit.restoreEquipment(row, 0), returnsNormally);
    });

    test('chips hide archived types except the one the row points at', () {
      final state = ClientFormState(
        serviceTypes: [
          ServiceTypeViewModel.fromDomain(archived),
          ServiceTypeViewModel.fromDomain(yearly),
        ],
      );

      expect(
        state
            .serviceTypesFor(const ClientFormEquipmentRow(rowKey: 0, serviceTypeId: 'yearly'))
            .map((type) => type.id),
        ['yearly'],
      );
      expect(
        state
            .serviceTypesFor(const ClientFormEquipmentRow(rowKey: 0, serviceTypeId: 'archived'))
            .map((type) => type.id),
        ['archived', 'yearly'],
      );
    });
  });

  group('save', () {
    test('creates the client with its drafts and signals the new id', () async {
      stubSave(() async => jan);
      final cubit = build();
      await cubit.init(null);
      cubit
        ..update(name: 'Jan', phone: '601 234 567')
        ..updateEquipment(
          cubit.state.equipment.single.rowKey,
          label: 'Kuchnia',
          lastVisit: '14.10.2025',
        );
      final signal = expectLater(
        cubit.signalStream,
        emits(const ClientFormSaved(id: 'c1', created: true)),
      );

      await cubit.save();
      await signal;

      expect(savedDrafts(), [
        EquipmentDraft(
          serviceTypeId: 'yearly',
          label: 'Kuchnia',
          lastVisitAt: DateTime.utc(2025, 10, 14),
        ),
      ]);
      expect(cubit.state.isSaving, isFalse);
      await cubit.close();
    });

    test('an edit passes the id and no date for a locked last visit', () async {
      stubSave(() async => jan);
      final cubit = build();
      await cubit.init('c1');
      final signal = expectLater(
        cubit.signalStream,
        emits(const ClientFormSaved(id: 'c1', created: false)),
      );

      await cubit.save();
      await signal;

      expect(savedDrafts(), [
        const EquipmentDraft(id: 'e1', serviceTypeId: 'yearly', label: 'Kuchnia'),
      ]);
      await cubit.close();
    });

    test('a removed saved row is left out of the drafts', () async {
      stubSave(() async => jan);
      final cubit = build();
      await cubit.init('c1');
      cubit.removeEquipment(cubit.state.equipment.single.rowKey);

      await cubit.save();

      expect(savedDrafts(), isEmpty);
      await cubit.close();
    });

    blocTest<ClientFormCubit, ClientFormState>(
      'a rejected phone becomes a field error',
      setUp: () => stubSave(
        () async => throw const ClientValidationException(ClientValidationError.phoneInvalid),
      ),
      build: build,
      seed: () => const ClientFormState(name: 'Jan', phone: '123 456 789 012 345 678'),
      act: (cubit) => cubit.save(),
      expect: () => [
        const ClientFormState(name: 'Jan', phone: '123 456 789 012 345 678', isSaving: true),
        const ClientFormState(
          name: 'Jan',
          phone: '123 456 789 012 345 678',
          error: ClientValidationError.phoneInvalid,
        ),
      ],
    );

    test('a failing write stops saving and goes to the error channel', () async {
      stubSave(() async => throw const ServiceTypeNotFoundException('s'));
      final cubit = build();
      await cubit.init('c1');
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);

      await cubit.save();
      await Future<void>.delayed(Duration.zero);

      expect(errors.single, isA<LocalizedServiceTypeNotFoundException>());
      expect(cubit.state.isSaving, isFalse);
      await sub.cancel();
      await cubit.close();
    });

    blocTest<ClientFormCubit, ClientFormState>(
      'does nothing while the form cannot be saved',
      build: build,
      act: (cubit) => cubit.save(),
      expect: () => <ClientFormState>[],
    );
  });

  test('a failing load goes to the error channel', () async {
    when(() => clients.getClient('x')).thenThrow(const ClientNotFoundException('x'));
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.init('x');
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    await sub.cancel();
    await cubit.close();
  });
}
