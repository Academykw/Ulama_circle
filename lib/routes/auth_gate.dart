import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';

/// The app's top-level router. Watches auth state and shows:
///   - Splash while the first auth check resolves
///   - Login when signed out
///   - Home when signed in (guest or registered — same destination)
///
/// Day 7 expands this with onboarding; for now it's the auth branch only.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
