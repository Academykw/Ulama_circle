import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';

import 'local_db_service.dart';

/// Google Play in-app updates + in-app review.
///
/// Both only work on a build the user installed from the Play Store (internal
/// testing counts). On a sideloaded `flutter run` debug build the platform
/// calls throw — everything here is wrapped in try/catch and silently no-ops,
/// so it's safe to call unconditionally at startup.
class AppUpdatesService {
  AppUpdatesService._();

  static final InAppReview _review = InAppReview.instance;

  /// After a listener has played a few things, ask (once) for a store review.
  /// Number of plays before we're allowed to prompt.
  static const int _reviewPlayThreshold = 3;

  /// Checks Play for a newer version and, if one is available, downloads it in
  /// the background (flexible flow) then prompts the user to restart to apply.
  /// Best-effort: no-ops when not installed from Play.
  static Future<void> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.flexibleUpdateAllowed) {
        // Downloads in the background; the returned future completes once the
        // download is done, then we ask the user to restart to install.
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('in_app_update skipped: $e');
    }
  }

  /// Asks for a Play Store review if the user has listened enough and we
  /// haven't already asked. Google throttles the actual dialog, so this is a
  /// hint, not a guarantee it shows.
  static Future<void> maybeRequestReview(LocalDbService db) async {
    if (db.reviewAsked) return;
    if (db.playCountTotal < _reviewPlayThreshold) return;
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
        await db.setReviewAsked(true);
      }
    } catch (e) {
      debugPrint('in_app_review skipped: $e');
    }
  }
}
