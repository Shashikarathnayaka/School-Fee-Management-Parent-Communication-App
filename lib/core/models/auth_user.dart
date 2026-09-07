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
}
