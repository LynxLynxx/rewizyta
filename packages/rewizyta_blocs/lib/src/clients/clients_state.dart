import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Single-class shape: the list, the search query and a loading flag are
/// needed at once.
final class const ClientsState({
  final List<ClientListItemViewModel> items = const [],
  final String query = '',
  final bool isLoading = true,
}) with Equatable {
  /// No clients at all, as opposed to a search that matches nobody.
  bool get isEmpty => !isLoading && items.isEmpty;

  List<ClientListItemViewModel> get visibleItems =>
      query.trim().isEmpty ? items : items.where((item) => item.matches(query)).toList();

  ClientsState copyWith({List<ClientListItemViewModel>? items, String? query, bool? isLoading}) {
    return ClientsState(
      items: items ?? this.items,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, query, isLoading];

  @override
  String toString() => 'ClientsState(items: ${items.length}, query: $query, isLoading: $isLoading)';
}
