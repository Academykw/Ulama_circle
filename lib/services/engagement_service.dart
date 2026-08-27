import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Records plays/listens so trending + the admin dashboard stay live. Counts are
/// bumped through Cloud Functions (clients can't write content docs directly),
/// so these are best-effort no-ops until the functions are deployed (Blaze).
class EngagementService {
  EngagementService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> recordLecturePlay(String lectureId) =>
      _call('incrementPlayCount', {'lectureId': lectureId});

  Future<void> recordRecitationListen(String recitationId) =>
      _call('incrementRecitationListen', {'recitationId': recitationId});

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call<dynamic>(data);
    } catch (e) {
      // Not deployed / offline / not signed in — engagement counting is
      // non-critical, so never surface this to playback.
      debugPrint('Engagement "$name" skipped: $e');
    }
  }
}
