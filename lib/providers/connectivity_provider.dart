import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams whether the device currently has *any* network connection.
/// (This reflects link state, not actual reachability, which is enough to gate
/// streaming and show an offline banner.)
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final conn = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  yield online(await conn.checkConnectivity());
  yield* conn.onConnectivityChanged.map(online);
});

/// Synchronous best-effort read of the latest connectivity. Defaults to online
/// so we never wrongly block playback before the first reading arrives.
final isOnlineProvider = Provider<bool>(
    (ref) => ref.watch(connectivityProvider).value ?? true);
