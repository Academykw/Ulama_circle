import 'package:flutter/services.dart';

/// Bridges to the native side (MainActivity) to move the app to the background
/// without closing it — Android `moveTaskToBack(true)`. Lets "back" minimise
/// the app (keeping audio + the media notification alive) instead of exiting.
const _channel = MethodChannel('ulama/app');

Future<void> moveAppToBackground() async {
  try {
    await _channel.invokeMethod('moveToBack');
  } catch (_) {
    /* no-op on platforms without the channel */
  }
}
