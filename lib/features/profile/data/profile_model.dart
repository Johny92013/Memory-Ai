/// Profilmodell für `public.profiles`.
class ProfileModel {
  const ProfileModel({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarPath,
    this.profileCompleted = false,
    this.birthDate,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarPath;
  final bool profileCompleted;
  final DateTime? birthDate;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final combined = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (combined.isNotEmpty) return combined;
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return email ?? 'Profil';
  }

  bool get hasAvatar => avatarPath != null && avatarPath!.isNotEmpty;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      avatarPath: json['avatar_path'] as String?,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      birthDate: _parseDate(json['birth_date']),
      gender: json['gender'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (username != null) 'username': username,
      if (avatarPath != null) 'avatar_path': avatarPath,
      'profile_completed': profileCompleted,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().split('T').first,
      if (gender != null) 'gender': gender,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarPath,
    bool? profileCompleted,
    DateTime? birthDate,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBirthDate = false,
    bool clearGender = false,
    bool clearAvatarPath = false,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      profileCompleted: profileCompleted ?? this.profileCompleted,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      gender: clearGender ? null : (gender ?? this.gender),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
