import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/services/active_role_notifier.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/parent_api_service.dart';
import '../../core/services/student_list_notifier.dart';
import '../../features/auth/presentation/screens/driver_upgrade_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/driver/presentation/screens/driver_history_screen.dart';
import '../../features/driver/presentation/screens/driver_route_screen.dart';
import '../../features/driver/presentation/screens/driver_students_screen.dart';
import '../../core/models/driver_route.dart';
import '../../core/services/driver_api_service.dart';
import '../../features/driver/presentation/screens/driver_register_student_screen.dart';
import '../../features/home/presentation/screens/add_student_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/profile/presentation/screens/manage_students_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen.dart';

abstract class AppRouter {
  static GoRouter createRouter(
    AuthService authService,
    ActiveRoleNotifier activeRoleNotifier,
    StudentListNotifier studentListNotifier,
    ParentApiService parentApiService, {
    DriverApiService? driverApiService,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authService,
      debugLogDiagnostics: false,
      redirect: (context, state) {
        final isAuthenticated = authService.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.splash ||
            state.matchedLocation == AppRoutes.register;

        if (!isAuthenticated) {
          return isAuthRoute ? null : AppRoutes.login;
        }

        if (isAuthenticated &&
            (state.matchedLocation == AppRoutes.login ||
                state.matchedLocation == AppRoutes.splash)) {
          final user = authService.currentUser;
          if (user != null) {
            activeRoleNotifier.value = user.role;
          }
          return AppRoutes.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splashName,
          builder: (context, state) => SplashScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) => LoginScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: AppRoutes.registerName,
          builder: (context, state) =>
              RegistrationScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (context, state) => HomeScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: parentApiService,
            driverApiService: driverApiService,
            studentListNotifier: studentListNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.payments,
          name: AppRoutes.paymentsName,
          builder: (context, state) => PaymentsScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          name: AppRoutes.notificationsName,
          builder: (context, state) => NotificationsScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          builder: (context, state) => ProfileScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.receipts,
          name: AppRoutes.receiptsName,
          builder: (context, state) => ReceiptsScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.driverRoute,
          name: AppRoutes.driverRouteName,
          builder: (context, state) => DriverRouteScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: driverApiService,
          ),
        ),
        GoRoute(
          path: AppRoutes.driverStudents,
          name: AppRoutes.driverStudentsName,
          builder: (context, state) => DriverStudentsScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: driverApiService,
          ),
        ),
        GoRoute(
          path: AppRoutes.driverRegisterStudent,
          name: AppRoutes.driverRegisterStudentName,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return DriverRegisterStudentScreen(
              authService: authService,
              driverApiService: driverApiService,
              initialRouteId: extra?['routeId'] as String?,
              initialRoutes: extra?['routes'] as List<DriverRoute>?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.driverHistory,
          name: AppRoutes.driverHistoryName,
          builder: (context, state) => DriverHistoryScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.becomeDriver,
          name: AppRoutes.becomeDriverName,
          builder: (context, state) => DriverUpgradeScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.addStudent,
          name: AppRoutes.addStudentName,
          builder: (context, state) => AddStudentScreen(
            authService: authService,
            parentApiService: parentApiService,
            studentListNotifier: studentListNotifier,
          ),
        ),
        GoRoute(
          path: AppRoutes.manageStudents,
          name: AppRoutes.manageStudentsName,
          builder: (context, state) => ManageStudentsScreen(
            authService: authService,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: parentApiService,
            studentListNotifier: studentListNotifier,
          ),
        ),
      ],
    );
  }
}
