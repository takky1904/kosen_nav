import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/sync/sync_service.dart';

class ConnectivityListener {
  ConnectivityListener({Connectivity? connectivity, SyncService? syncService})
    : _connectivity = connectivity ?? Connectivity(),
      _syncService = syncService ?? SyncService();

  final Connectivity _connectivity;
  final SyncService _syncService;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;
  bool _wasOffline = false;
  bool _isSyncing = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final current = await _connectivity.checkConnectivity();
    _wasOffline = !_hasNetwork(current);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final nowOnline = _hasNetwork(results);

      if (_wasOffline && nowOnline) {
        unawaited(_runSync());
      }

      _wasOffline = !nowOnline;
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _runSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncService.pushLocalChanges();
      await _syncService.fetchRemoteChanges();
    } finally {
      _isSyncing = false;
    }
  }
}

final ConnectivityListener appConnectivityListener = ConnectivityListener();
