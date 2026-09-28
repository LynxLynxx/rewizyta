import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/formatters/phone_formatter.dart';

final class const ClientListItemViewModel({
  required final String id,
  required final String name,

  /// Formatted for display; null when the client has no phone.
  required final String? phoneLabel,
  required final String? town,
}) with Equatable {
  factory fromDomain(Client client) => ClientListItemViewModel(
    id: client.id,
    name: client.name,
    phoneLabel: client.phone == null ? null : formatPhone(client.phone!),
    town: client.town,
  );

  @override
  List<Object?> get props => [id, name, phoneLabel, town];
}
