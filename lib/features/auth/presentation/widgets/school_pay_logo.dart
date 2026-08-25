import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class SchoolPayLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDarkBackground;

  const SchoolPayLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.52;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryNavy,
                AppColors.primaryBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withAlpha(70),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Academic Cap + Shield composite icon
              Icon(
                Icons.school_rounded,
                size: iconSize,
                color: AppColors.surfaceWhite,
              ),
              Positioned(
                bottom: size * 0.15,
                right: size * 0.15,
                child: Container(
                  padding: EdgeInsets.all(size * 0.04),
                  decoration: const BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: size * 0.22,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 14),
          Text(
            'N&D Smart SchoolPay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: isDarkBackground
                  ? AppColors.surfaceWhite
                  : AppColors.primaryNavy,
            ),
          ),
        ],
      ],
    );
  }
}
