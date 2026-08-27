import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import 'local_db_provider.dart';

/// Single shared AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// The current Firebase auth state. `null` data == signed out.
/// Routing (the AuthGate) watches this to decide splash vs login vs home.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Convenience: the current uid, or null when signed out.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid;
});

/// The signed-in user's Firestore doc (displayName, isGuest, favorites…).
/// Emits null when signed out or before the doc is created.
final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(authServiceProvider).userDocStream(uid);
});

/// Whether the current user has Premium (unlocks offline downloads).
final isPremiumProvider = Provider<bool>((ref) =>
    ref.watch(currentUserDocProvider).asData?.value?.isPremium ?? false);

/// Whether the current user is an admin (has an `admins/{uid}` marker doc).
final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return false;
  return ref.watch(authServiceProvider).isAdmin(uid);
});

/// One-shot "user is active now" ping — writes lastActiveAt for the current
/// user. Watched by the AuthGate so it fires each app open (per uid), feeding
/// the admin dashboard's daily-active-users metric.
final activityPingProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  await ref.read(authServiceProvider).touchLastActive(uid);
});

/// Actions the UI calls. Kept as a small controller so screens don't touch
/// AuthService directly and error handling lives in one place.
final authControllerProvider = Provider<AuthController>(
    (ref) => AuthController(ref.watch(authServiceProvider), ref));

class AuthController {
  AuthController(this._service, this._ref);
  final AuthService _service;
  final Ref _ref;

  Future<void> signInAsGuest() => _service.signInAsGuest();

  Future<void> signInWithEmail(String email, String password) =>
      _service.signInWithEmail(email, password);

  /// Returns true if a session started, false if the user canceled the picker.
  Future<bool> signInWithGoogle() async {
    final cred = await _service.signInWithGoogle();
    return cred != null;
  }

  Future<void> register(String email, String password, {String? displayName}) =>
      _service.registerWithEmail(email, password, displayName: displayName);

  Future<void> signOut() => _service.signOut();

  /// Permanently deletes the account (Firebase Auth + Firestore data) and wipes
  /// on-device data so nothing from the deleted account lingers for the next
  /// user. Throws on failure (e.g. cancelled re-auth) so the UI can report it.
  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    try {
      final db = _ref.read(localDbServiceProvider);
      await db.clearHistory();
      await db.clearNotifications();
      await db.clearAllDownloadRecords();
    } catch (_) {/* best-effort local cleanup */}
  }

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  /// Sets the current user's emoji avatar (no-op when signed out).
  Future<void> setAvatarEmoji(String uid, String emoji) =>
      _service.setAvatarEmoji(uid, emoji);
}
