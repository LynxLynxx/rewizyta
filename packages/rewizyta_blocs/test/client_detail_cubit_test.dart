import 'dart:async';

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
  final jan = Client(id: 'c1', name: 'Jan', phone: '+48601234567', createdAt: now, updatedAt: now);

  late MockClientsService service;
  late StreamController<Client> client;

  setUp(() {
    service = MockClientsService();
    client = StreamController<Client>.broadcast();
    when(() => service.watchClient('c1')).thenAnswer((_) => client.stream);
  });

  tearDown(() => client.close());

  blocTest<ClientDetailCubit, ClientDetailState>(
    'init maps every change of the client to the view model',
    build: () => ClientDetailCubit(service),
    act: (cubit) {
      cubit.init('c1');
      client
        ..add(jan)
        ..add(jan.copyWith(name: 'Jan Kowalski'));
    },
    expect: () => [
      ClientDetailState(client: ClientDetailViewModel.fromDomain(jan)),
      ClientDetailState(
        client: ClientDetailViewModel.fromDomain(jan.copyWith(name: 'Jan Kowalski')),
      ),
    ],
  );

  test('an unknown id goes to the error channel', () async {
    final cubit = ClientDetailCubit(service)..init('c1');
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
    final cubit = ClientDetailCubit(service)..init('c1');
    final signals = <ClientDetailSignal>[];
    final sub = cubit.signalStream.listen(signals.add);
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
    final cubit = ClientDetailCubit(service);

    await cubit.deleteClient();

    verifyNever(() => service.deleteClient(any()));
    await cubit.close();
  });
}
