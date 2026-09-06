import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/common_widgets.dart';

class EditTransactionDialog extends ConsumerStatefulWidget {
  final TransactionModel txn;
  final String staffId;

  const EditTransactionDialog({
    super.key,
    required this.txn,
    required this.staffId,
  });

  @override
  ConsumerState<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends ConsumerState<EditTransactionDialog> {
  late final TextEditingController _dateCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _memberNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _paidToCtrl;
  late final TextEditingController _remarksCtrl;
  late final TextEditingController _utrCtrl;

  late String? _selectedMode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(text: widget.txn.date);
    _amountCtrl = TextEditingController(text: widget.txn.amount.toString());
    _memberNameCtrl = TextEditingController(text: widget.txn.memberName);
    _phoneCtrl = TextEditingController(text: widget.txn.memberPhone);
    _addressCtrl = TextEditingController(text: widget.txn.address);
    _purposeCtrl = TextEditingController(text: widget.txn.purpose);
    _paidToCtrl = TextEditingController(text: widget.txn.paidTo);
    _remarksCtrl = TextEditingController(text: widget.txn.remarks);
    _utrCtrl = TextEditingController(text: widget.txn.utrNumber);
    _selectedMode = widget.txn.mode;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    _memberNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _purposeCtrl.dispose();
    _paidToCtrl.dispose();
    _remarksCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTax = widget.txn.type == 'tax';
    final isDonation = widget.txn.type == 'donation';
    final isExpense = widget.txn.type == 'expense';
    final isTransfer = widget.txn.type == 'transfer';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  const Icon(Icons.edit_note, color: AppColors.gold100, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Edit ${widget.txn.documentLabel} #${widget.txn.serialNumber ?? '—'}',
                      style: const TextStyle(
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
            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                          initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          _dateCtrl.text = picked.toIso8601String().substring(0, 10);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    if (isTax || isDonation) ...[
                      const Text('Devotee / Member Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _memberNameCtrl,
                        decoration: const InputDecoration(hintText: 'Devotee Name'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(hintText: 'Phone Number'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Address'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Purpose', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _purposeCtrl,
                        decoration: const InputDecoration(hintText: 'Purpose'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (isExpense) ...[
                      const Text('Paid To', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _paidToCtrl,
                        decoration: const InputDecoration(hintText: 'Vendor / person name'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Remarks / Purpose', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _remarksCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Expense remarks'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (isTransfer) ...[
                      const Text('Remarks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _remarksCtrl,
                        decoration: const InputDecoration(hintText: 'Transfer remarks'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    PaymentModeSelector(
                      selected: _selectedMode,
                      onChanged: (mode) => setState(() => _selectedMode = mode),
                    ),
                    const SizedBox(height: 14),

                    if (_selectedMode == 'bank') ...[
                      const Text('UTR No. / Bank Ref No.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _utrCtrl,
                        decoration: const InputDecoration(hintText: 'Bank UTR / Reference Number'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.maroon800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _save,
                          child: _isLoading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'date': _dateCtrl.text.trim(),
        'amount': amount,
        'mode': _selectedMode,
        'member_name': _memberNameCtrl.text.trim(),
        'member_phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'purpose': _purposeCtrl.text.trim(),
        'paid_to': _paidToCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
        'utr_number': _utrCtrl.text.trim(),
      };

      await ref.read(transactionServiceProvider).update(widget.txn.id, payload);
      invalidateAllAccountingData(ref, widget.staffId);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
