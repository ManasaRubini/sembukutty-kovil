import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../dialogs/document_preview_dialog.dart';
import '../../dialogs/edit_transaction_dialog.dart';
import '../../dialogs/admin_reauth_dialog.dart';
import '../../widgets/common_widgets.dart';

import '../billing/expense_form_screen.dart';
import '../billing/tax_donation_form_screen.dart';
import '../billing/transfer_form_screen.dart';
import '../devotees/devotees_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStaffId = ref.watch(currentStaffIdProvider);
    final role = ref.watch(userRoleProvider);
    final staffListAsync = ref.watch(staffListProvider);

    final isAdmin = role == 'admin';
    String staffId = isAdmin ? 'admin' : (currentStaffId ?? '');
    String staffName = isAdmin ? 'Admin' : 'Account';

    staffListAsync.whenData((list) {
      if (!isAdmin && staffId.isEmpty && list.isNotEmpty) {
        staffId = list.first.id;
      }
      if (!isAdmin) {
        final s = list.where((x) => x.id == staffId);
        if (s.isNotEmpty) staffName = s.first.name;
      }
    });

    if (!isAdmin && staffId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final dashAsync = ref.watch(dashboardProvider(staffId));

    return dashAsync.when(
      data: (dash) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider(staffId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. LORD SEMBUKUTTY SASTHA DIVINE WELCOME BANNER CARD ─────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBF4E6), Color(0xFFFFFBF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8D3A7), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.maroon900.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Opacity(
                          opacity: 0.08,
                          child: Icon(Icons.star, size: 140, color: AppColors.gold500),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()}, $staffName ${_getGreetingIcon()}',
                                    style: const TextStyle(
                                      fontFamily: 'Fraunces',
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.maroon900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'May Lord Sastha bless the temple and all devotees.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.inkSoft,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // Date selector chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.maroon700),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.keyboard_arrow_down, size: 15, color: AppColors.inkSoft),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right Lord Sembukutty Sastha Divine Image Frame
                            Container(
                              height: 100,
                              width: 105,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.6), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold500.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/lord_sastha.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Image.asset(
                                    'assets/images/banner_card.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: AppColors.gold100,
                                      child: const Center(
                                        child: Icon(Icons.temple_hindu, size: 40, color: AppColors.maroon900),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── 2. TEMPLE FINANCIAL OVERVIEW ─────────────────────────────────────
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.maroon800, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Temple Financial Overview',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: _OverviewStatCard(title: 'TAX COLLECTED', amount: dash.taxCollected, colorTheme: _CardTheme.green, icon: Icons.currency_rupee)),
                        const SizedBox(width: 10),
                        Expanded(child: _OverviewStatCard(title: 'DONATIONS', amount: dash.donations, colorTheme: _CardTheme.teal, icon: Icons.handshake_outlined)),
                        const SizedBox(width: 10),
                        Expanded(child: _OverviewStatCard(title: 'EXPENSES', amount: dash.expenses, colorTheme: _CardTheme.red, icon: Icons.account_balance_wallet_outlined)),
                        const SizedBox(width: 10),
                        Expanded(child: _OverviewStatCard(title: 'TEMPLE BANK BALANCE', amount: dash.bankBalance, colorTheme: _CardTheme.purple, icon: Icons.account_balance, subtitle: 'Bank: ${formatINR(dash.bankBalance)} | Cash: ${formatINR(dash.totalCash)}')),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _OverviewStatCard(title: 'TAX COLLECTED', amount: dash.taxCollected, colorTheme: _CardTheme.green, icon: Icons.currency_rupee)),
                            const SizedBox(width: 10),
                            Expanded(child: _OverviewStatCard(title: 'DONATIONS', amount: dash.donations, colorTheme: _CardTheme.teal, icon: Icons.handshake_outlined)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _OverviewStatCard(title: 'EXPENSES', amount: dash.expenses, colorTheme: _CardTheme.red, icon: Icons.account_balance_wallet_outlined)),
                            const SizedBox(width: 10),
                            Expanded(child: _OverviewStatCard(title: 'TEMPLE BANK BALANCE', amount: dash.bankBalance, colorTheme: _CardTheme.purple, icon: Icons.account_balance, subtitle: 'Bank: ${formatINR(dash.bankBalance)} | Cash: ${formatINR(dash.totalCash)}')),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 12),

              // Summary Cash in hand & Grand total cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryBannerCard(
                      title: 'YOUR CASH IN HAND\n($staffName)',
                      amount: dash.myCash,
                      icon: Icons.people_outline,
                      bgColor: const Color(0xFFFFF5E6),
                      borderColor: const Color(0xFFF7DDB5),
                      iconColor: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryBannerCard(
                      title: 'GRAND TOTAL\n(BANK + CASH)',
                      amount: dash.grandTotal,
                      icon: Icons.account_balance_wallet,
                      bgColor: const Color(0xFFFEF3D6),
                      borderColor: const Color(0xFFEED08E),
                      iconColor: const Color(0xFFB45309),
                      isLotusDecor: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── 3. QUICK ACTIONS ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flash_on_rounded, color: AppColors.maroon800, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon900,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View All', style: TextStyle(color: AppColors.maroon700, fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.maroon700),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final isTablet = constraints.maxWidth > 500;
                  final cols = isWide ? 5 : (isTablet ? 3 : 2);

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isWide ? 1.35 : 1.25,
                    children: [
                      _QuickActionButton(
                        title: 'Tax\nCollection',
                        icon: Icons.currency_rupee,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        accentColor: const Color(0xFF2E7D32),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TaxDonationFormScreen(type: 'tax', staffId: staffId)),
                        ),
                      ),
                      _QuickActionButton(
                        title: 'Donation\nCollection',
                        icon: Icons.handshake_outlined,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        accentColor: const Color(0xFFE65100),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TaxDonationFormScreen(type: 'donation', staffId: staffId)),
                        ),
                      ),
                      _QuickActionButton(
                        title: 'Expense',
                        icon: Icons.receipt_long,
                        iconBg: const Color(0xFFFFEBEE),
                        iconColor: const Color(0xFFC62828),
                        accentColor: const Color(0xFFC62828),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ExpenseFormScreen(staffId: staffId)),
                        ),
                      ),
                      _QuickActionButton(
                        title: 'Cash ⇄ Bank\nTransfer',
                        icon: Icons.swap_horiz_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF1565C0),
                        accentColor: const Color(0xFF1565C0),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TransferFormScreen(staffId: staffId)),
                        ),
                      ),
                      _QuickActionButton(
                        title: 'Devotee\nDetails',
                        icon: Icons.groups_outlined,
                        iconBg: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFF6A1B9A),
                        accentColor: const Color(0xFF6A1B9A),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DevoteesScreen()),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ─── 4. RECENT TRANSACTIONS ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.article_outlined, color: AppColors.maroon800, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon900,
                        ),
                      ),
                    ],
                  ),
                  if (onNavigateTab != null)
                    TextButton(
                      onPressed: () => onNavigateTab!(1),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All', style: TextStyle(color: AppColors.maroon700, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.maroon700),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (dash.recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Column(
                    children: [
                      Text('📋', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text('No entries yet. Add your first billing entry above.', style: TextStyle(color: AppColors.inkSoft)),
                    ],
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dash.recentTransactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final txn = dash.recentTransactions[index];
                      final isExpense = txn.type == 'expense';
                      final isIncome = txn.type == 'tax' || txn.type == 'donation';

                      final iconBg = isIncome
                          ? (txn.type == 'tax' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0))
                          : (isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD));

                      final iconColor = isIncome
                          ? (txn.type == 'tax' ? const Color(0xFF2E7D32) : const Color(0xFFE65100))
                          : (isExpense ? const Color(0xFFC62828) : const Color(0xFF1565C0));

                      final iconData = txn.type == 'tax'
                          ? Icons.currency_rupee
                          : (txn.type == 'donation' ? Icons.handshake_outlined : (isExpense ? Icons.receipt_long : Icons.swap_horiz));

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: iconColor, size: 20),
                        ),
                        title: Text(
                          txn.memberName.isNotEmpty ? txn.memberName : txn.documentLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),

                        subtitle: Text(
                          '${txn.serialNumber ?? '—'}  •  ${txn.mode?.toUpperCase() ?? 'CASH'}  •  ${txn.date}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isExpense ? '-' : (isIncome ? '+' : '')} ${formatINR(txn.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isExpense ? AppColors.expense : (isIncome ? AppColors.income : AppColors.ink),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.inkSoft),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DocumentPreviewDialog(txn: txn, staffName: staffName),
                                );
                              },
                            ),
                            if (isAdmin)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.inkSoft),
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    showDialog(
                                      context: context,
                                      builder: (_) => EditTransactionDialog(txn: txn, staffId: staffId),
                                    );
                                  } else if (val == 'delete') {
                                    _confirmDelete(context, ref, txn.id, staffId);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppColors.expense), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.expense))])),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, color: AppColors.maroon700, size: 40),
            const SizedBox(height: 10),
            const Text('Connecting to Dashboard...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              onPressed: () {
                ref.invalidate(dashboardProvider(staffId));
                ref.invalidate(staffListProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String staffId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Delete this entry? This action is archived into the database.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(transactionServiceProvider).delete(id);
                invalidateAllAccountingData(ref, staffId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bill deleted and archived successfully'), backgroundColor: AppColors.income),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                final errStr = e.toString();
                if (errStr.contains('Invalid or expired token') || errStr.contains('Admin privileges required')) {
                  final reauthed = await promptAdminReauth(context, ref);
                  if (reauthed) {
                    try {
                      await ref.read(transactionServiceProvider).delete(id);
                      invalidateAllAccountingData(ref, staffId);
                    } catch (retryErr) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $retryErr'), backgroundColor: AppColors.expense),
                        );
                      }
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $errStr'), backgroundColor: AppColors.expense),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

enum _CardTheme { green, teal, red, purple }

class _OverviewStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final _CardTheme colorTheme;
  final IconData icon;
  final String? subtitle;

  const _OverviewStatCard({
    required this.title,
    required this.amount,
    required this.colorTheme,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconBg;
    Color iconColor;

    switch (colorTheme) {
      case _CardTheme.green:
        bgColor = const Color(0xFFEAF7F0);
        iconBg = const Color(0xFFC8E6C9);
        iconColor = const Color(0xFF25A269);
        break;
      case _CardTheme.teal:
        bgColor = const Color(0xFFEBF7FA);
        iconBg = const Color(0xFFB2EBF2);
        iconColor = const Color(0xFF0FB7C0);
        break;
      case _CardTheme.red:
        bgColor = const Color(0xFFFDECEF);
        iconBg = const Color(0xFFFFCDD2);
        iconColor = const Color(0xFFE53935);
        break;
      case _CardTheme.purple:
        bgColor = const Color(0xFFF3EBFB);
        iconBg = const Color(0xE1E0CFFC);
        iconColor = const Color(0xFF8E24AA);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconBg.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: iconColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatINR(amount),
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                )
              : Row(
                  children: [
                    Icon(Icons.north_east, size: 12, color: iconColor),
                    const SizedBox(width: 3),
                    Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: iconColor)),
                  ],
                ),
        ],
      ),
    );
  }
}

class _SummaryBannerCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final bool isLotusDecor;

  const _SummaryBannerCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    this.isLotusDecor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    color: iconColor.withValues(alpha: 0.9),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatINR(amount),
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon900.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
                ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
