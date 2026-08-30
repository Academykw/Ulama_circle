import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/local_db_provider.dart';
import 'providers/player_provider.dart';
import 'services/audio_player_handler.dart';
import 'services/local_db_service.dart';
import 'services/notification_service.dart';

/// Best-effort report to Crashlytics — swallows failures itself (e.g. an error
/// that lands here before Firebase.initializeApp has completed), since a crash
/// handler must never throw.
void _reportError(Object error, StackTrace stack) {
  try {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  } catch (_) {
    debugPrint('Unreported error (Crashlytics unavailable): $error');
  }
}

void main() {
  // Everything the app does runs inside this guarded zone. FlutterError.onError
  // (set below) only catches errors the framework raises during build/layout/
  // paint/gestures — it does NOT catch exceptions thrown in Timer callbacks,
  // Stream listeners without an onError, or un-awaited Futures. Those are
  // common on flaky networks (a stream stall watchdog, a position listener)
  // and, left uncaught, can silently kill the whole app process. This zone +
  // PlatformDispatcher.instance.onError below are the app-wide safety net so a
  // bad connection reports to Crashlytics instead of closing the app.
  runZonedGuarded(_run, _reportError);
}

Future<void> _run() async {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportError(error, stack);
    return true; // handled — do not let it propagate further.
  };

  // Go edge-to-edge and make the system bars TRANSPARENT so the app's own dark
  // background draws behind them. On Android 15 the OS ignores a solid
  // systemNavigationBarColor (enforced edge-to-edge) and shows a grey scrim —
  // transparent + contrast-off is the only way to get the themed look there.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Kick off the independent startup tasks CONCURRENTLY so the app draws its
  // first frame sooner (the native launch window shows until then). Hive/local
  // storage and the audio service don't depend on Firebase, so they run in
  // parallel with it instead of one-after-another.
  final localDbFuture = Hive.initFlutter().then((_) async {
    // All box/adapter setup lives in LocalDbService; open its boxes before
    // runApp so the initialized instance can be injected below.
    final db = LocalDbService();
    await db.init();
    return db;
  });

  // --- Background audio ---
  final audioFuture = AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ulama.circle.lectures.audio',
      androidNotificationChannelName: 'Ulama Circle',
      // Both false together (package requires androidNotificationOngoing to
      // imply androidStopForegroundOnPause:true, so this is the only valid
      // combination that avoids it): keep the app in the Android foreground-
      // service state through a pause AND through a network error/auto-retry,
      // at the cost of the notification becoming swipeable at any time. A
      // network drop mid-lecture makes the handler report playing:false the
      // same as a user pause (see AudioPlayerHandler's playbackEventStream
      // error listener) — with the old androidStopForegroundOnPause:true,
      // that instantly stripped foreground protection right when the app is
      // retrying in the background, and Crashlytics' device breakdown for the
      // crash reports is 100% aggressive-OEM Android skins (Tecno/Xiaomi/
      // Infinix) that are quick to kill unprotected background processes.
      // Foreground status is now only released on an explicit stop() (handler
      // .stop() below).
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      // A compliant white-on-transparent small icon — the default
      // (mipmap/ic_launcher, a colour icon) is rejected by strict OEM skins
      // (MIUI/HyperOS), which was hiding the media notification.
      androidNotificationIcon: 'drawable/ic_stat_ulama',
      // Tint the MediaStyle notification with the brand emerald surface.
      notificationColor: Color(0xFF132A22),
    ),
  );

  // --- Firebase --- (Crashlytics + the background message handler need it)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Non-fatal: FlutterError.onError also catches routine, self-recovering
  // framework errors — e.g. a scholar-photo NetworkImage failing DNS/TLS on a
  // bad connection — which never actually crash the app. Marking those
  // "fatal" was drowning the dashboard in noise and hiding real crashes.
  // Genuine unhandled crashes (uncaught async/Timer/Stream errors) are still
  // reported fatal via PlatformDispatcher.instance.onError above.
  FlutterError.onError = (details) =>
      FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // NOTE: push-notification init (which triggers the runtime permission dialog)
  // is intentionally NOT awaited here — it runs from MainShell once the UI is up.

  // Await the parallel tasks (already running while Firebase initialised).
  final localDb = await localDbFuture;
  final audioHandler = await audioFuture;

  runApp(
    ProviderScope(
      overrides: [
        localDbServiceProvider.overrideWithValue(localDb),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const UlamaCircleApp(),
    ),
  );
}
