class ProfileModel {
  final String id;
  final String fullName;
  final String role; // 'admin' or 'staff'
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.role = 'staff',
    this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Pengguna Gudang',
      role: (json['role'] as String?) ?? 'staff',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
