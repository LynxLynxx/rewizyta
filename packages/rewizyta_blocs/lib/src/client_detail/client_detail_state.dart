import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Null [client] until the first row arrives from the database.
final class const ClientDetailState({final ClientDetailViewModel? client}) with Equatable {
  bool get isLoading => client == null;

  @override
  List<Object?> get props => [client];
}

enum ClientDetailSignal() {
  /// The client was soft-deleted; the page closes and offers an undo.
  deleted,
}
