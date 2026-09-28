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
  final jan = Client(id: '1', name: 'Jan', phone: '+48601234567', createdAt: now, updatedAt: now);

  late MockClientsService service;
  late StreamController<List<Client>> clients;

  setUp(() {
    service = MockClientsService();
    // Broadcast: a single-subscription controller's close() never completes
    // without a listener, which would hang tearDown.
    clients = StreamController<List<Client>>.broadcast();
    when(service.watchClients).thenAnswer((_) => clients.stream);
  });

  tearDown(() => clients.close());

  test('initial state is loading with no items', () {
    final cubit = ClientsCubit(service);
    expect(cubit.state, const ClientsState());
    expect(cubit.state.isEmpty, isFalse);
    unawaited(cubit.close());
  });

  blocTest<ClientsCubit, ClientsState>(
    'init maps every stream event to view models',
    build: () => ClientsCubit(service),
    act: (cubit) {
      cubit.init();
      clients
        ..add([jan])
        ..add([]);
    },
    expect: () => [
      ClientsState(items: [ClientListItemViewModel.fromDomain(jan)], isLoading: false),
      const ClientsState(isLoading: false),
    ],
  );

  test('a failing delete goes to the error channel, not to state', () async {
    when(() => service.deleteClient('x')).thenThrow(const ClientNotFoundException('x'));
    final cubit = ClientsCubit(service);
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
    final cubit = ClientsCubit(service)..init();
    await cubit.close();
    expect(clients.hasListener, isFalse);
  });
}
