import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TempleHeader extends StatelessWidget {
  final bool isAdmin;
  final String? staffName;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onStaffTap;

  const TempleHeader({
    super.key,
    this.isAdmin = false,
    this.staffName,
    this.currentTab = 0,
    this.onTabSelected,
    this.onStaffTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.maroon900, AppColors.maroon700],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Gopuram watermark icon in top right
            Positioned(
              right: -10,
              top: -20,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: _GopuramPainter(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand mark & title
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold300, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.temple_hindu, color: AppColors.gold300, size: 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Sembukutty Sastha Kovil',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Fraunces',
                                    color: AppColors.gold100,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'BILLING & ACCOUNTS',
                                  style: TextStyle(
                                    color: AppColors.gold300,
                                    fontSize: 9.5,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Staff chip
                    if (staffName != null && staffName!.isNotEmpty)
                      InkWell(
                        onTap: onStaffTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.gold300.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.gold500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                staffName!,
                                style: const TextStyle(
                                  color: AppColors.gold100,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (onTabSelected != null) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TabBtn(label: 'Dashboard', index: 0, selected: currentTab == 0, onTap: onTabSelected!),
                        _TabBtn(label: isAdmin ? 'All Entries' : 'My Entries', index: 1, selected: currentTab == 1, onTap: onTabSelected!),
                        _TabBtn(label: 'Reports', index: 2, selected: currentTab == 2, onTap: onTabSelected!),
                        _TabBtn(label: 'Receipts', index: 3, selected: currentTab == 3, onTap: onTabSelected!),
                        _TabBtn(label: 'Settings', index: 4, selected: currentTab == 4, onTap: onTabSelected!),
                      ],
                    ),
                  ),
                ] else
                  const SizedBox(height: 8),
                // Decorative bottom gold border line
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold500, AppColors.gold300, AppColors.gold500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  const _TabBtn({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.gold500 : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.gold100.withValues(alpha: 0.7),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _GopuramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.05);
    path.lineTo(size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.4, size.height * 0.2);
    path.close();

    path.moveTo(size.width * 0.35, size.height * 0.2);
    path.lineTo(size.width * 0.65, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.35);
    path.lineTo(size.width * 0.3, size.height * 0.35);
    path.close();

    path.addRect(Rect.fromLTWH(
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.5,
      size.height * 0.5,
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
