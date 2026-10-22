import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/formatters/address_formatter.dart';

final class const ClientListItemViewModel({
  required final String id,
  required final String name,

  /// Street, postal code and town on one line; null when none is known.
  required final String? addressLabel,

  /// The phone without `+`, for searching by number.
  final String phoneDigits = '',
}) with Equatable {
  factory fromDomain(Client client) => ClientListItemViewModel(
    id: client.id,
    name: client.name,
    addressLabel: formatAddress(
      addressLine: client.addressLine,
      postalCode: client.postalCode,
      town: client.town,
    ),
    phoneDigits: client.phone?.replaceAll(_nonDigits, '') ?? '',
  );

  static final _phoneQuery = RegExp(r'^[\d\s+\-]+$');
  static final _nonDigits = RegExp(r'\D');

  /// The list's search: name and address without case or Polish diacritics
  /// ("lodz" finds "Łódź"), or the phone when the query is a number, whatever
  /// its spacing.
  bool matches(String query) {
    final folded = foldPolish(query.trim());
    if (folded.isEmpty || foldPolish('$name ${addressLabel ?? ''}').contains(folded)) return true;
    final digits = query.replaceAll(_nonDigits, '');
    return _phoneQuery.hasMatch(query) && digits.isNotEmpty && phoneDigits.contains(digits);
  }

  @override
  List<Object?> get props => [id, name, addressLabel, phoneDigits];
}
