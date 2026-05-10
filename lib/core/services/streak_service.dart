// lib/core/services/streak_service.dart
//
// Tracks daily logins and maintains a streak counter.
// On each app open (after auth), call checkIn().
// Awards daily login points (+2) and streak bonuses (+15 / +50).
// Backed by Hive for fast, offline-first reads.

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'points_service.dart';

class StreakService extends ChangeNotifier {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const String _boxName = 'streak_data';
  late Box _box;
  String _uid = 'anonymous';

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDate;
  bool _checkedInToday = false;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  bool get checkedInToday => _checkedInToday;

  /// Initialize the Hive box. Call once in main().
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  void setUserId(String uid) {
    _uid = uid;
    _loadFromBox();
  }

  String _k(String key) => '${_uid}_$key';

  void _loadFromBox() {
    _currentStreak = _box.get(_k('current_streak'), defaultValue: 0) as int;
    _longestStreak = _box.get(_k('longest_streak'), defaultValue: 0) as int;
    final lastStr = _box.get(_k('last_active_date')) as String?;
    _lastActiveDate = lastStr != null ? DateTime.tryParse(lastStr) : null;
    _checkedInToday = _isSameDay(_lastActiveDate, DateTime.now());
    notifyListeners();
  }

  /// Returns the active days for the last 7 days (Mon-Sun or rolling).
  List<bool> getActiveDays() {
    final now = DateTime.now();
    final List<bool> days = [];
    // Read the stored active-days set
    final storedDays = _box.get(_k('active_days'), defaultValue: <String>[]);
    final Set<String> activeDaySet = (storedDays as List)
        .map((d) => d.toString())
        .toSet();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      days.add(activeDaySet.contains(key));
    }
    return days;
  }

  /// Called once per app open (from AuthGate after authenticated).
  /// Awards daily login points and manages streak.
  Future<void> checkIn() async {
    if (_uid == 'anonymous') return;

    final now = DateTime.now();
    if (_isSameDay(_lastActiveDate, now)) {
      // Already checked in today — do nothing.
      _checkedInToday = true;
      return;
    }

    final pts = PointsService.instance;

    // Fresh accounts start at 0 points; the streak begins, but day-one
    // onboarding should not mint leaderboard points before any real activity.
    if (_lastActiveDate == null) {
      _currentStreak = 1;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
      await pts.updateStreakColumns(_currentStreak, _longestStreak);
      _lastActiveDate = now;
      _checkedInToday = true;
      await _box.put(_k('current_streak'), _currentStreak);
      await _box.put(_k('longest_streak'), _longestStreak);
      await _box.put(_k('last_active_date'), now.toIso8601String());
      await _saveActiveDay(now);
      notifyListeners();
      debugPrint('StreakService: initialized streak without day-one points');
      return;
    }

    // Award +2 daily login points
    await pts.addPoints(PointsService.dailyLogin, 'daily_login');

    // Update streak
    if (_lastActiveDate != null && _isYesterday(_lastActiveDate!, now)) {
      _currentStreak++;
    } else {
      _currentStreak = 1;
    }

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    // Streak milestones
    if (_currentStreak == 7) {
      await pts.addPoints(PointsService.streakBonus7, 'streak_7_day');
    }
    if (_currentStreak == 30) {
      await pts.addPoints(PointsService.streakBonus30, 'streak_30_day');
    }

    // Update streak columns in leaderboard_scores
    await pts.updateStreakColumns(_currentStreak, _longestStreak);

    // Save to Hive
    _lastActiveDate = now;
    _checkedInToday = true;
    await _box.put(_k('current_streak'), _currentStreak);
    await _box.put(_k('longest_streak'), _longestStreak);
    await _box.put(_k('last_active_date'), now.toIso8601String());

    // Track active days (keep last 30 days worth)
    await _saveActiveDay(now);

    notifyListeners();
    debugPrint(
      'StreakService: checkIn — streak=$_currentStreak longest=$_longestStreak',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime prev, DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    return prev.year == yesterday.year &&
        prev.month == yesterday.month &&
        prev.day == yesterday.day;
  }

  Future<void> _saveActiveDay(DateTime day) async {
    final dayKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final storedDays = _box.get(_k('active_days'), defaultValue: <String>[]);
    final activeDays = List<String>.from(storedDays as List);
    if (!activeDays.contains(dayKey)) {
      activeDays.add(dayKey);
      if (activeDays.length > 30) activeDays.removeAt(0);
      await _box.put(_k('active_days'), activeDays);
    }
  }
}
