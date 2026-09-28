import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/experience_type.dart';
import '../services/experience_service.dart';
import '../theme.dart';

class NewExperienceScreen extends StatefulWidget {
  const NewExperienceScreen({super.key});

  @override
  State<NewExperienceScreen> createState() => _NewExperienceScreenState();
}

class _NewExperienceScreenState extends State<NewExperienceScreen> {
  final _picker = ImagePicker();
  final _custom = TextEditingController();
  final _body = TextEditingController();

  String? _selected;
  DateTime _date = DateTime.now();
  XFile? _media;
  bool _isVideo = false;
  bool _saving = false;

  @override
  void dispose() {
    _custom.dispose();
    _body.dispose();
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pick(String kind) async {
    Navigator.pop(context); // close the bottom sheet
    try {
      XFile? file;
      switch (kind) {
        case 'photo':
          file = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 2200,
          );
        case 'camera':
          file = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 2200,
          );
        case 'video':
          file = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 2),
          );
        case 'record':
          file = await _picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(minutes: 2),
          );
      }
      if (file != null) {
        setState(() {
          _media = file;
          _isVideo = kind == 'video' || kind == 'record';
        });
      }
    } catch (_) {
      _toast('Couldn\'t open that. Check the app\'s photo and camera permissions.');
    }
  }

  void _showMediaSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose a photo'),
              onTap: () => _pick('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => _pick('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose a video'),
              onTap: () => _pick('video'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record a video'),
              onTap: () => _pick('record'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selected == null) {
      _toast('Pick a title for this experience.');
      return;
    }
    final title = _selected == otherLabel ? _custom.text.trim() : _selected!;
    if (title.isEmpty) {
      _toast('Type a title for your experience.');
      return;
    }
    if (_body.text.trim().isEmpty) {
      _toast('Write a few words about what happened.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ExperienceService.instance.create(
        title: title,
        body: _body.text.trim(),
        happenedOn: _date,
        media: _media,
        isVideo: _isVideo,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _toast('Couldn\'t save. Check your connection and try again.');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New experience')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
          children: [
            Text('What kind of day was it?', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in experienceTypes)
                  ChoiceChip(
                    avatar: Icon(
                      t.icon,
                      size: 18,
                      color: _selected == t.label ? Colors.white : t.color,
                    ),
                    label: Text(t.label),
                    selected: _selected == t.label,
                    showCheckmark: false,
                    selectedColor: t.color,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _selected == t.label ? Colors.white : AppColors.ink,
                    ),
                    onSelected: (_) => setState(() => _selected = t.label),
                  ),
              ],
            ),
            if (_selected == otherLabel) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _custom,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                decoration: const InputDecoration(hintText: 'Give it a title'),
              ),
            ],
            const SizedBox(height: 22),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(DateFormat('EEEE, d MMMM y').format(_date)),
                    ),
                    const Text(
                      'Change',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _body,
              minLines: 7,
              maxLines: 14,
              textCapitalization: TextCapitalization.sentences,
              style: AppTheme.serif(size: 18),
              decoration: const InputDecoration(
                hintText: 'What happened? How did it feel?',
              ),
            ),
            const SizedBox(height: 16),
            if (_media == null)
              OutlinedButton.icon(
                onPressed: _showMediaSheet,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add a photo or video (optional)'),
              )
            else
              _mediaPreview(),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save experience'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _isVideo
              ? Container(
                  height: 120,
                  width: double.infinity,
                  color: AppColors.ink,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        _media!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              : Image.file(
                  File(_media!.path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() {
                _media = null;
                _isVideo = false;
              }),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
