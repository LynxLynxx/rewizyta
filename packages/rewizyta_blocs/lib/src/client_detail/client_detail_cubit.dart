import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/client_detail/client_detail_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The client card. Watches the rows, so an edit shows up when the form pops.
class ClientDetailCubit(
  final ClientsService _clientsService,
  final EquipmentService _equipmentService,
  final CatalogService _catalogService, {
  DateTime Function()? now,
}) extends Cubit<ClientDetailState>
    with
        SubscriptionManagerMixin<ClientDetailState>,
        BlocErrorEmitterMixin<ClientDetailState>,
        BlocSignalEmitterMixin<ClientDetailSignal, ClientDetailState> {
  this : super(const ClientDetailState());

  final DateTime Function() _now = now ?? DateTime.now;
  Client? _client;
  List<Equipment>? _equipment;
  List<ServiceType>? _serviceTypes;

  void init(String id) {
    subscribe(#client, _clientsService.watchClient(id), (client) {
      _client = client;
      _emitClient();
    }, onError: _onError);
    subscribe(#equipment, _equipmentService.watchByClient(id), (equipment) {
      _equipment = equipment;
      _emitClient();
    }, onError: _onError);
    subscribe(#serviceTypes, _catalogService.watchServiceTypes(), (types) {
      _serviceTypes = types;
      _emitClient();
    }, onError: _onError);
  }

  Future<void> deleteClient() async {
    final client = state.client;
    if (client == null) return;
    try {
      await _clientsService.deleteClient(client.id);
      if (isClosed) return;
      cancelSubscription(#client);
      cancelSubscription(#equipment);
      cancelSubscription(#serviceTypes);
      emitSignal(ClientDetailSignal.deleted);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  /// Waits for all three streams, so the card never opens half filled.
  void _emitClient() {
    final client = _client;
    final equipment = _equipment;
    final serviceTypes = _serviceTypes;
    if (isClosed || client == null || equipment == null || serviceTypes == null) return;
    emit(
      ClientDetailState(
        client: ClientDetailViewModel.fromDomain(
          client,
          equipment: equipment,
          serviceTypes: serviceTypes,
          today: calendarDay(_now()),
        ),
      ),
    );
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    emitError(LocalizedException.create(error));
  }
}
