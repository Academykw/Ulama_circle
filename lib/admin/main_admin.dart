import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import 'admin_app.dart';

/// Web entry point for the admin dashboard. Run it with:
///   flutter run -d chrome -t lib/admin/main_admin.dart
/// Build it with:
///   flutter build web -t lib/admin/main_admin.dart
///
/// It shares the same Firebase project + models as the mobile app, but has no
/// audio/Hive setup — it's a pure Firestore/Storage admin console.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: AdminApp()));
}
