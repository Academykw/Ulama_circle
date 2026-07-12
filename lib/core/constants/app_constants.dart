/// Central place for every "magic string" the app uses — collection names,
/// box names, storage paths. Change something here once instead of hunting
/// through the codebase.
class AppConstants {
  AppConstants._();

  // ---- Firestore collection names ----
  static const String lecturesCollection = 'lectures';
  static const String sheikhsCollection = 'sheikhs';
  static const String categoriesCollection = 'categories';
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String commentsSubcollection = 'comments';
  static const String playlistsSubcollection = 'playlists';

  // ---- Firebase Storage ----
  /// Files live at: lectures/{sheikhId}/{lectureId}.mp3
  static const String lecturesStoragePath = 'lectures';

  // ---- Hive box names ----
  static const String downloadedLecturesBox = 'downloaded_lectures';
  static const String appMetaBox = 'app_meta';

  // ---- Hive keys inside app_meta box ----
  static const String metaKeyIsGuest = 'is_guest';
  static const String metaKeyOnboardingSeen = 'onboarding_seen';
  static const String metaKeyThemeMode = 'theme_mode';

  // ---- Google sign-in ----
  /// The project's *Web* OAuth client ID (client_type 3 in google-services.json).
  /// google_sign_in v7 needs this as `serverClientId` so the returned ID token's
  /// audience matches what Firebase Auth expects. This is public info (not a
  /// secret), so it's safe to keep in source. If you swap Firebase projects,
  /// update this to the new project's Web client ID.
  static const String googleServerClientId =
      '428568192222-0u1qaivctrh36qkfk54oqggdv6i5hc9n.apps.googleusercontent.com';

  // ---- FCM topics ----
  static const String topicGeneralAnnouncements = 'general_announcements';
  static String sheikhTopic(String sheikhId) => 'sheikh_$sheikhId';

  // ---- Pagination ----
  static const int defaultPageSize = 20;
  static const int featuredLecturesLimit = 10;

  // ---- Local file storage ----
  /// Subfolder inside ApplicationDocumentsDirectory where downloaded audio lives.
  static const String localAudioFolder = 'lectures';
}
