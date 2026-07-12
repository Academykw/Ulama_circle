import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/local_db_provider.dart';
import 'services/local_db_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Firebase ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route uncaught Flutter errors to Crashlytics — set up once, forget about it.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // --- Hive local storage ---
  // All box/adapter setup lives in LocalDbService now; init it before runApp so
  // its boxes are open and the initialized instance can be injected below.
  await Hive.initFlutter();
  final localDb = LocalDbService();
  await localDb.init();

  runApp(
    ProviderScope(
      overrides: [
        localDbServiceProvider.overrideWithValue(localDb),
      ],
      child: const UlamaCircleApp(),
    ),
  );
}
