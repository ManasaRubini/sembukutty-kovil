import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Tag chip matching HTML .tag class — tax, donation, expense, transfer, cash, bank
class TagChip extends StatelessWidget {
  final String label;
  final TagType type;

  const TagChip({super.key, required this.label, required this.type});

  factory TagChip.fromType(String type) {
    return TagChip(label: _label(type), type: _typeFrom(type));
  }

  factory TagChip.fromMode(String mode) {
    return TagChip(
      label: mode == 'cash' ? 'Cash' : 'Bank',
      type: mode == 'cash' ? TagType.cash : TagType.bank,
    );
  }

  static String _label(String t) {
    switch (t) {
      case 'tax': return 'Tax';
      case 'donation': return 'Donation';
      case 'expense': return 'Expense';
      case 'transfer': return 'Transfer';
      default: return t;
    }
  }

  static TagType _typeFrom(String t) {
    switch (t) {
      case 'tax': return TagType.tax;
      case 'donation': return TagType.donation;
      case 'expense': return TagType.expense;
      case 'transfer': return TagType.transfer;
      default: return TagType.tax;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case TagType.tax:
        bg = AppColors.gold100; fg = const Color(0xFF8A6512);
      case TagType.donation:
        bg = AppColors.incomeBg; fg = AppColors.income;
      case TagType.expense:
        bg = AppColors.expenseBg; fg = AppColors.expense;
      case TagType.transfer:
        bg = AppColors.transferBg; fg = AppColors.transfer;
      case TagType.cash:
        bg = AppColors.gold100; fg = const Color(0xFF8A6512);
      case TagType.bank:
        bg = AppColors.bankBg; fg = AppColors.bank;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

enum TagType { tax, donation, expense, transfer, cash, bank }

/// Section title with gold bar prefix — matches HTML .section-title
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 14, height: 2,
            color: AppColors.gold500,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12.5,
              letterSpacing: 1.2,
              color: AppColors.maroon700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action card — matches HTML .qa class
class QuickActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color topBorderColor;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.topBorderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.gold100.withValues(alpha: 0.5),
        splashColor: AppColors.gold300.withValues(alpha: 0.3),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Top colored accent bar (matches HTML .qa::before)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4,
                child: Container(color: topBorderColor),
              ),
              // Centered emoji & label
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 26,
                          fontFamilyFallback: ['Segoe UI Emoji', 'Noto Color Emoji', 'Apple Color Emoji'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment mode selector — matches HTML .mode-opt
class PaymentModeSelector extends StatelessWidget {
  final String? selected; // 'cash' | 'bank' | null
  final ValueChanged<String> onChanged;
  final String cashLabel;
  final String bankLabel;

  const PaymentModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.cashLabel = '💵 Cash',
    this.bankLabel = '🏦 Bank Transfer',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ModeButton(
          label: cashLabel,
          selected: selected == 'cash',
          onTap: () => onChanged('cash'),
        )),
        const SizedBox(width: 10),
        Expanded(child: _ModeButton(
          label: bankLabel,
          selected: selected == 'bank',
          onTap: () => onChanged('bank'),
        )),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.maroon700 : AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.maroon700 : AppColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// Direction selector for transfers — Deposit or Withdraw
class DirectionSelector extends StatelessWidget {
  final String? selected; // 'deposit' | 'withdraw' | null
  final ValueChanged<String> onChanged;

  const DirectionSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ModeButton(
          label: '📥 Deposit Cash to Bank',
          selected: selected == 'deposit',
          onTap: () => onChanged('deposit'),
        )),
        const SizedBox(width: 10),
        Expanded(child: _ModeButton(
          label: '📤 Withdraw Cash from Bank',
          selected: selected == 'withdraw',
          onTap: () => onChanged('withdraw'),
        )),
      ],
    );
  }
}
