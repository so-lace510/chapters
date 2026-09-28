import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/experience.dart';
import '../models/experience_type.dart';
import '../services/experience_service.dart';
import '../theme.dart';
import '../widgets/media_view.dart';

class ExperienceDetailScreen extends StatelessWidget {
  final Experience experience;
  const ExperienceDetailScreen({super.key, required this.experience});

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this experience?'),
        content: const Text(
          'This also removes its photo or video. You can\'t undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ExperienceService.instance.delete(experience);
      if (context.mounted) Navigator.pop(context, 'deleted');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t delete. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = typeFor(experience.title);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
          children: [
            Row(
              children: [
                Icon(type.icon, color: type.color, size: 24),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(experience.title, style: theme.textTheme.headlineLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM y').format(experience.happenedOn),
              style: AppTheme.serif(
                size: 17,
                color: AppColors.muted,
                style: FontStyle.italic,
              ),
            ),
            if (experience.hasMedia) ...[
              const SizedBox(height: 20),
              MediaView(experience: experience, playVideo: true),
            ],
            const SizedBox(height: 22),
            SelectableText(
              experience.body,
              style: AppTheme.serif(size: 19.5, height: 1.65),
            ),
            const SizedBox(height: 28),
            Text(
              'Saved ${DateFormat('d MMM y, h:mm a').format(experience.createdAt)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
