// lib/shared/models/user_model.dart

/// Represents the authenticated learner profile stored locally.
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime dateOfBirth;
  final DateTime createdAt;

  /// Whether the user has completed the onboarding flow
  final bool hasCompletedOnboarding;

  /// Whether the user has completed the diagnostic assessment
  final bool hasCompletedDiagnostic;

  /// Overall skill level: 'beginner' | 'novice' | 'intermediate'
  final String? skillLevel;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.createdAt,
    this.hasCompletedOnboarding = false,
    this.hasCompletedDiagnostic = false,
    this.skillLevel,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => firstName;

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    bool? hasCompletedOnboarding,
    bool? hasCompletedDiagnostic,
    String? skillLevel,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasCompletedDiagnostic:
          hasCompletedDiagnostic ?? this.hasCompletedDiagnostic,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'hasCompletedOnboarding': hasCompletedOnboarding ? 1 : 0,
        'hasCompletedDiagnostic': hasCompletedDiagnostic ? 1 : 0,
        'skillLevel': skillLevel,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        firstName: map['firstName'] as String,
        lastName: map['lastName'] as String,
        email: map['email'] as String,
        dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
        hasCompletedOnboarding: (map['hasCompletedOnboarding'] as int) == 1,
        hasCompletedDiagnostic: (map['hasCompletedDiagnostic'] as int) == 1,
        skillLevel: map['skillLevel'] as String?,
      );
}
