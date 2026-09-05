import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'success_screen.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String staffId;

  const ExpenseFormScreen({super.key, required this.staffId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _purposeCtrl = TextEditingController();
  final _paidToCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: todayIso());

  String? _selectedMode; // 'cash' | 'bank'
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense', style: TextStyle(fontFamily: 'Fraunces', color: AppColors.gold100)),
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
                Row(
                  children: const [
                    Text('Purpose / remarks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(width: 4),
                    Text('*', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _purposeCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'What was this expense for? e.g. Flower decoration, Electricity bill',
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Paid to (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _paidToCtrl,
                  decoration: const InputDecoration(hintText: 'Vendor / person name'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Text('Paid from', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(width: 4),
                    Text('*', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                PaymentModeSelector(
                  selected: _selectedMode,
                  cashLabel: '💵 Cash',
                  bankLabel: '🏦 Bank',
                  onChanged: (mode) => setState(() => _selectedMode = mode),
                ),
                const SizedBox(height: 14),
                const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0.00'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A serially numbered voucher is generated automatically for this expense.',
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
    final purpose = _purposeCtrl.text.trim();
    if (purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purpose / remarks is required for expenses')));
      return;
    }
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select whether paid from Cash or Bank')));
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
        'type': 'expense',
        'date': _dateCtrl.text.trim(),
        'amount': amount,
        'mode': _selectedMode,
        'remarks': purpose,
        'paid_to': _paidToCtrl.text.trim(),
      });

      invalidateAllAccountingData(ref, widget.staffId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SuccessScreen(txn: txn, staffId: widget.staffId)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('Insufficient Cash')) {
        showInsufficientBalanceDialog(
          context,
          title: 'Insufficient Cash in Hand',
          message: errStr,
        );
      } else if (errStr.contains('Insufficient Bank')) {
        showInsufficientBalanceDialog(
          context,
          title: 'Insufficient Bank Balance',
          message: errStr,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errStr)));
      }
    }
  }

}
