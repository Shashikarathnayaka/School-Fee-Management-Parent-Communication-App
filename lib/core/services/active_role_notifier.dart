import 'package:flutter/foundation.dart';
import '../models/user_role.dart';

/// Tracks which role mode (Parent or Driver) the dual-role user is currently viewing.
/// Single-role users will never change this value — it stays at their only role.
class ActiveRoleNotifier extends ValueNotifier<UserRole> {
  ActiveRoleNotifier() : super(UserRole.parent);
}
