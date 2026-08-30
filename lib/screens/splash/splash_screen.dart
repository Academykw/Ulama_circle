import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.22),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/images/ulama_splash_emblem.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),


            const SizedBox(height: 16),
            Text(
              'Ulama Circle',
              style: GoogleFonts.petrona(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Gold rule between the wordmark and tagline.
            Container(
              width: 46,
              height: 2,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Lectures & recitations for every seeker',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
