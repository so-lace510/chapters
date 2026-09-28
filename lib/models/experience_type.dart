import 'package:flutter/material.dart';

class ExperienceType {
  final String label;
  final IconData icon;
  final Color color;
  const ExperienceType(this.label, this.icon, this.color);
}

const otherLabel = 'Other';

/// The titles a person can pick from. "Other" lets them type their own.
const experienceTypes = <ExperienceType>[
  ExperienceType('Big win', Icons.emoji_events_rounded, Color(0xFFD99100)),
  ExperienceType('Small win', Icons.wb_sunny_rounded, Color(0xFF3F9468)),
  ExperienceType('Normal day', Icons.coffee_rounded, Color(0xFF6F7F8F)),
  ExperienceType('Bad day', Icons.cloud_rounded, Color(0xFFB8506A)),
  ExperienceType('Lesson learned', Icons.lightbulb_rounded, Color(0xFF7B5EA7)),
  ExperienceType('Grateful moment', Icons.favorite_rounded, Color(0xFFD9695A)),
  ExperienceType('Milestone', Icons.flag_rounded, Color(0xFF2B7BB9)),
  ExperienceType(otherLabel, Icons.edit_rounded, Color(0xFF4A5568)),
];

/// Custom titles (typed under "Other") fall back to the "Other" styling.
ExperienceType typeFor(String title) => experienceTypes.firstWhere(
      (t) => t.label == title,
      orElse: () => experienceTypes.last,
    );

bool isPresetTitle(String title) =>
    experienceTypes.any((t) => t.label == title && t.label != otherLabel);
