/// Operation recorded in the outbox. A delete is an upsert with `deleted_at`
/// set; the distinction only matters for logging.
enum OutboxOp() {
  upsert,
  delete,
}

/// Entity names as they appear in the outbox and in the `sync_push` payload.
abstract final class SyncEntity() {
  static const clients = 'clients';
}
