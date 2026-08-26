import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String? actionText;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                actionText ?? AppStrings.viewAll,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
