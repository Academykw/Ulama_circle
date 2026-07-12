import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import 'auth_gate.dart';

/// The app's entry router. Sequences the full launch flow:
///
///   onboarding (first launch only) -> auth check -> home
///
/// Onboarding is a synchronous local flag, so there's no loading state here;
/// the auth loading/splash is handled inside [AuthGate].
class RootRouter extends ConsumerWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingSeen = ref.watch(onboardingSeenProvider);
    if (!onboardingSeen) return const OnboardingScreen();
    return const AuthGate();
  }
}
