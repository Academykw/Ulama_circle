import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user_model.dart';

/// Thin wrapper over FirebaseAuth + the `users/{uid}` Firestore doc.
///
/// Both guests (anonymous) and registered users land here; the only difference
/// is `isGuest` on their user doc. Guest accounts can later be *upgraded* to a
/// real account without losing their uid (favorites, history carry over).
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emits on sign-in / sign-out. The app's routing listens to this.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(AppConstants.usersCollection).doc(uid);

  // ---- Sign-in paths ----

  /// Guest login — Firebase Anonymous Auth. Lands on the same Home as everyone.
  Future<UserCredential> signInAsGuest() async {
    final cred = await _auth.signInAnonymously();
    await _ensureUserDoc(cred.user!, isGuest: true);
    return cred;
  }

  // Pinned to the pre-Credential-Manager (legacy) Google Sign-In flow: the
  // newer Credential Manager-based API (google_sign_in 7.x) hits a Google
  // Play Services bug on a lot of real Android devices — the account picker
  // opens, the user picks an account, and it fails with a native "Account
  // reauth failed" error before any token reaches Dart. The legacy
  // GoogleSignInClient flow doesn't go through Credential Manager and avoids
  // that bug entirely.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: AppConstants.googleServerClientId,
  );

  /// Google sign-in. Returns null if the user cancels the picker (so callers can
  /// treat cancellation as a no-op rather than an error).
  Future<UserCredential?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // user cancelled

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-no-id-token',
        message: 'Google sign-in did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: auth.accessToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await _ensureUserDoc(cred.user!, isGuest: false);
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Backfill the doc in case it predates this code / was created elsewhere.
    await _ensureUserDoc(cred.user!, isGuest: false);
    return cred;
  }

  Future<UserCredential> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(displayName.trim());
    }
    await _ensureUserDoc(cred.user!, isGuest: false, displayName: displayName);
    return cred;
  }

  Future<void> signOut() async {
    // Best-effort Google sign-out so the next Google login re-prompts the
    // account picker; ignore if Google was never used this session.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Permanently deletes the signed-in user's account and all their Firestore
  /// data. **Irreversible.** Firebase blocks account deletion when the last
  /// sign-in is stale, so we re-authenticate and retry once (Google users are
  /// re-prompted; email/password users are asked to sign in again).
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Firestore data first, while we still hold the uid + auth context:
    //    the playlists subcollection, then the user doc (favorites/history are
    //    fields on the doc, so they go with it).
    await _deleteUserData(user.uid);

    // 2. The auth account itself, re-authenticating if the session is stale.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauthenticate(user);
        await user.delete();
      } else {
        rethrow;
      }
    }

    // 3. Drop the Google session so the picker re-prompts next time.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> _deleteUserData(String uid) async {
    final ref = _userDoc(uid);
    // Subcollections don't cascade on the client — delete playlists explicitly.
    final playlists =
        await ref.collection(AppConstants.playlistsSubcollection).get();
    for (final d in playlists.docs) {
      await d.reference.delete();
    }
    await ref.delete();
  }

  Future<void> _reauthenticate(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (providers.contains('google.com')) {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Sign-in was cancelled. Please try again.',
        );
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-no-id-token',
          message: 'Google sign-in did not return an ID token.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      // Email/password (or unknown) — we don't hold the password here.
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Please sign out and sign in again, then delete your account.',
      );
    }
  }

  // ---- User doc + admin check ----

  /// Creates `users/{uid}` on first sign-in; leaves it untouched if it exists
  /// (so we never clobber favorites/history on a returning user).
  Future<void> _ensureUserDoc(
    User user, {
    required bool isGuest,
    String? displayName,
  }) async {
    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : (isGuest ? 'Guest' : (user.email ?? 'User'));

    await ref.set({
      ...AppUser(
        uid: user.uid,
        displayName: name,
        isGuest: isGuest,
      ).toFirestore(),
      // For the admin dashboard's "new users" metric (future signups only).
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<AppUser?> userDocStream(String uid) => _userDoc(uid)
      .snapshots()
      .map((snap) => snap.exists ? AppUser.fromFirestore(snap) : null);

  /// Records that the user opened the app now — powers the admin "daily active
  /// users" metric. Best-effort; merged so it never clobbers other fields.
  Future<void> touchLastActive(String uid) => _userDoc(uid).set(
        {'lastActiveAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

  /// Sets (or clears, with '') the user's emoji avatar.
  Future<void> setAvatarEmoji(String uid, String emoji) => _userDoc(uid).set(
        {'avatarEmoji': emoji},
        SetOptions(merge: true),
      );

  /// True if an `admins/{uid}` marker doc exists. Used to gate the admin panel;
  /// on the mobile app it just controls whether admin-only affordances show.
  Future<bool> isAdmin(String uid) async {
    final snap =
        await _db.collection(AppConstants.adminsCollection).doc(uid).get();
    return snap.exists;
  }
}
