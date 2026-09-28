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

    test('rejects a phone that is not E.164', () {
      expect(
        () => service.saveClient(name: 'Jan', phone: '601 234 567'),
        throwsA(isA<ClientValidationException>()),
      );
    });

    test('keeps createdAt when updating', () async {
      final created = DateTime.utc(2025);
      when(() => repository.find('c1')).thenAnswer(
        (_) async => Client(id: 'c1', name: 'Old', createdAt: created, updatedAt: created),
      );

      final client = await service.saveClient(id: 'c1', name: 'New');

      expect(client.id, 'c1');
      expect(client.createdAt, created);
      expect(client.updatedAt, now);
    });
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
