import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_db_service.dart';

/// Overridden in main() with the already-initialized instance (its boxes must
/// be open before the app runs, which can't happen inside a plain provider).
/// Reading it without that override throws — a deliberate fail-fast.
final localDbServiceProvider = Provider<LocalDbService>((ref) {
  throw UnimplementedError(
    'localDbServiceProvider must be overridden in main() with an '
    'initialized LocalDbService.',
  );
});
