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
