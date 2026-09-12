import 'package:flutter/foundation.dart';
import 'user_role.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final Set<UserRole> roles;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  bool get isParent => roles.contains(UserRole.parent);
  bool get isDriver => roles.contains(UserRole.driver);
  bool get hasDualRole => isParent && isDriver;

  /// Backward-compat getter — returns the "primary" role.
  /// For dual-role users, the activeRoleNotifier decides which view is shown;
  /// this getter is only a fallback for code that doesn't have access to the notifier.
  UserRole get role => isDriver ? UserRole.driver : UserRole.parent;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'roles': roles.map((r) => r.name).toList(),
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['roles'];
    final Set<UserRole> parsedRoles = {};

    if (rolesJson is List) {
      for (final r in rolesJson) {
        final str = r.toString().toLowerCase();
        if (str == 'driver') {
          parsedRoles.add(UserRole.driver);
        } else if (str == 'parent') {
          parsedRoles.add(UserRole.parent);
        }
      }
    }

    if (parsedRoles.isEmpty && json['role'] != null) {
      final str = json['role'].toString().toLowerCase();
      if (str == 'driver') {
        parsedRoles.add(UserRole.driver);
      } else if (str == 'parent') {
        parsedRoles.add(UserRole.parent);
      }
    }

    if (parsedRoles.isEmpty) {
      parsedRoles.add(UserRole.parent);
    }

    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: parsedRoles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          setEquals(roles, other.roles);

  @override
  int get hashCode => Object.hash(id, name, email, Object.hashAll(roles));
}
