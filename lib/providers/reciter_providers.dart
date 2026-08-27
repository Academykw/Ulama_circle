import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reciter_model.dart';
import '../models/recitation_model.dart';
import 'firebase_service_provider.dart';

/// Live list of Quran reciters (small bounded set, ordered).
final recitersProvider = StreamProvider<List<ReciterModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchReciters();
});

/// A reciter's surahs, resolved by reciter id (ordered).
final recitationsByReciterProvider =
    FutureProvider.family<List<RecitationModel>, String>((ref, reciterId) {
  return ref.watch(firebaseServiceProvider).getRecitationsByReciter(reciterId);
});
