import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The currently selected language filter on Home. `null` means "All languages".
/// Value is the lowercase language string ('yoruba' | 'hausa' | 'english').
///
/// Kept in-memory only (resets to All on relaunch); it's a browsing filter, not
/// a saved preference. If we later want it to persist, back it with LocalDb.
///
/// Uses a Notifier (Riverpod 3 dropped StateProvider from the main export).
final languageFilterProvider =
    NotifierProvider<LanguageFilterNotifier, String?>(LanguageFilterNotifier.new);

class LanguageFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? language) => state = language;
}
