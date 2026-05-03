class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.profileImageUrl = '',
    this.dateOfBirth,
    this.role = 'user',
    this.createdAt,
    this.isAdmin = false,
  });

  final String id;
  String name;
  String email;
  String phone;
  String profileImageUrl;
  DateTime? dateOfBirth;
  String role;
  DateTime? createdAt;
  bool isAdmin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profileImageUrl': profileImageUrl,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'role': role,
        'createdAt': createdAt?.toIso8601String(),
        'isAdmin': isAdmin,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String? ?? '',
        profileImageUrl: j['profileImageUrl'] as String? ?? '',
        dateOfBirth: j['dateOfBirth'] != null
            ? DateTime.tryParse(j['dateOfBirth'] as String)
            : null,
        role: j['role'] as String? ?? 'user',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        isAdmin: j['isAdmin'] as bool? ?? false,
      );
}
