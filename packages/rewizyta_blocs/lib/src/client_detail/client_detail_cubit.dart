import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/client_detail/client_detail_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The client card and its visit history. Watches the rows, so an edit
/// shows up when the form or the visit sheet closes.
class ClientDetailCubit(
  final ClientsService _clientsService,
  final EquipmentService _equipmentService,
  final CatalogService _catalogService,
  final VisitsService _visitsService, {
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
  List<Visit>? _visits;
  List<VisitItem>? _visitItems;

  void init(String id) {
    subscribe(#client, _clientsService.watchClient(id), (client) {
      _client = client;
      _emitClient();
    }, onError: _onError);
    // Deleted equipment too: the history still names it.
    subscribe(#equipment, _equipmentService.watchByClient(id, includeDeleted: true), (
      equipment,
    ) {
      _equipment = equipment;
      _emitClient();
    }, onError: _onError);
    subscribe(#serviceTypes, _catalogService.watchServiceTypes(), (types) {
      _serviceTypes = types;
      _emitClient();
    }, onError: _onError);
    subscribe(#visits, _visitsService.watchByClient(id), (visits) {
      _visits = visits;
      _emitClient();
    }, onError: _onError);
    subscribe(#visitItems, _visitsService.watchItemsByClient(id), (items) {
      _visitItems = items;
      _emitClient();
    }, onError: _onError);
  }

  /// The "Cofnij" after a visit is deleted on the visit sheet.
  Future<void> restoreVisit(String id) async {
    try {
      await _visitsService.restoreVisit(id);
    } on Exception catch (error) {
      if (isClosed) return;
      emitError(LocalizedException.create(error));
    }
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
      cancelSubscription(#visits);
      cancelSubscription(#visitItems);
      emitSignal(ClientDetailSignal.deleted);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  /// Waits for every stream, so the card never opens half filled.
  void _emitClient() {
    final client = _client;
    final equipment = _equipment;
    final serviceTypes = _serviceTypes;
    final visits = _visits;
    final visitItems = _visitItems;
    if (isClosed ||
        client == null ||
        equipment == null ||
        serviceTypes == null ||
        visits == null ||
        visitItems == null) {
      return;
    }
    emit(
      ClientDetailState(
        client: ClientDetailViewModel.fromDomain(
          client,
          equipment: equipment,
          serviceTypes: serviceTypes,
          visits: visits,
          visitItems: visitItems,
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
