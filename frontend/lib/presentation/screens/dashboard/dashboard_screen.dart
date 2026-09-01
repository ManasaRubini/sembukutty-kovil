import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/stat_card.dart';
import '../billing/tax_donation_form_screen.dart';
import '../billing/expense_form_screen.dart';
import '../billing/transfer_form_screen.dart';
import '../../dialogs/document_preview_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Your account · $staffName'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: StatCard(label: 'Tax collected', value: formatINR(dash.taxCollected), variant: StatCardVariant.income)),
                            const SizedBox(width: 10),
                            Expanded(child: StatCard(label: 'Donations', value: formatINR(dash.donations), variant: StatCardVariant.income)),
                            const SizedBox(width: 10),
                            Expanded(child: StatCard(label: 'Expenses', value: formatINR(dash.expenses), variant: StatCardVariant.expense)),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: StatCard(label: 'Tax collected', value: formatINR(dash.taxCollected), variant: StatCardVariant.income)),
                                const SizedBox(width: 10),
                                Expanded(child: StatCard(label: 'Donations', value: formatINR(dash.donations), variant: StatCardVariant.income)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: StatCard(label: 'Expenses', value: formatINR(dash.expenses), variant: StatCardVariant.expense)),
                              ],
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Your cash in hand', value: formatINR(dash.myCash), variant: StatCardVariant.closing)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(label: 'Temple bank balance', value: formatINR(dash.bankBalance), variant: StatCardVariant.neutral)),
                ],
              ),
              const SectionTitle('Temple overview'),
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Total cash (all members)', value: formatINR(dash.totalCash), variant: StatCardVariant.neutral)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(label: 'Grand total (bank + cash)', value: formatINR(dash.grandTotal), variant: StatCardVariant.closing)),
                ],
              ),
              const SectionTitle('New billing entry'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isWide ? 1.8 : 1.3,
                    children: [
                      QuickActionCard(
                        emoji: '🪙',
                        label: 'Tax\nCollection',
                        topBorderColor: AppColors.gold500,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TaxDonationFormScreen(type: 'tax', staffId: staffId)),
                        ),
                      ),
                      QuickActionCard(
                        emoji: '🙏',
                        label: 'Donation\nCollection',
                        topBorderColor: AppColors.income,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TaxDonationFormScreen(type: 'donation', staffId: staffId)),
                        ),
                      ),
                      QuickActionCard(
                        emoji: '🧾',
                        label: 'Expense',
                        topBorderColor: AppColors.expense,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ExpenseFormScreen(staffId: staffId)),
                        ),
                      ),
                      QuickActionCard(
                        emoji: '🔁',
                        label: 'Cash ⇄ Bank\nTransfer',
                        topBorderColor: AppColors.bank,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TransferFormScreen(staffId: staffId)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionTitle('Recent entries'),
                  if (onNavigateTab != null)
                    TextButton(
                      onPressed: () => onNavigateTab!(1),
                      child: const Text('View All', style: TextStyle(color: AppColors.maroon700, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              if (dash.recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: const [
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

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        title: Text(
                          txn.displayDescription,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (txn.serialNumber != null)
                              Text(
                                txn.serialNumber!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink),
                              ),
                            Text(formatDate(txn.date), style: const TextStyle(fontSize: 12)),
                            TagChip.fromType(txn.type),
                            if (txn.mode != null) TagChip.fromMode(txn.mode!),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isExpense ? "−" : isIncome ? "+" : ""}${formatINR(txn.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isExpense ? AppColors.expense : isIncome ? AppColors.income : AppColors.ink,
                              ),
                            ),
                            if (txn.serialNumber != null)
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 18),
                                color: AppColors.inkSoft,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => DocumentPreviewDialog(txn: txn, staffName: staffName),
                                  );
                                },
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
}
