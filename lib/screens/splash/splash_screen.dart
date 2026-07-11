import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Day-1 placeholder — just proves the project boots, Firebase connects,
/// and Hive opens without crashing. Real splash art + routing logic
/// (onboarding -> auth check -> home) gets built on Day 7.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle_outlined, color: AppColors.gold, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Ulama Circle',
              style: TextStyle(
                color: AppColors.cream,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'lectures from Nigeria and beyond',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
