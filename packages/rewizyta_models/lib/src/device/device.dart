import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

enum DevicePlatform() {
  android,
  ios,
}

/// Which push transport a token belongs to; tells the server which adapter to
/// send through.
enum PushProvider() {
  fcm,
  unifiedpush,
}

/// This phone's push registration. [id] is minted on the phone on first run;
/// only edge functions read the token, the app never addresses another device.
final class const Device({
  required final String id,
  required final DevicePlatform platform,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? pushToken,
  final PushProvider? pushProvider,
  final String? appVersion,
  final DateTime? lastSeenAt,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Device copyWith({
    Optional<String>? pushToken,
    Optional<PushProvider>? pushProvider,
    Optional<String>? appVersion,
    Optional<DateTime>? lastSeenAt,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Device(
      id: id,
      platform: platform,
      pushToken: pushToken.dataOr(this.pushToken),
      pushProvider: pushProvider.dataOr(this.pushProvider),
      appVersion: appVersion.dataOr(this.appVersion),
      lastSeenAt: lastSeenAt.dataOr(this.lastSeenAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    platform,
    pushToken,
    pushProvider,
    appVersion,
    lastSeenAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
