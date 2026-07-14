/// Central place for every "magic string" the app uses — collection names,
/// box names, storage paths. Change something here once instead of hunting
/// through the codebase.
class AppConstants {
  AppConstants._();

  // ---- Firestore collection names ----
  static const String lecturesCollection = 'lectures';
  static const String sheikhsCollection = 'sheikhs';
  static const String categoriesCollection = 'categories';
  static const String recitersCollection = 'reciters';
  static const String recitationsCollection = 'recitations';
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
  static const String metaKeyNotifications = 'notifications_inbox';
  /// Prefix for per-topic push toggles, e.g. 'notif_pref_general_announcements'.
  static const String metaKeyNotifPrefPrefix = 'notif_pref_';

  // ---- Languages ----
  /// Lecture languages the app ships with (lowercase, as stored in Firestore).
  static const List<String> supportedLanguages = ['yoruba', 'hausa', 'english'];

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
  static const String topicNewLectures = 'new_lectures';
  static const String topicRamadan = 'ramadan_reminders';
  static String sheikhTopic(String sheikhId) => 'sheikh_$sheikhId';

  /// The push topics the user can toggle, with display labels + descriptions.
  static const List<({String topic, String label, String description})>
      notificationTopics = [
    (
      topic: topicGeneralAnnouncements,
      label: 'Announcements',
      description: 'Important news and updates from Ulama Circle',
    ),
    (
      topic: topicNewLectures,
      label: 'New lectures',
      description: 'When fresh lectures are added to the catalogue',
    ),
    (
      topic: topicRamadan,
      label: 'Ramadan reminders',
      description: 'Daily Qur’an and reflection prompts in Ramadan',
    ),
  ];

  // ---- Pagination ----
  static const int defaultPageSize = 20;
  static const int featuredLecturesLimit = 10;

  // ---- Local file storage ----
  /// Subfolder inside ApplicationDocumentsDirectory where downloaded audio lives.
  static const String localAudioFolder = 'lectures';
}
