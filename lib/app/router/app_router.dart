import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/driver/presentation/screens/driver_history_screen.dart';
import '../../features/driver/presentation/screens/driver_route_screen.dart';
import '../../features/driver/presentation/screens/driver_students_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen.dart';

abstract class AppRouter {
  static GoRouter createRouter(AuthService authService) {
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
          return AppRoutes.home;
        }

        return null;
      },
      // routes: [
      //   GoRoute(
      //     path: AppRoutes.splash,
      //     name: AppRoutes.splashName,
      //     builder: (context, state) => SplashScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.login,
      //     name: AppRoutes.loginName,
      //     builder: (context, state) => LoginScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.register,
      //     name: AppRoutes.registerName,
      //     builder: (context, state) => RegistrationScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.home,
      //     name: AppRoutes.homeName,
      //     builder: (context, state) => HomeScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.payments,
      //     name: AppRoutes.paymentsName,
      //     builder: (context, state) => const PaymentsScreen(),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.notifications,
      //     name: AppRoutes.notificationsName,
      //     builder: (context, state) => const NotificationsScreen(),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.profile,
      //     name: AppRoutes.profileName,
      //     builder: (context, state) => ProfileScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.receipts,
      //     name: AppRoutes.receiptsName,
      //     builder: (context, state) => const ReceiptsScreen(),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.driverRoute,
      //     name: AppRoutes.driverRouteName,
      //     builder: (context, state) => DriverRouteScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.driverStudents,
      //     name: AppRoutes.driverStudentsName,
      //     builder: (context, state) => DriverStudentsScreen(authService: authService),
      //   ),
      //   GoRoute(
      //     path: AppRoutes.driverHistory,
      //     name: AppRoutes.driverHistoryName,
      //     builder: (context, state) => DriverHistoryScreen(authService: authService),
      //   ),
      // ],
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splashName,
          builder: (context, state) => SplashScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) => LoginScreen(authService: authService),
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
          builder: (context, state) => HomeScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.payments,
          name: AppRoutes.paymentsName,
          builder: (context, state) => PaymentsScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          name: AppRoutes.notificationsName,
          builder: (context, state) =>
              NotificationsScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          builder: (context, state) => ProfileScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.receipts,
          name: AppRoutes.receiptsName,
          builder: (context, state) => ReceiptsScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.driverRoute,
          name: AppRoutes.driverRouteName,
          builder: (context, state) =>
              DriverRouteScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.driverStudents,
          name: AppRoutes.driverStudentsName,
          builder: (context, state) =>
              DriverStudentsScreen(authService: authService),
        ),
        GoRoute(
          path: AppRoutes.driverHistory,
          name: AppRoutes.driverHistoryName,
          builder: (context, state) =>
              DriverHistoryScreen(authService: authService),
        ),
      ],
    );
  }
}
