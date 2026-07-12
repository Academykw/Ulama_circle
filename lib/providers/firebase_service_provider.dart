import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_service.dart';

/// Shared read-only Firestore content service. Day 6 layers feature-specific
/// providers (sheikhs stream, featured lectures, paginated lists) on top of it.
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());
