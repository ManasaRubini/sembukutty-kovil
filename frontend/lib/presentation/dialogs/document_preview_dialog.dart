import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/amount_words.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../pdf/pdf_generator.dart';

class DocumentPreviewDialog extends StatelessWidget {
  final TransactionModel txn;
  final String staffName;

  const DocumentPreviewDialog({
    super.key,
    required this.txn,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context) {
    final isVoucher = txn.type == 'expense';
    final isTransfer = txn.type == 'transfer';
    final docTitle = isVoucher
        ? 'Payment Voucher'
        : isTransfer
            ? 'Cash Transfer Note'
            : 'Receipt — ${txn.type == "tax" ? "Temple Tax Collection" : "Donation Collection"}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Text('ௐ', style: TextStyle(fontSize: 24, color: AppColors.maroon700)),
                          const Text('Sembukutty Sastha Kovil', style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(docTitle, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          const Divider(thickness: 2, color: AppColors.ink),
                        ],
                      ),
                    ),
                    _row('${txn.documentLabel} No.', txn.serialNumber ?? '—', isBold: true),
                    _row('Date & Time', formatDateTime(txn.createdAt)),
                    const Divider(),
                    if (!isVoucher && !isTransfer) ...[
                      _field('Received From', txn.memberName.isNotEmpty ? txn.memberName : '—'),
                      _field('Address', txn.address.isNotEmpty ? txn.address : '—'),
                      _field('Phone Number', txn.memberPhone.isNotEmpty ? txn.memberPhone : '—'),
                      _field('Purpose', txn.purpose.isNotEmpty ? txn.purpose : docTitle),
                      _field('Mode of Payment', txn.mode == 'cash' ? 'Cash' : 'Bank Transfer'),
                    ] else if (isVoucher) ...[
                      _field('Paid To', txn.paidTo.isNotEmpty ? txn.paidTo : '—'),
                      _field('Purpose', txn.remarks.isNotEmpty ? txn.remarks : '—'),
                      _field('Paid From', txn.mode == 'cash' ? 'Cash' : 'Bank'),
                    ] else ...[
                      _field('Transaction', txn.direction == 'deposit' ? 'Cash Deposited to Bank' : 'Cash Withdrawn from Bank'),
                      _field('Remarks', txn.remarks.isNotEmpty ? txn.remarks : '—'),
                    ],
                    const Divider(),
                    Center(
                      child: Column(
                        children: [
                          Text(formatINR(txn.amount), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.maroon800)),
                          Text(amountToWords(txn.amount), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    const Divider(),
                    _row('Handled by', staffName, isBold: true),
                    const SizedBox(height: 12),
                    const Text('Signature: ______________________', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        PdfGenerator.printOrShare(txn, staffName);
                      },
                      child: const Text('🖨️ Print PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
