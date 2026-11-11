import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Single-class shape: both groups and the loading flag are shown at once.
final class const DueState({
  /// Most overdue first.
  final List<DueListItemViewModel> overdue = const [],

  /// Due today or within 60 days, soonest first.
  final List<DueListItemViewModel> upcoming = const [],
  final bool isLoading = true,
}) with Equatable {
  int get count => overdue.length + upcoming.length;

  bool get isEmpty => !isLoading && count == 0;

  @override
  List<Object?> get props => [overdue, upcoming, isLoading];

  @override
  String toString() =>
      'DueState(overdue: ${overdue.length}, upcoming: ${upcoming.length}, isLoading: $isLoading)';
}
