import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'admin_theme.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_shell.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ulama Circle Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      home: const _AdminGate(),
    );
  }
}

/// Routes: not signed in → login; signed in but not an admin → denied;
/// signed-in admin → the dashboard.
class _AdminGate extends ConsumerWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const _Loading(),
      error: (_, __) => const AdminLoginScreen(),
      data: (user) {
        if (user == null) return const AdminLoginScreen();
        final isAdmin = ref.watch(isAdminProvider);
        return isAdmin.when(
          loading: () => const _Loading(),
          error: (_, __) => const _Denied(),
          data: (admin) => admin ? const AdminShell() : const _Denied(),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AdminTheme.sidebar,
        body: Center(
            child: CircularProgressIndicator(color: AdminTheme.gold)),
      );
}

class _Denied extends ConsumerWidget {
  const _Denied();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AdminTheme.sidebar,
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              const Text('Not authorized',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.ink)),
              const SizedBox(height: 8),
              const Text(
                'This account isn’t an admin. Ask an existing admin to add an '
                'admins/{your-uid} document, then sign in again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AdminTheme.subtle, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => ref.read(authControllerProvider).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
