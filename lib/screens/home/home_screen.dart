import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Placeholder Home. Day 8+ replaces this with the real banner + sheikh
/// sections. For now it proves auth landed a user here and lets us sign out.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ulama Circle'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: userDoc.when(
          loading: () => const CircularProgressIndicator(color: AppColors.gold),
          error: (e, _) => Text('Error: $e'),
          data: (user) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.olive, size: 48),
              const SizedBox(height: 16),
              Text(
                user == null
                    ? 'Signed in'
                    : 'Welcome, ${user.displayName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                user?.isGuest ?? false ? 'Guest session' : 'Registered account',
                style: const TextStyle(color: AppColors.mutedText),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Admin',
                      style: TextStyle(color: AppColors.gold)),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Home screen — real content arrives Day 8.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
