import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:test/test.dart';

class MockClientsRepository() extends Mock implements ClientsRepository;

void main() {
  final now = DateTime.utc(2026, 9, 28, 12);
  late MockClientsRepository repository;
  late ClientsServiceImpl service;

  setUpAll(() => registerFallbackValue(Client(id: '', name: '', createdAt: now, updatedAt: now)));

  setUp(() {
    repository = MockClientsRepository();
    when(() => repository.upsert(any())).thenAnswer((_) async {});
    service = ClientsServiceImpl(repository, now: () => now);
  });

  group('saveClient', () {
    test('creates a client with a phone-generated id and timestamps', () async {
      final client = await service.saveClient(name: ' Jan Kowalski ', phone: '+48601234567');

      expect(client.id, isNotEmpty);
      expect(client.name, 'Jan Kowalski');
      expect(client.phone, '+48601234567');
      expect(client.createdAt, now);
      expect(client.updatedAt, now);
      verify(() => repository.upsert(client)).called(1);
    });

    test('stores blank optional fields as null', () async {
      final client = await service.saveClient(
        name: 'Jan',
        phone: ' ',
        addressLine: '',
        town: '  ',
        postalCode: '',
        note: ' ',
      );

      expect(
        [client.phone, client.addressLine, client.town, client.postalCode, client.note],
        everyElement(isNull),
      );
    });

    test('rejects an empty name', () {
      expect(
        () => service.saveClient(name: '   '),
        throwsA(
          isA<ClientValidationException>().having(
            (e) => e.error,
            'error',
            ClientValidationError.nameEmpty,
          ),
        ),
      );
    });

    test('stores a phone typed the Polish way as E.164', () async {
      for (final typed in ['601 234 567', '601-234-567', '+48 601 234 567', '0048601234567']) {
        final client = await service.saveClient(name: 'Jan', phone: typed);
        expect(client.phone, '+48601234567', reason: typed);
      }
      final foreign = await service.saveClient(name: 'Hans', phone: '+49 151 1234 5678');
      expect(foreign.phone, '+4915112345678');
    });

    test('rejects a phone that is not a number', () {
      for (final typed in ['601 234', '601 234 5678', 'abc', '+0601234567']) {
        expect(
          () => service.saveClient(name: 'Jan', phone: typed),
          throwsA(
            isA<ClientValidationException>().having(
              (e) => e.error,
              'error',
              ClientValidationError.phoneInvalid,
            ),
          ),
          reason: typed,
        );
      }
    });

    group('updating', () {
      final created = DateTime.utc(2025);

      setUp(() {
        when(() => repository.find('c1')).thenAnswer(
          (_) async => Client(
            id: 'c1',
            name: 'Old',
            addressLine: 'ul. Leśna 12',
            town: 'Nowy Targ',
            postalCode: '34-400',
            lat: 49.48,
            lng: 20.03,
            contactId: 'contact-1',
            createdAt: created,
            updatedAt: created,
          ),
        );
      });

      test('keeps createdAt, the contact link and the coordinates of the same address', () async {
        final client = await service.saveClient(
          id: 'c1',
          name: 'New',
          addressLine: ' ul. Leśna 12 ',
          town: 'Nowy Targ',
          postalCode: '34-400',
        );

        expect(client.id, 'c1');
        expect(client.name, 'New');
        expect(client.addressLine, 'ul. Leśna 12');
        expect(client.lat, 49.48);
        expect(client.lng, 20.03);
        expect(client.contactId, 'contact-1');
        expect(client.createdAt, created);
        expect(client.updatedAt, now);
      });

      test('keeps the coordinates when the form sends blanks for missing fields', () async {
        when(() => repository.find('c2')).thenAnswer(
          (_) async => Client(
            id: 'c2',
            name: 'Anna',
            town: 'Nowy Targ',
            lat: 49.48,
            lng: 20.03,
            createdAt: created,
            updatedAt: created,
          ),
        );

        final client = await service.saveClient(
          id: 'c2',
          name: 'Anna',
          addressLine: '',
          town: 'Nowy Targ',
          postalCode: ' ',
        );

        expect(client.addressLine, isNull);
        expect(client.lat, 49.48);
        expect(client.lng, 20.03);
      });

      test('keeps the coordinates when a stored address only loses its whitespace', () async {
        when(() => repository.find('c3')).thenAnswer(
          (_) async => Client(
            id: 'c3',
            name: 'Jan',
            addressLine: ' ul. Leśna 12 ',
            town: 'Nowy Targ ',
            lat: 49.48,
            lng: 20.03,
            createdAt: created,
            updatedAt: created,
          ),
        );

        final client = await service.saveClient(
          id: 'c3',
          name: 'Jan',
          addressLine: 'ul. Leśna 12',
          town: 'Nowy Targ',
        );

        expect(client.lat, 49.48);
        expect(client.lng, 20.03);
      });

      test('drops the coordinates when the address changes', () async {
        final client = await service.saveClient(
          id: 'c1',
          name: 'Old',
          addressLine: 'ul. Leśna 14',
          town: 'Nowy Targ',
          postalCode: '34-400',
        );

        expect(client.lat, isNull);
        expect(client.lng, isNull);
        expect(client.contactId, 'contact-1');
      });
    });
  });

  test('watchClients sorts the repository stream in Polish order', () async {
    Client named(String name) => Client(id: name, name: name, createdAt: now, updatedAt: now);
    when(() => repository.watchAll()).thenAnswer(
      (_) => Stream.value([named('Żak'), named('Łoś'), named('Zych')]),
    );

    final clients = await service.watchClients().first;

    expect(clients.map((c) => c.name), ['Łoś', 'Zych', 'Żak']);
  });

  test('watchClient emits the client and an error while it is unknown', () async {
    final jan = Client(id: 'c1', name: 'Jan', createdAt: now, updatedAt: now);
    when(() => repository.watch('c1')).thenAnswer((_) => Stream.fromIterable([null, jan]));

    await expectLater(
      service.watchClient('c1'),
      emitsInOrder([emitsError(isA<ClientNotFoundException>()), jan]),
    );
  });

  test('restoreClient clears deletedAt through the repository', () async {
    when(() => repository.find('c1')).thenAnswer(
      (_) async => Client(
        id: 'c1',
        name: 'Jan',
        createdAt: now,
        updatedAt: now,
        deletedAt: DateTime.utc(2026),
      ),
    );

    await service.restoreClient('c1');

    final saved = verify(() => repository.upsert(captureAny())).captured.single as Client;
    expect(saved.deletedAt, isNull);
    expect(saved.updatedAt, now);
  });

  test('deleteClient soft-deletes through the repository', () async {
    when(() => repository.find('c1'))
        .thenAnswer((_) async => Client(id: 'c1', name: 'Jan', createdAt: now, updatedAt: now));

    await service.deleteClient('c1');

    final saved = verify(() => repository.upsert(captureAny())).captured.single as Client;
    expect(saved.deletedAt, now);
  });

  test('getClient throws when the id is unknown', () {
    when(() => repository.find('missing')).thenAnswer((_) async => null);

    expect(() => service.getClient('missing'), throwsA(isA<ClientNotFoundException>()));
  });
}
