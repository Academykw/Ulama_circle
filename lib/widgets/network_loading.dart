import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/icons/px.dart';
import '../core/theme/app_theme.dart';
import '../providers/connectivity_provider.dart';

/// A network-aware replacement for a bare loading spinner.
///
/// Firestore streams silently *wait* when there's no cached data and the network
/// is poor — a plain spinner then spins forever with no feedback. This widget:
///   • shows a normal spinner for the first few seconds,
///   • then explains the delay ("Poor connection — still trying…") with a Retry,
///   • shows an offline message when there's no connection,
///   • and auto-retries the moment the connection returns.
///
/// [onRetry] should re-trigger the load (typically `ref.invalidate(provider)`).
class NetworkLoading extends ConsumerStatefulWidget {
  const NetworkLoading({super.key, required this.onRetry, this.isError = false});

  final VoidCallback onRetry;

  /// When true, render the "failed to load" variant immediately (used from an
  /// AsyncValue.error branch) instead of waiting out the slow timer.
  final bool isError;

  @override
  ConsumerState<NetworkLoading> createState() => _NetworkLoadingState();
}

class _NetworkLoadingState extends ConsumerState<NetworkLoading> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isError) {
      _timer = Timer(const Duration(seconds: 6),
          () => mounted ? setState(() => _slow = true) : null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider);
    // Auto-retry as soon as the connection comes back.
    ref.listen<bool>(isOnlineProvider, (prev, next) {
      if (next && prev == false) widget.onRetry();
    });

    if (!online) {
      return _Message(
        icon: Px.bell,
        text: 'You’re offline. We’ll load this as soon as you reconnect.',
        onRetry: widget.onRetry,
      );
    }
    if (widget.isError) {
      return _Message(
        icon: Px.arrowClockwise,
        text: 'Couldn’t load — check your connection and try again.',
        onRetry: widget.onRetry,
      );
    }
    if (_slow) {
      return _Message(
        icon: Px.arrowClockwise,
        text: 'Poor connection — still trying…',
        onRetry: widget.onRetry,
        spinner: true,
      );
    }
    return const Center(
        child: CircularProgressIndicator(color: AppColors.gold));
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.onRetry,
    this.spinner = false,
  });

  final PxData icon;
  final String text;
  final VoidCallback onRetry;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinner)
              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2.5),
              )
            else
              PxIcon(icon, color: AppColors.mutedText, size: 34),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const PxIcon(Px.arrowClockwise, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
