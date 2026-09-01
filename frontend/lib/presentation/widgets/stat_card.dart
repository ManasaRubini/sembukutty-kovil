import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A styled stat card matching the HTML .stat class
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final StatCardVariant variant;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.variant = StatCardVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color valueColor;

    switch (variant) {
      case StatCardVariant.income:
        bg = AppColors.incomeBg;
        valueColor = AppColors.income;
      case StatCardVariant.expense:
        bg = AppColors.expenseBg;
        valueColor = AppColors.expense;
      case StatCardVariant.closing:
        bg = AppColors.gold100;
        valueColor = AppColors.ink;
      case StatCardVariant.bank:
        bg = AppColors.bankBg;
        valueColor = AppColors.bank;
      case StatCardVariant.neutral:
        bg = AppColors.paper;
        valueColor = AppColors.ink;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.0,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatCardVariant { neutral, income, expense, closing, bank }
