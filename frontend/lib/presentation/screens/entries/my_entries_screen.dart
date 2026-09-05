import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../dialogs/document_preview_dialog.dart';
import '../../widgets/common_widgets.dart';

class MyEntriesScreen extends ConsumerStatefulWidget {
  const MyEntriesScreen({super.key});

  @override
  ConsumerState<MyEntriesScreen> createState() => _MyEntriesScreenState();
}

class _MyEntriesScreenState extends ConsumerState<MyEntriesScreen> {
  String _filterType = 'all'; // 'all' | 'tax' | 'donation' | 'expense' | 'transfer'

  @override
  Widget build(BuildContext context) {
    final currentStaffId = ref.watch(currentStaffIdProvider);
    final role = ref.watch(userRoleProvider);
    final staffListAsync = ref.watch(staffListProvider);

    final isAdmin = role == 'admin';
    String? queryStaffId = isAdmin ? null : (currentStaffId ?? '');
    String headerTitle = isAdmin ? 'All entries · Admin' : 'My entries';
    Map<String, String> staffMap = {};

    staffListAsync.whenData((list) {
      for (var s in list) {
        staffMap[s.id] = s.name;
      }
      if (!isAdmin) {
        if ((queryStaffId == null || queryStaffId!.isEmpty) && list.isNotEmpty) {
          queryStaffId = list.first.id;
        }
        final s = list.where((x) => x.id == queryStaffId);
        if (s.isNotEmpty) headerTitle = 'My entries · ${s.first.name}';
      }
    });

    final txnsAsync = ref.watch(myTransactionsProvider(queryStaffId));

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                headerTitle,
                style: const TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.maroon700),
                tooltip: 'Refresh entries',
                onPressed: () => ref.invalidate(myTransactionsProvider(queryStaffId)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Pill('All', selected: _filterType == 'all', onTap: () => setState(() => _filterType = 'all')),
                _Pill('Tax', selected: _filterType == 'tax', onTap: () => setState(() => _filterType = 'tax')),
                _Pill('Donation', selected: _filterType == 'donation', onTap: () => setState(() => _filterType = 'donation')),
                _Pill('Expense', selected: _filterType == 'expense', onTap: () => setState(() => _filterType = 'expense')),
                _Pill('Transfer', selected: _filterType == 'transfer', onTap: () => setState(() => _filterType = 'transfer')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myTransactionsProvider(queryStaffId));
              },
              child: txnsAsync.when(
                data: (list) {
                  var filtered = list;
                  if (_filterType != 'all') {
                    filtered = list.where((x) => x.type == _filterType).toList();
                  }

                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('📋', style: TextStyle(fontSize: 32)),
                              SizedBox(height: 8),
                              Text('No entries found.', style: TextStyle(color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final txn = filtered[index];
                        final isExpense = txn.type == 'expense';
                        final isIncome = txn.type == 'tax' || txn.type == 'donation';
                        final billedBy = staffMap[txn.staffId] ?? 'Staff';

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
                              if (txn.utrNumber.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper,
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'UTR: ${txn.utrNumber}',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
                                  ),
                                ),
                              if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'By $billedBy',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.maroon900),
                                  ),
                                ),
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
                                      builder: (_) => DocumentPreviewDialog(txn: txn, staffName: billedBy),
                                    );
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: AppColors.expense,
                                onPressed: () => _confirmDelete(context, ref, txn.id, queryStaffId ?? ''),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.expense))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String staffId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Delete this entry? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(transactionServiceProvider).delete(id);
              invalidateAllAccountingData(ref, staffId);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.maroon700 : AppColors.paper,
            border: Border.all(color: selected ? AppColors.maroon700 : AppColors.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
