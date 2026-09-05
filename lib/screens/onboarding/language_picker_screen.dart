import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/filter_providers.dart';
import '../../providers/onboarding_provider.dart';

/// One-time "Choose your languages" step, shown right after onboarding on first
/// launch (before Home). The chosen set becomes the default content-language
/// filter across the app; it stays a *soft* default (nothing is hidden — the
/// language chips still let users browse anything), and it's editable later in
/// Profile.
class LanguagePickerScreen extends ConsumerStatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  // Nothing selected up front — the user actively chooses. "Continue" stays
  // disabled until they pick at least one language (or "All languages").
  final Set<String> _selected = {};
  bool _saving = false;

  static const _labels = {
    'english': 'English',
    'yoruba': 'Yoruba',
    'hausa': 'Hausa',
  };
  static const _subtitles = {
    'english': 'Lectures delivered in English',
    'yoruba': 'Àwọn ìwàásù ní èdè Yorùbá',
    'hausa': 'Darussa cikin harshen Hausa',
  };

  bool get _allSelected =>
      _selected.length == AppConstants.supportedLanguages.length;

  Future<void> _continue() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    // Notifier normalises "all selected" to the empty set (= all languages).
    await ref.read(preferredLanguagesProvider.notifier).save({..._selected});
    await ref.read(languagesChosenProvider.notifier).complete();
    // The root router now advances to the auth check automatically.
  }

  void _toggle(String lang) {
    setState(() {
      if (!_selected.add(lang)) _selected.remove(lang);
    });
  }

  void _selectAll() {
    setState(() {
      if (_allSelected) return;
      _selected
        ..clear()
        ..addAll(AppConstants.supportedLanguages);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text('Choose your languages',
                    style: AppTheme.display(size: 28, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  'Pick the language(s) you listen in. We’ll show those first — '
                  'you can still browse the others any time, and change this '
                  'later in Profile.',
                  style: TextStyle(
                      color: AppColors.mutedText, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                _AllTile(selected: _allSelected, onTap: _selectAll),
                const SizedBox(height: 12),
                for (final lang in AppConstants.supportedLanguages) ...[
                  _LangTile(
                    label: _labels[lang] ?? Formatters.titleCase(lang),
                    subtitle: _subtitles[lang] ?? '',
                    selected: _selected.contains(lang),
                    onTap: () => _toggle(lang),
                  ),
                  const SizedBox(height: 12),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _selected.isEmpty || _saving ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0D2620),
                    disabledBackgroundColor:
                        AppColors.gold.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Color(0xFF0D2620)))
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _AllTile extends StatelessWidget {
  const _AllTile({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          PxIcon(Px.translate,
              color: selected ? AppColors.gold : AppColors.mutedText, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text('All languages',
                style: TextStyle(
                    color: AppColors.cream,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          _Check(selected: selected),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          _Check(selected: selected),
        ],
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.08)
              : AppColors.cream.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.mutedText.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.gold : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.gold
              : AppColors.mutedText.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 15, color: Color(0xFF0D2620))
          : null,
    );
  }
}
