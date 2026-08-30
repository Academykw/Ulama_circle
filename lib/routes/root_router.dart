import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../screens/onboarding/language_picker_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'auth_gate.dart';

/// Whether the one-time launch splash has already been shown this session. Held
/// in a provider (above the theme-keyed MaterialApp) so it SURVIVES the full
/// app rebuild that a theme switch triggers — otherwise the splash would replay
/// every time the user changes theme.
final splashShownProvider =
    NotifierProvider<SplashShownNotifier, bool>(SplashShownNotifier.new);

class SplashShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void markShown() => state = true;
}

/// The app's entry router. Sequences the full launch flow:
///
///   splash (min. hold) -> onboarding (first launch only) -> auth check -> home
///
/// A short minimum splash hold guarantees the branded splash is actually seen
/// even when auth resolves instantly from cache.
class RootRouter extends ConsumerStatefulWidget {
  const RootRouter({super.key});

  @override
  ConsumerState<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends ConsumerState<RootRouter> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Only run the splash hold the first time; a theme-switch rebuild recreates
    // this state but the provider flag is already set, so we skip it.
    if (!ref.read(splashShownProvider)) {
      _timer = Timer(
        const Duration(milliseconds: 2400),
        () => mounted ? ref.read(splashShownProvider.notifier).markShown() : null,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(splashShownProvider)) return const SplashScreen();

    final onboardingSeen = ref.watch(onboardingSeenProvider);
    if (!onboardingSeen) return const OnboardingScreen();
    // First launch: let the user pick their content language(s) once.
    final languagesChosen = ref.watch(languagesChosenProvider);
    if (!languagesChosen) return const LanguagePickerScreen();
    return const AuthGate();
  }
}
