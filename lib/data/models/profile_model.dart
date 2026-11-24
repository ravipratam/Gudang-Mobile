class ProfileModel {
  final String id;
  final String fullName;
  final String role; // 'admin' or 'staff'
  final DateTime? createdAt;
  final String? email;
  final String? avatarUrl;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.role = 'staff',
    this.createdAt,
    this.email,
    this.avatarUrl,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory ProfileModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackEmail,
    String? fallbackAvatarUrl,
  }) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Pengguna Gudang',
      role: (json['role'] as String?) ?? 'staff',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      email: (json['email'] as String?) ?? fallbackEmail,
      avatarUrl: (json['avatar_url'] as String?) ?? fallbackAvatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? role,
    DateTime? createdAt,
    String? email,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          role == other.role &&
          email == other.email &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      role.hashCode ^
      (email?.hashCode ?? 0) ^
      (avatarUrl?.hashCode ?? 0);
}
