import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/clients/clients_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Reactive: the drift stream pushes state, so a sync pull or a write from
/// another screen shows up without any explicit refresh. There is no
/// "loading from network" here and there never will be (CLAUDE.md, rule 1).
/// Not `final`: widget tests mock cubits with `MockCubit implements ClientsCubit`.
class ClientsCubit(
  final ClientsService _clientsService,
  final EquipmentService _equipmentService, {
  DateTime Function()? now,
}) extends Cubit<ClientsState>
    with SubscriptionManagerMixin<ClientsState>, BlocErrorEmitterMixin<ClientsState> {
  this : super(const ClientsState());

  final DateTime Function() _now = now ?? DateTime.now;
  List<Client>? _clients;
  List<Equipment>? _equipment;

  void init() {
    subscribe(#clients, _clientsService.watchClients(), (clients) {
      _clients = clients;
      _emitItems();
    }, onError: _onError);
    subscribe(#equipment, _equipmentService.watchAll(), (equipment) {
      _equipment = equipment;
      _emitItems();
    }, onError: _onError);
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> deleteClient(String id) async {
    try {
      await _clientsService.deleteClient(id);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  /// The "Cofnij" on the snackbar after a delete.
  Future<void> restoreClient(String id) async {
    try {
      await _clientsService.restoreClient(id);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  /// Waits for both streams, so a tag never pops in after its row.
  void _emitItems() {
    final clients = _clients;
    final equipment = _equipment;
    if (isClosed || clients == null || equipment == null) return;
    final today = calendarDay(_now());
    final byClient = <String, List<Equipment>>{};
    for (final item in equipment) {
      (byClient[item.clientId] ??= []).add(item);
    }
    emit(
      state.copyWith(
        items: [
          for (final client in clients)
            ClientListItemViewModel.fromDomain(
              client,
              equipment: byClient[client.id] ?? const [],
              today: today,
            ),
        ],
        isLoading: false,
      ),
    );
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    emit(state.copyWith(isLoading: false));
    emitError(LocalizedException.create(error));
  }
}
