import 'package:hive_flutter/hive_flutter.dart';
import '../models/local_user.dart';

class HiveService {
  static const String _userBox = 'users';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LocalUserAdapter());
    await Hive.openBox<LocalUser>(_userBox);
  }

  Box<LocalUser> get _box => Hive.box<LocalUser>(_userBox);

  // ── User ops ────────────────────────────────────────────

  Future<void> saveUser(LocalUser user) async {
    await _box.put(user.uid, user);
  }

  LocalUser? getUserByUid(String uid) {
    return _box.get(uid);
  }

  LocalUser? getLastUser() {
    if (_box.isEmpty) return null;
    return _box.values.last;
  }

  Future<void> updateLastSeen(String uid) async {
    final user = _box.get(uid);
    if (user != null) {
      user.lastSeenAt = DateTime.now();
      await user.save();
    }
  }

  Future<void> clearUser(String uid) async {
    await _box.delete(uid);
  }
}