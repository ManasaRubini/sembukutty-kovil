import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/amount_words.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';

class PdfGenerator {
  static Future<Uint8List> generatePdf(TransactionModel txn, String staffName) async {
    final pdf = pw.Document();

    // Load Noto Sans Tamil fonts from Google Fonts via printing package
    pw.Font tamilRegular;
    pw.Font tamilBold;

    try {
      tamilRegular = await PdfGoogleFonts.notoSansTamilRegular();
      tamilBold = await PdfGoogleFonts.notoSansTamilBold();
    } catch (_) {
      // Fallback to standard Noto Sans if offline
      tamilRegular = await PdfGoogleFonts.notoSansRegular();
      tamilBold = await PdfGoogleFonts.notoSansBold();
    }

    final isVoucher = txn.type == 'expense';
    final isTransfer = txn.type == 'transfer';
    final docTitle = isVoucher
        ? 'Payment Voucher'
        : isTransfer
            ? 'Cash Transfer Note'
            : 'Receipt — ${txn.type == "tax" ? "Temple Tax Collection" : "Donation Collection"}';

    // Format Rupee text cleanly for PDF
    final amountFormatted = formatINR(txn.amount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header (OM, Temple Name, Subtitle)
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ௐ',
                        style: pw.TextStyle(
                          font: tamilBold,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Sembukutty Sastha Kovil',
                        style: pw.TextStyle(
                          font: tamilBold,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        docTitle,
                        style: pw.TextStyle(
                          font: tamilRegular,
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 2,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Document Metadata (Serial Number & Date)
                _pdfRow(
                  '${txn.documentLabel} No.',
                  txn.serialNumber ?? '—',
                  fontRegular: tamilRegular,
                  fontBold: tamilBold,
                  isBold: true,
                ),
                _pdfRow(
                  'Date & Time',
                  formatDateTime(txn.createdAt),
                  fontRegular: tamilRegular,
                  fontBold: tamilBold,
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),

                // Details Grid
                if (!isVoucher && !isTransfer) ...[
                  _pdfField('Received From', txn.memberName.isNotEmpty ? txn.memberName : '—', fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Address', txn.address.isNotEmpty ? txn.address : '—', fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Phone Number', txn.memberPhone.isNotEmpty ? txn.memberPhone : '—', fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Purpose', txn.purpose.isNotEmpty ? txn.purpose : docTitle, fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Mode of Payment', txn.mode == 'cash' ? 'Cash' : 'Bank Transfer', fontRegular: tamilRegular, fontBold: tamilBold),
                ] else if (isVoucher) ...[
                  _pdfField('Paid To', txn.paidTo.isNotEmpty ? txn.paidTo : '—', fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Purpose', txn.remarks.isNotEmpty ? txn.remarks : '—', fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Paid From', txn.mode == 'cash' ? 'Cash' : 'Bank', fontRegular: tamilRegular, fontBold: tamilBold),
                ] else ...[
                  _pdfField('Transaction', txn.direction == 'deposit' ? 'Cash Deposited to Bank' : 'Cash Withdrawn from Bank', fontRegular: tamilRegular, fontBold: tamilBold),
                  _pdfField('Remarks', txn.remarks.isNotEmpty ? txn.remarks : '—', fontRegular: tamilRegular, fontBold: tamilBold),
                ],

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 6),

                // Amount Section
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        amountFormatted,
                        style: pw.TextStyle(
                          font: tamilBold,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        amountToWords(txn.amount),
                        style: pw.TextStyle(
                          font: tamilRegular,
                          fontSize: 9.5,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.Spacer(),

                // Signature & Footer
                _pdfRow(
                  'Handled by',
                  staffName,
                  fontRegular: tamilRegular,
                  fontBold: tamilBold,
                  isBold: true,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Signature: ______________________',
                  style: pw.TextStyle(font: tamilRegular, fontSize: 10, color: PdfColors.grey800),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrShare(TransactionModel txn, String staffName) async {
    final pdfBytes = await generatePdf(txn, staffName);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: '${txn.serialNumber ?? "doc"}.pdf',
    );
  }
}

pw.Widget _pdfRow(
  String label,
  String value, {
  required pw.Font fontRegular,
  required pw.Font fontBold,
  bool isBold = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: isBold ? fontBold : fontRegular,
            fontSize: 10.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfField(
  String label,
  String value, {
  required pw.Font fontRegular,
  required pw.Font fontBold,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
