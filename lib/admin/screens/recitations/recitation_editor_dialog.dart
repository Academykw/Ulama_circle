import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/reciter_model.dart';
import '../../../models/recitation_model.dart';
import '../../../providers/reciter_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../../services/web_file_picker.dart';

/// Create/edit a single surah recitation for [reciter], with audio upload.
class RecitationEditorDialog extends ConsumerStatefulWidget {
  const RecitationEditorDialog({
    super.key,
    required this.reciter,
    this.existing,
  });
  final ReciterModel reciter;
  final RecitationModel? existing;

  @override
  ConsumerState<RecitationEditorDialog> createState() =>
      _RecitationEditorDialogState();
}

class _RecitationEditorDialogState
    extends ConsumerState<RecitationEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _surah;
  late final TextEditingController _order;
  late final TextEditingController _seconds;

  PickedFile? _picked;
  late String _audioUrl;
  double? _uploadProgress;
  bool _busy = false;
  String? _error;
  late String _kind;

  bool get _isEdit => widget.existing != null;
  bool get _isSurah => _kind == 'surah';

  static const _kinds = <({String value, String label})>[
    (value: 'surah', label: 'Single surah'),
    (value: 'juz', label: 'Juz'),
    (value: 'mushaf', label: 'Full mushaf'),
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _title = TextEditingController(text: r?.title ?? '');
    _surah = TextEditingController(
        text: r == null || r.surahNumber == 0 ? '' : r.surahNumber.toString());
    _order = TextEditingController(text: (r?.order ?? 0).toString());
    _seconds = TextEditingController(
        text: r == null || r.durationSeconds == 0
            ? ''
            : r.durationSeconds.toString());
    _audioUrl = r?.audioUrl ?? '';
    _kind = r?.kind ?? 'surah';
  }

  @override
  void dispose() {
    _title.dispose();
    _surah.dispose();
    _order.dispose();
    _seconds.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final f = await pickFile('audio/*');
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      return setState(() => _error = 'Title is required.');
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
      if (_picked != null) {
        setState(() => _uploadProgress = 0);
        final res = await admin.uploadRecitationAudio(
          widget.reciter.id,
          _picked!.bytes,
          _picked!.name,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        url = res.url;
      }
      final model = RecitationModel(
        id: widget.existing?.id ?? '',
        reciterId: widget.reciter.id,
        reciterName: widget.reciter.name,
        coverUrl: widget.reciter.coverUrl,
        title: _title.text.trim(),
        surahNumber: _isSurah ? (int.tryParse(_surah.text.trim()) ?? 0) : 0,
        kind: _kind,
        audioUrl: url,
        durationSeconds: int.tryParse(_seconds.text.trim()) ?? 0,
        order: int.tryParse(_order.text.trim()) ?? 0,
        listenCount: widget.existing?.listenCount ?? 0,
      );
      await admin.saveRecitation(model, id: widget.existing?.id);
      ref.invalidate(recitationsByReciterProvider(widget.reciter.id));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String audioStatus;
    if (_picked != null) {
      audioStatus =
          '${_picked!.name}  ·  ${Formatters.fileSize(_picked!.sizeBytes / (1024 * 1024))}';
    } else if (_audioUrl.isNotEmpty) {
      audioStatus = 'Current audio kept — choose a file to replace it';
    } else {
      audioStatus = 'No audio selected';
    }

    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEdit ? 'Edit recitation' : 'New recitation',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.ink)),
              const SizedBox(height: 4),
              Text('for ${widget.reciter.name}',
                  style:
                      const TextStyle(color: AdminTheme.subtle, fontSize: 13)),
              const SizedBox(height: 20),
              _label('Type'),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                items: [
                  for (final k in _kinds)
                    DropdownMenuItem(value: k.value, child: Text(k.label)),
                ],
                onChanged: (v) => setState(() => _kind = v ?? _kind),
              ),
              const SizedBox(height: 14),
              _label('Title'),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                    hintText: "e.g. Recitation Of Qur'an (105) Suratul Fil"),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_isSurah) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Surah no.'),
                          TextField(
                            controller: _surah,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                                hintText: '1–114'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Length (seconds)'),
                        TextField(
                          controller: _seconds,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Order'),
                        TextField(
                          controller: _order,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
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
                        const Icon(Icons.audiotrack,
                            color: AdminTheme.olive, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(audioStatus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AdminTheme.subtle, fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _choose,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Choose file'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AdminTheme.ink,
                              side: const BorderSide(color: AdminTheme.border)),
                        ),
                      ],
                    ),
                    if (_uploadProgress != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          minHeight: 6,
                          backgroundColor: AdminTheme.border,
                          color: AdminTheme.gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Uploading… ${((_uploadProgress ?? 0) * 100).round()}%',
                          style: const TextStyle(
                              color: AdminTheme.subtle, fontSize: 12)),
                    ],
                  ],
                ),
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
                    onPressed: _busy ? null : _save,
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
}
