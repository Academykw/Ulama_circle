import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ha.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ha')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingSalam.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum'**
  String get greetingSalam;

  /// No description provided for @greetingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get greetingWelcome;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lectures, scholars…'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @lecturers.
  ///
  /// In en, this message translates to:
  /// **'Lecturers'**
  String get lecturers;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @ramadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadan;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @freshContent.
  ///
  /// In en, this message translates to:
  /// **'Fresh Content'**
  String get freshContent;

  /// No description provided for @freshContentSub.
  ///
  /// In en, this message translates to:
  /// **'Latest from our scholars'**
  String get freshContentSub;

  /// No description provided for @quranRecitations.
  ///
  /// In en, this message translates to:
  /// **'Quran Recitations'**
  String get quranRecitations;

  /// No description provided for @quranRecitationsSub.
  ///
  /// In en, this message translates to:
  /// **'Beautiful recitations'**
  String get quranRecitationsSub;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @trendingNowSub.
  ///
  /// In en, this message translates to:
  /// **'Most popular this week'**
  String get trendingNowSub;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE LISTENING'**
  String get continueListening;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @tabScholars.
  ///
  /// In en, this message translates to:
  /// **'Scholars'**
  String get tabScholars;

  /// No description provided for @tabReciters.
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get tabReciters;

  /// No description provided for @tabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tabPlaylists;

  /// No description provided for @tabDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get tabDownloaded;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @searchScholars.
  ///
  /// In en, this message translates to:
  /// **'Search scholars'**
  String get searchScholars;

  /// No description provided for @scholarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scholars'**
  String scholarsCount(int count);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get sectionPreferences;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get sectionSupport;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage what you\'re notified about'**
  String get notificationsSub;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSupportSub.
  ///
  /// In en, this message translates to:
  /// **'FAQs and contact us'**
  String get helpSupportSub;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSub.
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get sendFeedbackSub;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get signInToSync;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get themeEmerald;

  /// No description provided for @themeObsidian.
  ///
  /// In en, this message translates to:
  /// **'Obsidian'**
  String get themeObsidian;

  /// No description provided for @pressBackToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackToExit;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nothingPlaying;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @quranReciters.
  ///
  /// In en, this message translates to:
  /// **'Quran Reciters'**
  String get quranReciters;

  /// No description provided for @recitersIntro.
  ///
  /// In en, this message translates to:
  /// **'Listen to beautiful recitations from talented Qur\'an reciters'**
  String get recitersIntro;

  /// No description provided for @quranTaraweeh.
  ///
  /// In en, this message translates to:
  /// **'Quran & Taraweeh'**
  String get quranTaraweeh;

  /// No description provided for @quranTaraweehSub.
  ///
  /// In en, this message translates to:
  /// **'Recite along this Ramadan'**
  String get quranTaraweehSub;

  /// No description provided for @tafsirReminders.
  ///
  /// In en, this message translates to:
  /// **'Tafsir & Reminders'**
  String get tafsirReminders;

  /// No description provided for @tafsirRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Reflect on the Qur\'an and the Seerah'**
  String get tafsirRemindersSub;

  /// No description provided for @ramadanReflections.
  ///
  /// In en, this message translates to:
  /// **'Ramadan Reflections'**
  String get ramadanReflections;

  /// No description provided for @ramadanReflectionsSub.
  ///
  /// In en, this message translates to:
  /// **'A curated collection for the blessed month'**
  String get ramadanReflectionsSub;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'New announcements and lectures will show up here'**
  String get notificationsEmptySub;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloads;

  /// No description provided for @noDownloadsSub.
  ///
  /// In en, this message translates to:
  /// **'Play or download a lecture to keep it offline'**
  String get noDownloadsSub;

  /// No description provided for @nothingSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get nothingSaved;

  /// No description provided for @nothingSavedSub.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a lecture to save it here'**
  String get nothingSavedSub;

  /// No description provided for @noRecitersYet.
  ///
  /// In en, this message translates to:
  /// **'No reciters yet'**
  String get noRecitersYet;

  /// No description provided for @noScholarsFound.
  ///
  /// In en, this message translates to:
  /// **'No scholars found'**
  String get noScholarsFound;

  /// No description provided for @searchQuranReciters.
  ///
  /// In en, this message translates to:
  /// **'Search in quran reciters'**
  String get searchQuranReciters;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ha'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'ha':
      return L10nHa();
  }

  throw FlutterError(
      'L10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
