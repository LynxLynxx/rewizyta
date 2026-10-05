/// Keys of the local `sync_state` table, stored in snake_case.
enum SyncStateKey() {
  /// Server time returned by the last successful pull.
  lastPulledAt,
  lastPushAt,

  /// This phone's id, minted on first run; also the `devices` row id.
  deviceId,
}

/// The sync's own bookkeeping. Local only: nothing here reaches the outbox.
abstract interface class SyncStateRepository() {
  Future<String?> read(SyncStateKey key);

  /// Stores [value], or removes the key when it is null.
  Future<void> write(SyncStateKey key, String? value);
}
