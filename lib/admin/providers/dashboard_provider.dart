import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/lecture_model.dart';
import '../../models/recitation_model.dart';
import '../models/daily_stat.dart';
import 'admin_providers.dart';

/// Everything the dashboard shows, fetched in one batch.
class DashboardData {
  const DashboardData({
    required this.totalUsers,
    required this.dailyActiveUsers,
    required this.newUsersThisWeek,
    required this.scholars,
    required this.lectures,
    required this.reciters,
    required this.recitations,
    required this.categories,
    required this.totalPlays,
    required this.totalListens,
    required this.featured,
    required this.languageCounts,
    required this.topLectures,
    required this.topRecitations,
    required this.dailyStats,
    required this.newUsersByDay,
    required this.topLecturesThisWeek,
  });

  final int totalUsers;
  final int dailyActiveUsers;
  final int newUsersThisWeek;
  final int scholars;
  final int lectures;
  final int reciters;
  final int recitations;
  final int categories;
  final int totalPlays;
  final int totalListens;
  final int featured;
  final Map<String, int> languageCounts;
  final List<LectureModel> topLectures;
  final List<RecitationModel> topRecitations;
  final List<DailyStat> dailyStats;

  /// New sign-ups per day (last 14 days), oldest first — the growth chart.
  final List<({String date, int count})> newUsersByDay;

  /// Most-played lectures over the last 7 days — "what people listen to now".
  final List<({String title, String sheikhName, int plays})> topLecturesThisWeek;
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final s = ref.watch(adminServiceProvider);

  // Fire everything at once.
  final totalUsers = s.countCollection(AppConstants.usersCollection);
  final dau = s.countActiveUsers(const Duration(hours: 24));
  final newUsers = s.countNewUsers(const Duration(days: 7));
  final daily = s.dailyStats(days: 7);
  final scholars = s.countCollection(AppConstants.sheikhsCollection);
  final lectures = s.countCollection(AppConstants.lecturesCollection);
  final reciters = s.countCollection(AppConstants.recitersCollection);
  final recitations = s.countCollection(AppConstants.recitationsCollection);
  final categories = s.countCollection(AppConstants.categoriesCollection);
  final plays = s.sumField(AppConstants.lecturesCollection, 'playCount');
  final listens = s.sumField(AppConstants.recitationsCollection, 'listenCount');
  final featured =
      s.countWhere(AppConstants.lecturesCollection, 'isFeatured', true);
  final topLectures = s.topLectures();
  final topRecitations = s.topRecitations();
  final newByDay = s.newUsersByDay(days: 14);
  final topWeek = s.topLecturesInWindow(days: 7, limit: 8);
  final langEntries = await Future.wait([
    for (final l in AppConstants.supportedLanguages)
      s.countWhere(AppConstants.lecturesCollection, 'language', l),
  ]);

  return DashboardData(
    totalUsers: await totalUsers,
    dailyActiveUsers: await dau,
    newUsersThisWeek: await newUsers,
    scholars: await scholars,
    lectures: await lectures,
    reciters: await reciters,
    recitations: await recitations,
    categories: await categories,
    totalPlays: await plays,
    totalListens: await listens,
    featured: await featured,
    languageCounts: {
      for (var i = 0; i < AppConstants.supportedLanguages.length; i++)
        AppConstants.supportedLanguages[i]: langEntries[i],
    },
    topLectures: await topLectures,
    topRecitations: await topRecitations,
    dailyStats: await daily,
    newUsersByDay: await newByDay,
    topLecturesThisWeek: await topWeek,
  );
});
