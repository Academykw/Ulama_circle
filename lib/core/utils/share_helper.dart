import 'package:share_plus/share_plus.dart';

import '../../models/lecture_model.dart';

/// Growth loop: let people share lectures, scholars, and the app itself —
/// each share carries the Play Store link so it spreads in WhatsApp/Telegram.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.ulama.circle.lectures';

Future<void> shareApp() {
  return SharePlus.instance.share(ShareParams(
    subject: 'Ulama Circle',
    text: 'Ulama Circle — authentic Islamic lectures & Qur\'an recitation from '
        'trusted scholars, in Hausa, Yoruba & English. 🎧📿\n\n'
        'Download free on Google Play:\n$kPlayStoreUrl',
  ));
}

Future<void> shareLecture(LectureModel lecture) {
  final by = lecture.sheikhName.isNotEmpty ? ' by ${lecture.sheikhName}' : '';
  // Deep link: opens the app straight to this lecture (or the landing page →
  // Play if the app isn't installed).
  final link = 'https://iscollection.web.app/lecture/${lecture.id}';
  return SharePlus.instance.share(ShareParams(
    subject: lecture.title,
    text: 'Listen to "${lecture.title}"$by on Ulama Circle 🎧\n\n$link',
  ));
}

Future<void> shareScholar(String name) {
  return SharePlus.instance.share(ShareParams(
    subject: name,
    text: 'Listen to $name and other trusted scholars on Ulama Circle — '
        'Islamic lectures in Hausa, Yoruba & English. 🤍\n\n'
        'Download free on Google Play:\n$kPlayStoreUrl',
  ));
}
