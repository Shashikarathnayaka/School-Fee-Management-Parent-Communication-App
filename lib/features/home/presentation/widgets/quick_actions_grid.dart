import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> items;

  const QuickActionsGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Material(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: item.onTap,
                splashColor: AppColors.primaryBlueLight,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlueLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
