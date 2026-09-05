import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../admin_theme.dart';

/// Admin sign-in. Any valid account can sign in here; the [AdminGate] then
/// checks the admins/{uid} marker and blocks non-admins.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e, st) {
      debugPrint('Admin auth failed: $e\n$st');
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('invalid-credential') ||
        s.contains('wrong-password') ||
        s.contains('user-not-found')) {
      return 'Wrong email or password.';
    }
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      backgroundColor: AdminTheme.sidebar,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AdminTheme.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_moon,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ulama Circle',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AdminTheme.ink)),
                        Text('Admin dashboard',
                            style: TextStyle(
                                fontSize: 13, color: AdminTheme.subtle)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _busy
                      ? null
                      : _run(() =>
                          auth.signInWithEmail(_email.text, _password.text)),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() =>
                          auth.signInWithEmail(_email.text, _password.text)),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AdminTheme.sidebar),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _run(() => auth.signInWithGoogle()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AdminTheme.border),
                  ),
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Continue with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
