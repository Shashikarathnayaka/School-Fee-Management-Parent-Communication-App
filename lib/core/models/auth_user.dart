import 'user_role.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isParent => role == UserRole.parent;
  bool get isDriver => role == UserRole.driver;
}
