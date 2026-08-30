import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db_provider.dart';

/// The app's UI language. `null` = follow the device locale; otherwise a forced
/// [Locale] (e.g. English or Hausa). Persisted in Hive (app_meta 'app_locale').
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(localDbServiceProvider).localeCode;
    return code.isEmpty ? null : Locale(code);
  }

  /// Pass `null` to follow the device.
  void set(Locale? locale) {
    state = locale;
    ref.read(localDbServiceProvider).setLocaleCode(locale?.languageCode ?? '');
  }
}
