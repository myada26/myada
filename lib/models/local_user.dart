import 'package:hive/hive.dart';

part 'local_user.g.dart';

@HiveType(typeId: 0)
class LocalUser extends HiveObject {
  @HiveField(0)
  late String uid;

  @HiveField(1)
  late String email;

  @HiveField(2)
  late String firstName;

  @HiveField(3)
  late String lastName;

  @HiveField(4)
  late String dateOfBirth;

  @HiveField(5)
  String? cachedIdToken;

  @HiveField(6)
  DateTime? tokenCachedAt;

  @HiveField(7)
  bool hasCompletedDiagnostic = false;

  @HiveField(8)
  String? startingLevel;

  @HiveField(9)
  DateTime createdAt = DateTime.now();

  @HiveField(10)
  DateTime lastSeenAt = DateTime.now();

  @HiveField(11)
  String? avatarPath;
}