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
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'User',
        email: j['email']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        profileImageUrl: j['profileImageUrl']?.toString() ?? '',
        dateOfBirth: j['dateOfBirth'] != null
            ? DateTime.tryParse(j['dateOfBirth'].toString())
            : null,
        role: j['role']?.toString() ?? 'user',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
        isAdmin: j['isAdmin'] as bool? ?? false,
      );
}
