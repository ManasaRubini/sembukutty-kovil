import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/providers.dart';

class DeletedRecordsDialog extends ConsumerStatefulWidget {
  const DeletedRecordsDialog({super.key});

  @override
  ConsumerState<DeletedRecordsDialog> createState() => _DeletedRecordsDialogState();
}

class _DeletedRecordsDialogState extends ConsumerState<DeletedRecordsDialog> {
  late Future<List<Map<String, dynamic>>> _deletedFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _deletedFuture = ref.read(transactionServiceProvider).getDeletedTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.maroon900,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, color: AppColors.gold100, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Deleted Bills Archive (Admin Only)',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold100,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gold100, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _deletedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading deleted records: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.expense),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.folder_open, size: 48, color: AppColors.inkSoft),
                          SizedBox(height: 12),
                          Text('No deleted records in database.', style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final serial = item['serial_number'] ?? '—';
                      final type = (item['type'] ?? '').toString().toUpperCase();
                      final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
                      final memberName = item['member_name'] ?? '';
                      final purpose = item['purpose'] ?? item['remarks'] ?? '';
                      final deletedBy = item['deleted_by'] ?? 'Admin';
                      final rawDt = item['deleted_at'] != null ? DateTime.tryParse(item['deleted_at'].toString()) : null;
                      final deletedAt = formatDateTime(rawDt);
                      final date = item['date'] ?? '';


                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Row(
                          children: [
                            Text(serial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.expenseBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.expense),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (memberName.isNotEmpty) Text('Devotee: $memberName', style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                            if (purpose.isNotEmpty) Text('Purpose: $purpose', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                            Text('Date: $date · Deleted by: $deletedBy on $deletedAt', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                          ],
                        ),
                        trailing: Text(
                          formatINR(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.expense),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
