// lib/core/services/leaderboard_models.dart

class RankedStudent {
  final String id;
  final String name;
  final int rank;
  final int totalPoints;
  final int? rankChange; // positive = moved up, negative = moved down, null = no change
  final bool isCurrentUser;
  final int currentStreak;
  final int modulesCompleted;

  const RankedStudent({
    required this.id,
    required this.name,
    required this.rank,
    required this.totalPoints,
    this.rankChange,
    this.isCurrentUser = false,
    this.currentStreak = 0,
    this.modulesCompleted = 0,
  });

  /// Get the user's initials (first letter of first + last name).
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Points gap to the person above (set by the service layer).
  int gapToAbove(List<RankedStudent> all) {
    if (rank <= 1) return 0;
    final above = all.where((s) => s.rank == rank - 1).firstOrNull;
    return above != null ? above.totalPoints - totalPoints : 0;
  }
}
