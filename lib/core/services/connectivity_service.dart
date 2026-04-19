// lib/core/services/connectivity_service.dart
// ─────────────────────────────────────────────
// Thin wrapper around connectivity_plus.
// Use isOnline() as a quick pre-check before any network call.
// ─────────────────────────────────────────────
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Returns true if any usable network interface is available.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (r) => r != ConnectivityResult.none,
    );
  }
}
