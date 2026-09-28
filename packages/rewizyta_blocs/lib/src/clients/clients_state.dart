import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Single-class shape: the list and a loading flag are needed at once.
final class const ClientsState({
  final List<ClientListItemViewModel> items = const [],
  final bool isLoading = true,
}) with Equatable {
  bool get isEmpty => !isLoading && items.isEmpty;

  ClientsState copyWith({List<ClientListItemViewModel>? items, bool? isLoading}) {
    return ClientsState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
  }

  @override
  List<Object?> get props => [items, isLoading];

  @override
  String toString() => 'ClientsState(items: ${items.length}, isLoading: $isLoading)';
}
