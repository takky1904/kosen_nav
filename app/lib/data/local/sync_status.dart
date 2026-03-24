class SyncStatus {
  SyncStatus._();

  static const String synced = 'synced';
  static const String pendingInsert = 'pending_insert';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';

  static const List<String> values = <String>[
    synced,
    pendingInsert,
    pendingUpdate,
    pendingDelete,
  ];
}
