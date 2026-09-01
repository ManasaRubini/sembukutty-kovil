import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../dialogs/document_preview_dialog.dart';
import '../../widgets/common_widgets.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchCtrl = TextEditingController();
  String _docType = 'all';
  String? _dateFrom;
  String? _dateTo;

  void _updateFilter() {
    ref.read(documentsFilterProvider.notifier).state = DocumentsFilter(
      query: _searchCtrl.text.trim(),
      docType: _docType,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(documentsFilterProvider);
    final docsAsync = ref.watch(documentsProvider(filter));
    final staffListAsync = ref.watch(staffListProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receipts & Vouchers',
            style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          const Text(
            'Look up any past receipt or voucher and print it again anytime.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search by serial number or name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. R-00012 or member name',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (_) => _updateFilter(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _dateFrom ?? ''),
                          decoration: const InputDecoration(labelText: 'From date', suffixIcon: Icon(Icons.calendar_today, size: 16)),
                          readOnly: true,
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) {
                              setState(() => _dateFrom = p.toIso8601String().substring(0, 10));
                              _updateFilter();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _dateTo ?? ''),
                          decoration: const InputDecoration(labelText: 'To date', suffixIcon: Icon(Icons.calendar_today, size: 16)),
                          readOnly: true,
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) {
                              setState(() => _dateTo = p.toIso8601String().substring(0, 10));
                              _updateFilter();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Pill('All', selected: _docType == 'all', onTap: () { setState(() => _docType = 'all'); _updateFilter(); }),
                        _Pill('Receipts (Tax/Donation)', selected: _docType == 'receipt', onTap: () { setState(() => _docType = 'receipt'); _updateFilter(); }),
                        _Pill('Vouchers (Expenses)', selected: _docType == 'voucher', onTap: () { setState(() => _docType = 'voucher'); _updateFilter(); }),
                        _Pill('Transfer Notes', selected: _docType == 'transfer', onTap: () { setState(() => _docType = 'transfer'); _updateFilter(); }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: docsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Container(
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
                        Text('📄', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text('No receipts, vouchers or transfer notes match your search.', style: TextStyle(color: AppColors.inkSoft)),
                      ],
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final txn = list[index];
                      String staffName = 'Staff';
                      staffListAsync.whenData((sList) {
                        final found = sList.where((s) => s.id == txn.staffId);
                        if (found.isNotEmpty) staffName = found.first.name;
                      });

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        title: Row(
                          children: [
                            Text(txn.serialNumber ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(width: 8),
                            TagChip.fromType(txn.type),
                          ],
                        ),
                        subtitle: Text(
                          '${txn.displayDescription} · ${formatDateTime(txn.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatINR(txn.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DocumentPreviewDialog(txn: txn, staffName: staffName),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('View', style: TextStyle(fontSize: 12)),
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
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}
