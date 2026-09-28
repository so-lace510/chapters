import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/experience.dart';
import '../models/experience_type.dart';
import '../theme.dart';
import 'media_view.dart';

/// One moment on the timeline: a coloured dot on a vertical line, the date,
/// the title, a preview of the writing and any photo or video.
class TimelineEntry extends StatelessWidget {
  final Experience experience;
  final VoidCallback onTap;

  const TimelineEntry({
    super.key,
    required this.experience,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = typeFor(experience.title);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 7),
              padding: const EdgeInsets.fromLTRB(22, 0, 0, 30),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.line, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE d MMM').format(experience.happenedOn),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(type.icon, size: 19, color: type.color),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          experience.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    experience.body,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.serif(size: 17.5, height: 1.5),
                  ),
                  if (experience.hasMedia) ...[
                    const SizedBox(height: 14),
                    MediaView(experience: experience, height: 210),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 1,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: type.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.paper, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
