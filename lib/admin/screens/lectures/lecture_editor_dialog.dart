import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/lecture_model.dart';
import '../../../providers/content_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../../services/web_file_picker.dart';

/// Create/edit form for a lecture, including audio upload to Storage.
class LectureEditorDialog extends ConsumerStatefulWidget {
  const LectureEditorDialog({super.key, this.existing});
  final LectureModel? existing;

  @override
  ConsumerState<LectureEditorDialog> createState() =>
      _LectureEditorDialogState();
}

class _LectureEditorDialogState extends ConsumerState<LectureEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _album;
  late final TextEditingController _order;
  late final TextEditingController _duration;
  String? _sheikhId;
  String? _category;
  late String _language;
  late bool _featured;

  /// The lecture's date. Sorting is newest-first, so this controls where the
  /// lecture lands in albums and Fresh Content. Defaults to today; backdate an
  /// old lecture to send it to the bottom instead of the top.
  late DateTime _date;

  /// Existing album/series names for the selected scholar — offered in the album
  /// dropdown so lectures group under the same series reliably.
  List<String> _albumOptions = const [];

  /// When true the album picker shows a text box to type a brand-new album name
  /// (toggled by the "＋ New album…" dropdown entry).
  bool _newAlbumMode = false;

  /// Sentinel dropdown value that switches into "type a new album" mode.
  static const String _newAlbumSentinel = '__new_album__';

  PickedFile? _picked; // newly chosen audio (null = keep existing)
  late String _audioUrl; // existing url on edit
  late double _fileSizeMb;
  double? _uploadProgress;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    _title = TextEditingController(text: l?.title ?? '');
    _album = TextEditingController(text: l?.album ?? '');
    _order = TextEditingController(
        text: (l?.order ?? 0) == 0 ? '' : l!.order.toString());
    _duration = TextEditingController(
        text: l == null ? '' : _fmtDuration(l.durationSeconds));
    _sheikhId = l?.sheikhId;
    _category = l?.category.isNotEmpty == true ? l!.category : null;
    _language = l?.language ?? AppConstants.supportedLanguages.first;
    _featured = l?.isFeatured ?? false;
    _date = l?.dateAdded ?? DateTime.now();
    _audioUrl = l?.audioUrl ?? '';
    _fileSizeMb = l?.fileSizeMb ?? 0;
    if (_sheikhId != null) _loadAlbums(_sheikhId!);
  }

  @override
  void dispose() {
    _title.dispose();
    _album.dispose();
    _order.dispose();
    _duration.dispose();
    super.dispose();
  }

  /// Loads the chosen scholar's existing album names to fill the album dropdown.
  Future<void> _loadAlbums(String sheikhId) async {
    try {
      final albums =
          await ref.read(adminServiceProvider).albumsForSheikh(sheikhId);
      if (mounted) setState(() => _albumOptions = albums);
    } catch (_) {/* suggestions are best-effort */}
  }

  Future<void> _choose() async {
    final f = await pickFile('audio/*');
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _save(String sheikhName) async {
    if (_title.text.trim().isEmpty) {
      return setState(() => _error = 'Title is required.');
    }
    if (_sheikhId == null) {
      return setState(() => _error = 'Choose a scholar.');
    }
    if (_picked == null && _audioUrl.isEmpty) {
      return setState(() => _error = 'Add an audio file.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final admin = ref.read(adminServiceProvider);
      var url = _audioUrl;
      var sizeMb = _fileSizeMb;
      if (_picked != null) {
        setState(() => _uploadProgress = 0);
        final res = await admin.uploadAudio(
          _sheikhId!,
          _picked!.bytes,
          _picked!.name,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        url = res.url;
        sizeMb = res.sizeMb;
      }
      final model = LectureModel(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        sheikhId: _sheikhId!,
        sheikhName: sheikhName,
        audioUrl: url,
        durationSeconds: _parseDurationSeconds(_duration.text),
        language: _language,
        category: _category ?? '',
        album: _album.text.trim(),
        order: int.tryParse(_order.text.trim()) ?? 0,
        isFeatured: _featured,
        dateAdded: _date,
        fileSizeMb: sizeMb,
        playCount: widget.existing?.playCount ?? 0,
      );
      await admin.saveLecture(model, id: widget.existing?.id);
      ref.invalidate(latestLecturesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheikhs = ref.watch(sheikhsProvider).asData?.value ?? const [];
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final sheikhName = sheikhs
            .where((s) => s.id == _sheikhId)
            .map((s) => s.name)
            .firstOrNull ??
        widget.existing?.sheikhName ??
        '';

    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEdit ? 'Edit lecture' : 'New lecture',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.ink)),
              const SizedBox(height: 20),
              _label('Title'),
              TextField(controller: _title),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Scholar'),
                        DropdownButtonFormField<String>(
                          initialValue: _sheikhId,
                          isExpanded: true,
                          hint: const Text('Select'),
                          items: [
                            for (final s in sheikhs)
                              DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name,
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _sheikhId = v;
                              _albumOptions = const [];
                            });
                            if (v != null) _loadAlbums(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Category'),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          hint: const Text('Select'),
                          items: [
                            for (final c in categories)
                              DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name,
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _category = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Language'),
                        DropdownButtonFormField<String>(
                          initialValue: _language,
                          isExpanded: true,
                          items: [
                            for (final l in AppConstants.supportedLanguages)
                              DropdownMenuItem(
                                  value: l,
                                  child: Text(Formatters.titleCase(l))),
                          ],
                          onChanged: (v) =>
                              setState(() => _language = v ?? _language),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Duration (mm:ss)'),
                        TextField(
                          controller: _duration,
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))
                          ],
                          decoration: const InputDecoration(
                              hintText: 'e.g. 32:29'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('Album / series (optional)'),
              _albumSection(),
              const SizedBox(height: 14),
              _label('Date'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmtDate(_date),
                          style: const TextStyle(color: AdminTheme.ink)),
                      const Icon(Icons.calendar_today,
                          size: 17, color: AdminTheme.subtle),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Newest date shows on top (albums & Fresh). Back-date an old '
                  'lecture to send it to the bottom.',
                  style: TextStyle(color: AdminTheme.subtle, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              _label('Order in album (optional)'),
              TextField(
                controller: _order,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Only for a fixed course (1,2,3…). Blank = by date.',
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
                activeThumbColor: AdminTheme.gold,
                contentPadding: EdgeInsets.zero,
                title: const Text('Featured on home banner'),
              ),
              const SizedBox(height: 8),
              _AudioField(
                picked: _picked,
                existingUrl: _audioUrl,
                progress: _uploadProgress,
                onChoose: _busy ? null : _choose,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : () => _save(sheikhName),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AdminTheme.sidebar))
                        : Text(_isEdit ? 'Save changes' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AdminTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' //
  ];

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Formats total seconds as "mm:ss" for the duration field on edit.
  String _fmtDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Parses the duration field into total seconds. Accepts "mm:ss" (e.g.
  /// 32:29) or a plain number treated as whole minutes (e.g. 32 → 32:00), so
  /// old habits still work.
  int _parseDurationSeconds(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 0;
    if (text.contains(':')) {
      final parts = text.split(':');
      final m = int.tryParse(parts[0].trim()) ?? 0;
      final s = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      return m * 60 + s;
    }
    return (int.tryParse(text) ?? 0) * 60; // plain number = minutes
  }

  /// Album / series picker. Pick "No album", one of the scholar's existing
  /// albums, or "＋ New album…" to type a brand-new series name. Empty = a
  /// standalone lecture. Grouping in the app is by exact name, so reusing an
  /// existing entry keeps a weekly series together.
  Widget _albumSection() {
    if (_sheikhId == null) {
      return const TextField(
        enabled: false,
        decoration: InputDecoration(hintText: 'Pick a scholar first'),
      );
    }

    // Typing a brand-new album name.
    if (_newAlbumMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _album,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'New album name, e.g. Friday Tafsir series'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _newAlbumMode = false;
                _album.clear();
              }),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Choose an existing album'),
              style: TextButton.styleFrom(foregroundColor: AdminTheme.olive),
            ),
          ),
        ],
      );
    }

    // Dropdown of existing albums (+ standalone + create-new). Include the
    // lecture's own album even if the scholar's list hasn't loaded yet.
    final current = _album.text.trim();
    final opts = <String>{..._albumOptions};
    if (current.isNotEmpty) opts.add(current);
    final list = opts.toList()..sort();

    return DropdownButtonFormField<String>(
      initialValue: current.isEmpty ? '' : current,
      isExpanded: true,
      items: [
        const DropdownMenuItem(
            value: '', child: Text('No album (standalone lecture)')),
        for (final a in list)
          DropdownMenuItem(
              value: a, child: Text(a, overflow: TextOverflow.ellipsis)),
        const DropdownMenuItem(
          value: _newAlbumSentinel,
          child: Text('＋  New album…',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
      onChanged: (v) {
        if (v == _newAlbumSentinel) {
          setState(() {
            _newAlbumMode = true;
            _album.clear();
          });
        } else {
          setState(() => _album.text = v ?? '');
        }
      },
    );
  }
}

class _AudioField extends StatelessWidget {
  const _AudioField({
    required this.picked,
    required this.existingUrl,
    required this.progress,
    required this.onChoose,
  });
  final PickedFile? picked;
  final String existingUrl;
  final double? progress;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final String status;
    if (picked != null) {
      status =
          '${picked!.name}  ·  ${Formatters.fileSize(picked!.sizeBytes / (1024 * 1024))}';
    } else if (existingUrl.isNotEmpty) {
      status = 'Current audio kept — choose a file to replace it';
    } else {
      status = 'No audio selected';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.audiotrack, color: AdminTheme.olive, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AdminTheme.subtle, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onChoose,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Choose file'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.ink,
                    side: const BorderSide(color: AdminTheme.border)),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AdminTheme.border,
                color: AdminTheme.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text('Uploading… ${((progress ?? 0) * 100).round()}%',
                style: const TextStyle(
                    color: AdminTheme.subtle, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
