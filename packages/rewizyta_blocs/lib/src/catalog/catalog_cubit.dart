import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/catalog/catalog_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Usługi i cykle: the user's trades and service types. Reactive, so a type
/// saved on its sheet shows up when the sheet closes. Does not seed the
/// catalogue; an empty one offers "Przywróć domyślne" instead.
class CatalogCubit(final CatalogService _catalogService)
    extends Cubit<CatalogState>
    with
        SubscriptionManagerMixin<CatalogState>,
        BlocErrorEmitterMixin<CatalogState>,
        BlocSignalEmitterMixin<CatalogSignal, CatalogState> {
  this : super(const CatalogState());

  List<Trade>? _trades;
  List<ServiceType>? _serviceTypes;

  void init() {
    subscribe(#trades, _catalogService.watchTrades(), (trades) {
      _trades = trades;
      _emitTrades();
    }, onError: _onError);
    subscribe(#serviceTypes, _catalogService.watchServiceTypes(), (types) {
      _serviceTypes = types;
      _emitTrades();
    }, onError: _onError);
  }

  Future<void> addTrade(String name) async {
    try {
      await _catalogService.addTrade(name);
    } on Exception catch (error) {
      if (isClosed) return;
      emitError(LocalizedException.create(error));
    }
  }

  /// Copies the missing defaults back; the user's own changes stay.
  Future<void> restoreDefaults() async {
    try {
      await _catalogService.copyDefaults(TradeTemplate.values);
      if (isClosed) return;
      emitSignal(CatalogSignal.defaultsRestored);
    } on Exception catch (error) {
      if (isClosed) return;
      emitError(LocalizedException.create(error));
    }
  }

  /// Waits for both streams, so a trade never shows without its types.
  void _emitTrades() {
    final trades = _trades;
    final serviceTypes = _serviceTypes;
    if (isClosed || trades == null || serviceTypes == null) return;
    emit(
      CatalogState(
        isLoading: false,
        trades: [
          for (final trade in trades) CatalogTradeViewModel.fromDomain(trade, serviceTypes),
        ],
      ),
    );
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    emit(CatalogState(isLoading: false, trades: state.trades));
    emitError(LocalizedException.create(error));
  }
}
