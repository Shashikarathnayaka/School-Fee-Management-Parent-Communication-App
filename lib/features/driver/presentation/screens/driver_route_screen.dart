import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/driver_route.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';

class DriverRouteScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final DriverApiService? driverApiService;

  const DriverRouteScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.driverApiService,
  });

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  late final DriverApiService _driverApiService = widget.driverApiService ??
      ServiceLocator.instance.driverApiService;

  List<DriverRoute> _routes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final routes = await _driverApiService.getTodayRoutes();
      if (!mounted) return;

      setState(() {
        _routes = routes;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load today's routes. Please try again.";
      });
    }
  }

  void _onBottomNavTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.driverRoute);
        break;
      case 2:
        context.go(AppRoutes.driverStudents);
        break;
      case 3:
        context.go(AppRoutes.notifications);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCreateRouteSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Create New Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textSecondary,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Route Name
                      AuthTextField(
                        controller: nameController,
                        label: 'Route Name',
                        hintText: 'e.g. Morning School Route',
                        prefixIcon: Icons.alt_route_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Route name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Start Time
                      AuthTextField(
                        controller: startTimeController,
                        label: 'Start Time (Optional)',
                        hintText: 'e.g. 07:00 AM',
                        prefixIcon: Icons.access_time_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // End Time
                      AuthTextField(
                        controller: endTimeController,
                        label: 'End Time (Optional)',
                        hintText: 'e.g. 08:30 AM',
                        prefixIcon: Icons.access_time_filled_rounded,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      AuthButton(
                        text: 'Create Route',
                        icon: Icons.add_road_rounded,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                FocusScope.of(sheetContext).unfocus();
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                final name = nameController.text.trim();
                                final startTime = startTimeController.text.trim();
                                final endTime = endTimeController.text.trim();

                                try {
                                  final newRoute = await _driverApiService.createRoute(
                                    name: name,
                                    startTime: startTime.isNotEmpty ? startTime : null,
                                    endTime: endTime.isNotEmpty ? endTime : null,
                                  );

                                  if (newRoute == null) {
                                    // createRoute() returned null — API call failed silently
                                    // (no exception thrown, but no route was created).
                                    if (sheetContext.mounted) {
                                      setModalState(() {
                                        isSubmitting = false;
                                      });
                                    }
                                    if (!mounted) return;
                                    _showSnackBar(
                                      "Couldn't create route. Please try again.",
                                      isError: true,
                                    );
                                    return;
                                  }

                                  // Success: close the sheet, refresh the list, then notify.
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  if (!mounted) return;
                                  await _loadRoutes(isRefresh: true);
                                  if (!mounted) return;
                                  _showSnackBar(
                                    'Route "${newRoute.name}" created successfully!',
                                  );
                                } on ApiException catch (e) {
                                  if (sheetContext.mounted) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                  if (!mounted) return;
                                  _showSnackBar(
                                    e.message.isNotEmpty
                                        ? e.message
                                        : "Failed to create route. Please try again.",
                                    isError: true,
                                  );
                                } catch (_) {
                                  if (sheetContext.mounted) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                  if (!mounted) return;
                                  _showSnackBar(
                                    "Failed to create route. Please try again.",
                                    isError: true,
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRouteCard(ThemeData theme, DriverRoute route) {
    final startTime = route.startTime;
    final endTime = route.endTime;
    String timeDisplay;
    if (startTime != null && endTime != null) {
      timeDisplay = '$startTime - $endTime';
    } else if (startTime != null) {
      timeDisplay = 'Starts $startTime';
    } else if (endTime != null) {
      timeDisplay = 'Ends $endTime';
    } else {
      timeDisplay = 'Time not set';
    }

    final studentCount = route.students?.length ?? 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    route.status ?? 'SCHEDULED',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  timeDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.people_outline_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$studentCount ${studentCount == 1 ? 'Student' : 'Students'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMapPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.map_outlined, size: 48, color: AppColors.primaryBlue),
          SizedBox(height: 12),
          Text(
            'Live GPS Route Map',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryNavy,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Route navigation & live tracking will be available upon backend integration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_errorMessage != null && _routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadRoutes(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  size: 42,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Routes Yet Today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No routes yet today — create one to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateRouteSheet,
                icon: const Icon(Icons.add_road_rounded),
                label: const Text('Create Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildLiveMapPlaceholder(),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        ..._routes.map((route) => _buildRouteCard(theme, route)),
        const SizedBox(height: 8),
        _buildLiveMapPlaceholder(),
        const SizedBox(height: 80), // bottom padding for FAB
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRole = widget.activeRoleNotifier.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'Driver Route',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_road_rounded,
              color: AppColors.surfaceWhite,
            ),
            tooltip: 'Create Route',
            onPressed: _showCreateRouteSheet,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        userRole: activeRole,
        onTap: (index) => _onBottomNavTapped(context, index),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRouteSheet,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(
          Icons.add_road_rounded,
          color: AppColors.surfaceWhite,
        ),
        label: const Text(
          'Create Route',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () => _loadRoutes(isRefresh: true),
          child: _buildBody(theme),
        ),
      ),
    );
  }
}
