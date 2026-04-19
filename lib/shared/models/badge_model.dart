// lib/shared/models/badge_model.dart
import 'package:flutter/material.dart';

enum BadgeRarity { common, uncommon, rare, veryRare }

extension BadgeRarityLabel on BadgeRarity {
  String get label {
    switch (this) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.uncommon:
        return 'Uncommon';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.veryRare:
        return 'Very rare';
    }
  }

  /// Approximate % of students who have it — for display only.
  String get prevalence {
    switch (this) {
      case BadgeRarity.common:
        return '80%';
      case BadgeRarity.uncommon:
        return '45%';
      case BadgeRarity.rare:
        return '20%';
      case BadgeRarity.veryRare:
        return '5%';
    }
  }
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final BadgeRarity rarity;
  final bool isEarned;
  final DateTime? earnedAt;

  /// 0.0–1.0 progress toward earning this badge (for locked badges)
  final double progressPercent;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.isEarned = false,
    this.earnedAt,
    this.progressPercent = 0.0,
  });
}

// ─── Certificate ────────────────────────────────────────────────────────────

class CertificateModel {
  final String id;        // e.g. 'CERT-ADA-2026-0073'
  final String moduleId;
  final String moduleTitle;
  final List<String> skillsCovered;
  final int score;        // 0–100
  final DateTime issuedAt;
  final bool isEarned;

  const CertificateModel({
    required this.id,
    required this.moduleId,
    required this.moduleTitle,
    required this.skillsCovered,
    required this.score,
    required this.issuedAt,
    this.isEarned = false,
  });
}
