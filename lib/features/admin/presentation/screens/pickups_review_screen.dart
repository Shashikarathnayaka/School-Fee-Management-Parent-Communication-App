import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/pickup_review_item.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/admin_api_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Maps a raw status string to display label, chip color and text color.
({String label, Color bg, Color fg}) _statusChip(String status) {
  return switch (status) {
    'PICKED_UP' => (
        label: 'Picked Up',
        bg: const Color(0xFFD1FAE5),
        fg: const Color(0xFF065F46),
      ),
    'ABSENT' => (
        label: 'Absent',
        bg: AppColors.errorLight,
        fg: AppColors.error,
      ),
    _ => (
        label: 'Pending',
        bg: const Color(0xFFFFF7ED),
        fg: const Color(0xFF92400E),
      ),
  };
}

String _todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

// ──────────────────────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────────────────────

class PickupsReviewScreen extends StatefulWidget {
  final AdminApiService adminApiService;

  const PickupsReviewScreen({super.key, required this.adminApiService});

  @override
  State<PickupsReviewScreen> createState() => _PickupsReviewScreenState();
}

class _PickupsReviewScreenState extends State<PickupsReviewScreen> {
  late String _selectedDate;
  String? _selectedRouteId; // null = all routes

  List<PickupReviewItem> _items = [];
  List<Map<String, String>> _routes = []; // [{id, name}]

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = _todayIso();
    _loadData();
    _loadRoutes();
  }

  // ── data loading ──

  Future<void> _loadRoutes() async {
    try {
      final raw = await widget.adminApiService.getRoutes();
      if (!mounted) return;
      setState(() {
        _routes = raw
            .whereType<Map>()
            .map((r) => {
                  'id': (r['id'] ?? '') as String,
                  'name': (r['name'] ?? 'Route') as String,
                })
            .toList();
      });
    } catch (_) {
      // Non-critical: route filter stays hidden
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await widget.adminApiService.getPickupsReview(
        date: _selectedDate,
        routeId: _selectedRouteId,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  // ── date picker ──

  Future<void> _pickDate() async {
    final parsed = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: AppColors.surfaceWhite,
            surface: AppColors.surfaceWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadData();
    }
  }

  // ── mark action ──

  void _showMarkSheet(PickupReviewItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MarkPickupSheet(
        item: item,
        onMark: (status, force) => _markPickup(item, status, force),
      ),
    );
  }

  Future<void> _markPickup(
    PickupReviewItem item,
    String status,
    bool force,
  ) async {
    try {
      await widget.adminApiService.markPickup(
        id: item.id,
        status: status,
        force: force,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.studentName} marked as ${_statusChip(status).label}.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(12),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(
          selectedDate: _selectedDate,
          selectedRouteId: _selectedRouteId,
          routes: _routes,
          onTapDate: _pickDate,
          onRouteChanged: (id) {
            setState(() => _selectedRouteId = id);
            _loadData();
          },
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadData);
    }

    if (_items.isEmpty) {
      return _EmptyState(date: _selectedDate);
    }

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _loadData,
      child: ListView.separated(
        key: ValueKey('$_selectedDate|$_selectedRouteId'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PickupCard(
          item: _items[i],
          onTap: () => _showMarkSheet(_items[i]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Filter bar
// ──────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String selectedDate;
  final String? selectedRouteId;
  final List<Map<String, String>> routes;
  final VoidCallback onTapDate;
  final ValueChanged<String?> onRouteChanged;

  const _FilterBar({
    required this.selectedDate,
    required this.selectedRouteId,
    required this.routes,
    required this.onTapDate,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = DateFormat('MMM d, yyyy').format(
      DateTime.tryParse(selectedDate) ?? DateTime.now(),
    );

    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Date picker button
          Flexible(
            child: InkWell(
              key: const Key('pickups_date_picker'),
              onTap: onTapDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayDate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (routes.isNotEmpty) ...[
            const SizedBox(width: 8),
            // Route dropdown
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    key: const Key('pickups_route_filter'),
                    value: selectedRouteId,
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    hint: const Text(
                      'All Routes',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Routes'),
                      ),
                      ...routes.map(
                        (r) => DropdownMenuItem<String?>(
                          value: r['id'],
                          child: Text(
                            r['name']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onRouteChanged,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Pickup card
// ──────────────────────────────────────────────────────────────────────────────

class _PickupCard extends StatelessWidget {
  final PickupReviewItem item;
  final VoidCallback onTap;

  const _PickupCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = _statusChip(item.status);
    final timeStr = item.updatedAt != null
        ? DateFormat('hh:mm a').format(item.updatedAt!.toLocal())
        : '—';
    final driver = item.driverName ?? 'Unassigned';
    final route = item.routeName ?? '—';
    final gradeSection = [item.grade, item.section]
        .where((s) => s != null && s.isNotEmpty)
        .join(' - ');

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('pickup_item_${item.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryBlueLight,
                    child: Text(
                      item.studentName.isNotEmpty
                          ? item.studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (gradeSection.isNotEmpty)
                          Text(
                            'Grade $gradeSection',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: chip.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: chip.fg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.alt_route_rounded,
                    label: route,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.person_rounded,
                    label: driver,
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Mark pickup bottom sheet
// ──────────────────────────────────────────────────────────────────────────────

class _MarkPickupSheet extends StatefulWidget {
  final PickupReviewItem item;
  final Future<void> Function(String status, bool force) onMark;

  const _MarkPickupSheet({required this.item, required this.onMark});

  @override
  State<_MarkPickupSheet> createState() => _MarkPickupSheetState();
}

class _MarkPickupSheetState extends State<_MarkPickupSheet> {
  String? _selectedStatus;
  bool _isLoading = false;

  static const _options = [
    (status: 'PICKED_UP', label: 'Picked Up', icon: Icons.check_circle_rounded),
    (status: 'ABSENT', label: 'Absent', icon: Icons.cancel_rounded),
    (status: 'PENDING', label: 'Pending', icon: Icons.hourglass_top_rounded),
  ];

  Future<void> _confirm() async {
    if (_selectedStatus == null) return;

    // Check if this is a backward move that may need force=true
    final isBackward =
        (widget.item.status == 'PICKED_UP' || widget.item.status == 'ABSENT') &&
            _selectedStatus == 'PENDING';

    bool force = false;
    if (isBackward) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Override Warning',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy)),
          content: Text(
            'Moving from ${_statusChip(widget.item.status).label} to '
            '${_statusChip(_selectedStatus!).label} requires '
            'admin override. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Force Override'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      force = true;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onMark(_selectedStatus!, force);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = _statusChip(widget.item.status);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Text(
            'Set Pickup Status',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.item.studentName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chip.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chip.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: chip.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Options
          ..._options.map((opt) {
            final optChip = _statusChip(opt.status);
            final isSelected = _selectedStatus == opt.status;
            return GestureDetector(
              key: Key('mark_option_${opt.status.toLowerCase()}'),
              onTap: () => setState(() => _selectedStatus = opt.status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? optChip.bg : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? optChip.fg : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(opt.icon,
                        color: isSelected
                            ? optChip.fg
                            : AppColors.textSecondary,
                        size: 22),
                    const SizedBox(width: 12),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 15,
                        color: isSelected
                            ? optChip.fg
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.radio_button_checked,
                          color: optChip.fg, size: 20)
                    else
                      const Icon(Icons.radio_button_unchecked,
                          color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('mark_confirm_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.surfaceWhite,
                disabledBackgroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (_selectedStatus != null && !_isLoading)
                  ? _confirm
                  : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.surfaceWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Error state
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('pickups_retry_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Empty state
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String date;

  const _EmptyState({required this.date});

  @override
  Widget build(BuildContext context) {
    final displayDate = DateFormat('MMM d, yyyy').format(
      DateTime.tryParse(date) ?? DateTime.now(),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.local_shipping_rounded,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Pickups Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pickup records for $displayDate.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
