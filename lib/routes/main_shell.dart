import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/icons/px.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_background.dart';
import '../core/utils/play_lecture.dart';
import '../l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';
import '../providers/content_providers.dart';
import '../providers/firebase_service_provider.dart';
import '../providers/local_db_provider.dart';
import '../providers/notification_providers.dart';
import '../providers/player_provider.dart';
import '../services/app_updates_service.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/mini_player.dart';

/// The main app shell after auth: Home / Library / Profile behind a bottom
/// navigation bar, with the persistent mini-player sitting just above the bar
/// so playback controls follow the user across every tab.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  DateTime? _lastBackPress;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;

  // Kept alive via IndexedStack so each tab preserves its scroll position.
  static const _tabs = [HomeScreen(), LibraryScreen(), ProfileScreen()];

  /// Back handling (hybrid):
  ///   • From Library/Profile → return to Home.
  ///   • On Home WITH a track loaded → minimise the app (audio keeps playing);
  ///     the user closes it from Recents, or stops audio from the notification.
  ///   • On Home with nothing playing → double-press to exit.
  void _onBack() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    // Something is loaded → minimise instead of closing, so playback survives.
    if (ref.read(currentLectureProvider) != null) {
      moveAppToBackground();
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(L10n.of(context).pressBackToExit),
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    // Deferred to here (not main()) so the OS notification-permission prompt
    // appears over the app, not over the splash. Then, on affected OEMs, a
    // one-time background-playback tip.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startupTasks());
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  /// Handles shared lecture links (https://iscollection.web.app/lecture/{id} or
  /// ulamacircle://lecture/{id}) — opens the app straight to that lecture.
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {/* best-effort */}
    _linkSub = _appLinks!.uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  Future<void> _handleUri(Uri uri) async {
    final segs = uri.pathSegments;
    // Path form: /lecture/{id}  (host or custom scheme both land here).
    if (segs.length >= 2 && segs.first == 'lecture') {
      final id = segs[1];
      try {
        final lecture = await ref.read(firebaseServiceProvider).getLecture(id);
        if (lecture != null && mounted) {
          setState(() => _index = 0); // ensure we're on a tab with a Navigator
          openLecture(context, ref, lecture);
        }
      } catch (_) {/* ignore bad links */}
    }
  }

  Future<void> _startupTasks() async {
    // Request the Android 13+ POST_NOTIFICATIONS runtime permission directly —
    // this reliably shows the OS dialog, and without it the media/playback
    // notification is hidden even though audio plays.
    try {
      await Permission.notification.request();
    } catch (_) {/* best-effort */}
    try {
      await ref.read(notificationServiceProvider).init();
    } catch (_) {/* best-effort */}
    if (!mounted) return;

    // Play Store housekeeping (both no-op off Play / on debug builds):
    // pull any available update, and — if the user has listened enough —
    // ask once for a review at this calm moment.
    await AppUpdatesService.checkForUpdate();
    await AppUpdatesService.maybeRequestReview(ref.read(localDbServiceProvider));
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider);
    // Warm the small, bounded catalogues once the shell is up so the first tap
    // into Scholars / category browsing opens instantly. These are tiny
    // (dozens of docs) and Firestore serves them from its offline cache on
    // later launches, so the read cost is negligible. Big paginated lists
    // (all lectures/recitations) are intentionally NOT prefetched.
    ref.watch(sheikhsProvider);
    ref.watch(categoriesProvider);
    // Surface playback network errors anywhere in the app as a brief toast.
    ref.listen(playerErrorProvider, (prev, next) {
      if (!next.hasValue || next.value == null) return;
      final msg = ref.read(isOnlineProvider)
          ? 'Network problem — playback will resume automatically.'
          : 'You’re offline — playback resumes when you’re back online.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
        ));
    });
    // Transient buffering/stall notices (self-healing — no retry state).
    ref.listen(playbackNoticeProvider, (prev, next) {
      final msg = next.asData?.value;
      if (msg == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
        ));
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            if (!online) const _OfflineBanner(),
            Expanded(child: IndexedStack(index: _index, children: _tabs)),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            _NavBar(
              index: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim bar shown at the top of the shell whenever the device is offline.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3A2A12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PxIcon(Px.bell, color: AppColors.gold, size: 15),
              const SizedBox(width: 8),
              Text(
                L10n.of(context).noInternet,
                style: TextStyle(
                    color: AppColors.cream,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge: paint navBg across the full width (incl. behind the system
    // gesture/button bar), and SafeArea(top:false) lifts the destinations above
    // that inset — so the system nav area shows the app's emerald, not grey.
    return Container(
      color: AppColors.navBg,
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.mutedText,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.mutedText,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        height: 64,
        destinations: [
          NavigationDestination(
            icon: const PxIcon(Px.house),
            selectedIcon: const PxIcon(Px.houseFill),
            label: L10n.of(context).navHome,
          ),
          NavigationDestination(
            icon: const PxIcon(Px.books),
            selectedIcon: const PxIcon(Px.booksFill),
            label: L10n.of(context).navLibrary,
          ),
          NavigationDestination(
            icon: const PxIcon(Px.userCircle),
            selectedIcon: const PxIcon(Px.userCircleFill),
            label: L10n.of(context).navProfile,
          ),
        ],
      ),
        ),
      ),
    );
  }
}
