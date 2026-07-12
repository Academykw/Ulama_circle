import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user_model.dart';
import '../services/auth_service.dart';

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

/// Whether the current user is an admin (has an `admins/{uid}` marker doc).
final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return false;
  return ref.watch(authServiceProvider).isAdmin(uid);
});

/// Actions the UI calls. Kept as a small controller so screens don't touch
/// AuthService directly and error handling lives in one place.
final authControllerProvider =
    Provider<AuthController>((ref) => AuthController(ref.watch(authServiceProvider)));

class AuthController {
  AuthController(this._service);
  final AuthService _service;

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

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);
}
