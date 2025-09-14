// lib/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Returns true if any reported connectivity result is not `none`.
  Future<bool> hasNetwork() async {
    final results = await _connectivity.checkConnectivity();
    // `checkConnectivity()` now returns List<ConnectivityResult>
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Expose the raw connectivity change stream as a list (recommended).
  /// The emitted list is never empty; in case of no connectivity it contains [ConnectivityResult.none].
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
