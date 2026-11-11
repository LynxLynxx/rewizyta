import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_blocs/src/due/due_state.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The due list (Terminy): clients overdue or due within 60 days. Reactive
/// like the client list, so a visit saved anywhere moves the row.
class DueCubit(
  final ClientsService _clientsService,
  final EquipmentService _equipmentService,
  final CatalogService _catalogService, {
  DateTime Function()? now,
}) extends Cubit<DueState>
    with SubscriptionManagerMixin<DueState>, BlocErrorEmitterMixin<DueState> {
  this : super(const DueState());

  final DateTime Function() _now = now ?? DateTime.now;
  List<Client>? _clients;
  List<Equipment>? _equipment;
  List<ServiceType>? _serviceTypes;

  void init() {
    subscribe(#clients, _clientsService.watchClients(), (clients) {
      _clients = clients;
      _emitItems();
    }, onError: _onError);
    subscribe(#equipment, _equipmentService.watchAll(), (equipment) {
      _equipment = equipment;
      _emitItems();
    }, onError: _onError);
    subscribe(#serviceTypes, _catalogService.watchServiceTypes(), (types) {
      _serviceTypes = types;
      _emitItems();
    }, onError: _onError);
  }

  /// The "Cofnij" after a client is deleted on its card.
  Future<void> restoreClient(String id) async {
    try {
      await _clientsService.restoreClient(id);
    } on Exception catch (error) {
      emitError(LocalizedException.create(error));
    }
  }

  /// Waits for all three streams, so a row never shows half filled.
  void _emitItems() {
    final clients = _clients;
    final equipment = _equipment;
    final serviceTypes = _serviceTypes;
    if (isClosed || clients == null || equipment == null || serviceTypes == null) return;
    final today = calendarDay(_now());
    final byClient = <String, List<Equipment>>{};
    for (final item in equipment) {
      (byClient[item.clientId] ??= []).add(item);
    }
    final items = [
      for (final client in clients)
        ?DueListItemViewModel.fromDomain(
          client,
          equipment: byClient[client.id] ?? const [],
          serviceTypes: serviceTypes,
          today: today,
        ),
    ];
    // Most overdue first, soonest first; [DueStatusViewModel.count] is days
    // past the date in the first group and days to it in the second.
    final overdue = items.where((item) => item.status.kind == DueStatusKind.overdue).toList()
      ..sort((a, b) => _byName(b.status.count.compareTo(a.status.count), a, b));
    final upcoming = items.where((item) => item.status.kind != DueStatusKind.overdue).toList()
      ..sort((a, b) => _byName(a.status.count.compareTo(b.status.count), a, b));
    emit(DueState(overdue: overdue, upcoming: upcoming, isLoading: false));
  }

  /// Ties go by name, because `sort` is not stable.
  static int _byName(int byCount, DueListItemViewModel a, DueListItemViewModel b) =>
      byCount != 0 ? byCount : comparePolish(a.name, b.name);

  void _onError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    emit(DueState(overdue: state.overdue, upcoming: state.upcoming, isLoading: false));
    emitError(LocalizedException.create(error));
  }
}
