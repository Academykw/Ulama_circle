import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A curated emoji avatar picker. Returns the chosen emoji, or '' if the user
/// tapped "Remove", or null if dismissed. Kept as a fixed grid so it needs no
/// third-party emoji package.
Future<String?> showEmojiPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _EmojiPickerSheet(),
  );
}

const _emojis = <String>[
  '😊', '🙂', '😌', '🤗', '😎', '🤩', '🥰', '😇',
  '🧕', '🧔', '👳', '🧑', '👨', '👩', '👦', '👧',
  '🤲', '🕌', '🌙', '⭐', '☪️', '📿', '📖', '📚',
  '✨', '💫', '🌟', '🌸', '🌿', '🌹', '🍃', '🌷',
  '❤️', '💚', '💛', '🧡', '☕', '🎧', '🎙️', '🔊',
  '🏆', '🎯', '💡', '🔥', '🤝', '🕋', '🤍', '💙',
];

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  @override
  Widget build(BuildContext context) {
    const emojis = _emojis;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mutedText.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text('Choose an avatar',
                    style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, ''),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, i) {
                final emoji = emojis[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context, emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
