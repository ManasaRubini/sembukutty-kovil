import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../dialogs/document_preview_dialog.dart';
import '../main_shell.dart';

class SuccessScreen extends ConsumerWidget {
  final TransactionModel txn;
  final String staffId;

  const SuccessScreen({
    super.key,
    required this.txn,
    required this.staffId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffListAsync = ref.watch(staffListProvider);
    String staffName = 'Staff';
    staffListAsync.whenData((list) {
      final found = list.where((s) => s.id == staffId);
      if (found.isNotEmpty) staffName = found.first.name;
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Entry saved',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${txn.documentLabel} No. ${txn.serialNumber ?? "—"} · ${formatINR(txn.amount)}',
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    },
                    child: const Text('Back to dashboard'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => DocumentPreviewDialog(txn: txn, staffName: staffName),
                      );
                    },
                    child: Text('🖨️ Print ${txn.documentLabel}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
