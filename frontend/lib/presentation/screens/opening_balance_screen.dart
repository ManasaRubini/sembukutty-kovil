import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class OpeningBalanceDialog extends ConsumerStatefulWidget {
  final String currentStaffId;
  final VoidCallback onSaved;

  const OpeningBalanceDialog({
    super.key,
    required this.currentStaffId,
    required this.onSaved,
  });

  @override
  ConsumerState<OpeningBalanceDialog> createState() => _OpeningBalanceDialogState();
}

class _OpeningBalanceDialogState extends ConsumerState<OpeningBalanceDialog> {
  final _bankCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    final bank = double.tryParse(_bankCtrl.text.trim()) ?? 0.0;
    final cash = double.tryParse(_cashCtrl.text.trim()) ?? 0.0;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(openingBalanceServiceProvider).create(
            bankBalance: bank,
            cashBalance: cash,
            cashHolderStaffId: widget.currentStaffId,
          );
      ref.invalidate(openingBalanceProvider);
      widget.onSaved();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Temple's opening balances",
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Asked only once, from whoever is the first to set up billing. These become the starting point for the temple\'s accounts.',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.expense, fontSize: 13)),
              const SizedBox(height: 10),
            ],
            const Text(
              'Opening Bank Balance (₹)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bankCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Opening Cash Balance (₹)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cashCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
            const SizedBox(height: 8),
            const Text(
              'The cash amount will start as being held by you. As cash is deposited or withdrawn, it moves between members and the bank.',
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save & continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
