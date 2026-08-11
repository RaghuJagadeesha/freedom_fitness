/// User profile model with experience level for Safety Guardrails (P0.4)
/// and identity for BYOA OAuth (P0.1).
library;

enum ExperienceLevel { beginner, intermediate, advanced }

extension ExperienceLevelExt on ExperienceLevel {
  String get label {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner (< 3 months)';
      case ExperienceLevel.intermediate:
        return 'Intermediate (3–12 months)';
      case ExperienceLevel.advanced:
        return 'Advanced (1+ year)';
    }
  }

  String get shortLabel {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }
}

class UserProfile {
  final String? googleId;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final ExperienceLevel experienceLevel;
  final DateTime? joinDate;

  const UserProfile({
    this.googleId,
    this.displayName,
    this.email,
    this.photoUrl,
    this.experienceLevel = ExperienceLevel.beginner,
    this.joinDate,
  });

  bool get isSignedIn => googleId != null;

  /// Whether the user has been training for less than 3 months.
  bool get isBeginner => experienceLevel == ExperienceLevel.beginner;

  UserProfile copyWith({
    String? googleId,
    String? displayName,
    String? email,
    String? photoUrl,
    ExperienceLevel? experienceLevel,
    DateTime? joinDate,
  }) {
    return UserProfile(
      googleId: googleId ?? this.googleId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'googleId': googleId,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'experienceLevel': experienceLevel.index,
    'joinDate': joinDate?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    googleId: json['googleId'],
    displayName: json['displayName'],
    email: json['email'],
    photoUrl: json['photoUrl'],
    experienceLevel: ExperienceLevel.values[json['experienceLevel'] ?? 0],
    joinDate: json['joinDate'] != null
        ? DateTime.parse(json['joinDate'])
        : null,
  );
}
