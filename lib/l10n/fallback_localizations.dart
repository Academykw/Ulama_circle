import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter's `GlobalMaterialLocalizations` only ships a fixed set of locales,
/// and **Hausa (`ha`) is not one of them**. Without a fallback, switching the
/// app to `ha` throws "No MaterialLocalizations found" and crashes.
///
/// These delegates claim to support *every* locale and simply load the English
/// Material/Cupertino localizations — so our own UI strings render in Hausa
/// (from [L10n]) while Material's built-in widgets (dialogs, pickers, tooltips)
/// safely fall back to English behaviour. Add them AFTER the generated
/// `L10n.localizationsDelegates`.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
