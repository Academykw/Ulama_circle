import 'package:flutter/material.dart';

import '../../admin_theme.dart';

/// Standard content-area layout for an admin section: a title/subtitle header
/// with an optional action on the right, then the full-width section body.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AdminTheme.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(subtitle!,
                          style: const TextStyle(
                              color: AdminTheme.subtle, fontSize: 14.5)),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AdminTheme.border),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}
