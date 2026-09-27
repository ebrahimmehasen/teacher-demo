import 'enums.dart';

/// Global account (not tenant-scoped): the same person can study with several teachers.
class User {
  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    password: json['password'] as String,
    role: UserRole.values.byName(json['role'] as String),
    photoUrl: json['photoUrl'] as String?,
  );

  final String id;
  final String name;
  final String phone;

  /// Plain text in the mock layer only; the real backend handles auth.
  final String password;
  final UserRole role;
  final String? photoUrl;

  User copyWith({String? name, String? phone, String? password, String? photoUrl}) => User(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    password: password ?? this.password,
    role: role,
    photoUrl: photoUrl ?? this.photoUrl,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
    'role': role.name,
    'photoUrl': photoUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.phone == phone &&
      other.password == password &&
      other.role == role &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, name, phone, password, role, photoUrl);
}
