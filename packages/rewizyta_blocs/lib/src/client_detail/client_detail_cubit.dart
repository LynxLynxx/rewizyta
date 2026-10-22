import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/client_detail/client_detail_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The client card. Watches the row, so an edit shows up when the form pops.
class ClientDetailCubit(final ClientsService _clientsService)
    extends Cubit<ClientDetailState>
    with
        SubscriptionManagerMixin<ClientDetailState>,
        BlocErrorEmitterMixin<ClientDetailState>,
        BlocSignalEmitterMixin<ClientDetailSignal, ClientDetailState> {
  this : super(const ClientDetailState());

  void init(String id) {
    subscribe(#client, _clientsService.watchClient(id), _onClient, onError: _onError);
  }

  Future<void> deleteClient() async {
    final client = state.client;
    if (client == null) return;
    try {
      await _clientsService.deleteClient(client.id);
      if (isClosed) return;
      cancelSubscription(#client);
      emitSignal(ClientDetailSignal.deleted);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  void _onClient(Client client) {
    if (isClosed) return;
    emit(ClientDetailState(client: ClientDetailViewModel.fromDomain(client)));
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    emitError(LocalizedException.create(error));
  }
}
