import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The catalogue editor: the trades, each with its service types.
final class const CatalogState({
  final bool isLoading = true,
  final List<CatalogTradeViewModel> trades = const [],
}) with Equatable {
  bool get isEmpty => !isLoading && trades.isEmpty;

  @override
  List<Object?> get props => [isLoading, trades];
}

enum CatalogSignal() {
  /// The missing defaults were copied back; the page says so.
  defaultsRestored,
}
