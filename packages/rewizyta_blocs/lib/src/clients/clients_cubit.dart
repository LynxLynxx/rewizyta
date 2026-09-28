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
class ClientsCubit(final ClientsService _clientsService)
    extends Cubit<ClientsState>
    with SubscriptionManagerMixin<ClientsState>, BlocErrorEmitterMixin<ClientsState> {
  this : super(const ClientsState());

  void init() {
    subscribe(#clients, _clientsService.watchClients(), _onClients, onError: _onError);
  }

  Future<void> deleteClient(String id) async {
    try {
      await _clientsService.deleteClient(id);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  void _onClients(List<Client> clients) {
    if (isClosed) return;
    emit(
      state.copyWith(
        items: clients.map(ClientListItemViewModel.fromDomain).toList(),
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
