import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import 'local_db_provider.dart';
import 'locale_provider.dart';

/// Maps an app UI language code to the matching CONTENT language, used to
/// pre-tick the first-launch picker (e.g. Hausa UI → suggest Hausa). Null when
/// there's no obvious match (English UI, or system default).
String? contentLanguageForLocale(String? localeCode) => switch (localeCode) {
      'ha' => 'hausa',
      'yo' => 'yoruba',
      _ => null,
    };

/// The content languages the user chose at first launch (and can edit later).
/// An **empty set means "all languages"**. Persisted in Hive.
final preferredLanguagesProvider =
    NotifierProvider<PreferredLanguagesNotifier, Set<String>>(
        PreferredLanguagesNotifier.new);

class PreferredLanguagesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.watch(localDbServiceProvider).preferredLanguages.toSet();

  /// Persists the chosen languages. Picking all of them is normalised to the
  /// empty set ("all"), so downstream filtering has a single meaning for it.
  Future<void> save(Set<String> langs) async {
    final normalized =
        langs.length >= AppConstants.supportedLanguages.length ? <String>{} : langs;
    state = normalized;
    await ref
        .read(localDbServiceProvider)
        .setPreferredLanguages(normalized.toList());
  }
}

/// The active content-language filter — a **set** of languages; an empty set
/// means "All". Defaults to the user's preferred languages, and the chips let
/// them toggle languages on/off from there (soft filter — nothing is hidden
/// permanently).
final languageFilterProvider =
    NotifierProvider<LanguageFilterNotifier, Set<String>>(
        LanguageFilterNotifier.new);

class LanguageFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(preferredLanguagesProvider);

  /// Toggle a single language. Ending up with all (or none) selected collapses
  /// to the empty set = "All".
  void toggle(String lang) {
    final next = {...state};
    if (!next.add(lang)) next.remove(lang);
    state = next.length >= AppConstants.supportedLanguages.length
        ? <String>{}
        : next;
  }

  /// Select "All languages" (clear the filter).
  void selectAll() => state = <String>{};
}

/// Whether a lecture's language passes the given filter set (empty = all).
bool languageMatches(Set<String> filter, String language) =>
    filter.isEmpty || filter.contains(language);
