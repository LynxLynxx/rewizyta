import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

class MockClientsService() extends Mock implements ClientsService;

void main() {
  final now = DateTime.utc(2026);
  final jan = Client(
    id: 'c1',
    name: 'Jan',
    phone: '+48601234567',
    town: 'Nysa',
    createdAt: now,
    updatedAt: now,
  );

  late MockClientsService service;

  void stubSave(Future<Client> Function() answer) {
    when(
      () => service.saveClient(
        id: any(named: 'id'),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        addressLine: any(named: 'addressLine'),
        postalCode: any(named: 'postalCode'),
        town: any(named: 'town'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => answer());
  }

  setUp(() => service = MockClientsService());

  group('canSave', () {
    test('needs a name of two characters and a phone of nine digits', () {
      const valid = ClientFormState(name: 'Jo', phone: '601 234 567');
      expect(valid.canSave, isTrue);
      expect(valid.copyWith(name: ' J ').canSave, isFalse);
      expect(valid.copyWith(phone: '601 234 56').canSave, isFalse);
      expect(valid.copyWith(isSaving: true).canSave, isFalse);
    });
  });

  blocTest<ClientFormCubit, ClientFormState>(
    'init without an id leaves an empty new form',
    build: () => ClientFormCubit(service),
    act: (cubit) => cubit.init(null),
    expect: () => <ClientFormState>[],
  );

  blocTest<ClientFormCubit, ClientFormState>(
    'init with an id loads the client, the phone formatted',
    setUp: () => when(() => service.getClient('c1')).thenAnswer((_) async => jan),
    build: () => ClientFormCubit(service),
    act: (cubit) => cubit.init('c1'),
    expect: () => [
      const ClientFormState(isEditing: true, isLoading: true),
      const ClientFormState(isEditing: true, name: 'Jan', phone: '601 234 567', town: 'Nysa'),
    ],
  );

  blocTest<ClientFormCubit, ClientFormState>(
    'update clears the validation error',
    build: () => ClientFormCubit(service),
    seed: () => const ClientFormState(error: ClientValidationError.phoneInvalid),
    act: (cubit) => cubit.update(phone: '6'),
    expect: () => [const ClientFormState(phone: '6')],
  );

  blocTest<ClientFormCubit, ClientFormState>(
    'save creates the client and signals the new id',
    setUp: () => stubSave(() async => jan),
    build: () => ClientFormCubit(service),
    seed: () => const ClientFormState(name: 'Jan', phone: '601 234 567'),
    act: (cubit) async {
      await cubit.init(null);
      final signal = expectLater(
        cubit.signalStream,
        emits(const ClientFormSaved(id: 'c1', created: true)),
      );
      await cubit.save();
      await signal;
    },
    expect: () => [
      const ClientFormState(name: 'Jan', phone: '601 234 567', isSaving: true),
      const ClientFormState(name: 'Jan', phone: '601 234 567'),
    ],
    verify: (_) => verify(
      () => service.saveClient(
        name: 'Jan',
        phone: '601 234 567',
        addressLine: '',
        postalCode: '',
        town: '',
        note: '',
      ),
    ).called(1),
  );

  blocTest<ClientFormCubit, ClientFormState>(
    'save of an edit passes the id and signals an update',
    setUp: () {
      when(() => service.getClient('c1')).thenAnswer((_) async => jan);
      stubSave(() async => jan);
    },
    build: () => ClientFormCubit(service),
    act: (cubit) async {
      await cubit.init('c1');
      final signal = expectLater(
        cubit.signalStream,
        emits(const ClientFormSaved(id: 'c1', created: false)),
      );
      await cubit.save();
      await signal;
    },
    verify: (_) => verify(
      () => service.saveClient(
        id: 'c1',
        name: 'Jan',
        phone: '601 234 567',
        addressLine: '',
        postalCode: '',
        town: 'Nysa',
        note: '',
      ),
    ).called(1),
  );

  blocTest<ClientFormCubit, ClientFormState>(
    'a rejected phone becomes a field error',
    setUp: () => stubSave(
      () async => throw const ClientValidationException(ClientValidationError.phoneInvalid),
    ),
    build: () => ClientFormCubit(service),
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

  test('a failing load goes to the error channel', () async {
    when(() => service.getClient('x')).thenThrow(const ClientNotFoundException('x'));
    final cubit = ClientFormCubit(service);
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.init('x');
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    await sub.cancel();
    await cubit.close();
  });

  blocTest<ClientFormCubit, ClientFormState>(
    'save does nothing while the form cannot be saved',
    build: () => ClientFormCubit(service),
    act: (cubit) => cubit.save(),
    expect: () => <ClientFormState>[],
  );
}
