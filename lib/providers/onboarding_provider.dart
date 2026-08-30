import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db_provider.dart';

/// Whether the user has finished (or skipped) onboarding. Seeded from the local
/// `onboardingSeen` flag so it survives restarts; flipped once via [complete].
final onboardingSeenProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(localDbServiceProvider).onboardingSeen;

  /// Called when the user taps "Get started" or "Skip". Persists the flag and
  /// flips state so the root router advances to the auth check.
  Future<void> complete() async {
    await ref.read(localDbServiceProvider).setOnboardingSeen(true);
    state = true;
  }
}

/// Whether the first-launch "choose your content languages" step is done. The
/// root router shows the picker once, right after onboarding, until this flips.
final languagesChosenProvider =
    NotifierProvider<LanguagesChosenNotifier, bool>(LanguagesChosenNotifier.new);

class LanguagesChosenNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(localDbServiceProvider).languagesChosen;

  Future<void> complete() async {
    await ref.read(localDbServiceProvider).setLanguagesChosen(true);
    state = true;
  }
}
