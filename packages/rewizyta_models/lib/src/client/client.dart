import 'package:equatable/equatable.dart';

/// A person or company the technician services.
///
/// Phone numbers are E.164 (`+48…`); addresses are free text because rural
/// Polish addresses rarely fit a street/number grid.
final class const Client({
  required final String id,
  required final String name,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? phone,
  final String? address,
  final String? town,
  final String? note,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Client copyWith({
    String? name,
    String? phone,
    String? address,
    String? town,
    String? note,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      town: town ?? this.town,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    address,
    town,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
