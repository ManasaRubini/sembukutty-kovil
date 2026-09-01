import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'success_screen.dart';

class TransferFormScreen extends ConsumerStatefulWidget {
  final String staffId;

  const TransferFormScreen({super.key, required this.staffId});

  @override
  ConsumerState<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: todayIso());

  String? _selectedDirection; // 'deposit' | 'withdraw'
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash ⇄ Bank Transfer', style: TextStyle(fontFamily: 'Fraunces', color: AppColors.gold100)),
        backgroundColor: AppColors.maroon900,
        iconTheme: const IconThemeData(color: AppColors.gold100),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today, size: 18)),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Direction', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DirectionSelector(
                  selected: _selectedDirection,
                  onChanged: (dir) => setState(() => _selectedDirection = dir),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Deposit reduces your cash in hand and increases the temple bank balance. Withdrawal does the reverse.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0.00'),
                ),
                const SizedBox(height: 14),
                const Text('Remarks (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Weekly bank deposit'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A serially numbered transfer note is generated automatically.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save entry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedDirection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Deposit or Withdraw')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final txn = await ref.read(transactionServiceProvider).create({
        'staff_id': widget.staffId,
        'type': 'transfer',
        'date': _dateCtrl.text.trim(),
        'amount': amount,
        'direction': _selectedDirection,
        'remarks': _remarksCtrl.text.trim(),
      });

      invalidateAllAccountingData(ref, widget.staffId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SuccessScreen(txn: txn, staffId: widget.staffId)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
