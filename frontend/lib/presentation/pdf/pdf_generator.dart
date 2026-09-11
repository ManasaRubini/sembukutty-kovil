import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/amount_words.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';

class PdfGenerator {
  /// Generate PDF Uint8List bytes with pure-Dart pw.Document (works on Web, Windows, Android, iOS)
  static Future<Uint8List> generatePdf(TransactionModel txn, String staffName) async {
    final isVoucher = txn.type == 'expense';
    final isTransfer = txn.type == 'transfer';
    final docTitle = isVoucher
        ? 'Payment Voucher'
        : isTransfer
            ? 'Cash Transfer Note'
            : 'Receipt — ${txn.type == "tax" ? "Temple Tax Collection" : "Donation Collection"}';

    final amountFormatted = formatINR(txn.amount);
    final amountInWords = amountToWords(txn.amount);
    final formattedDate = formatDateTime(txn.createdAt);
    final maroonColor = PdfColor.fromHex('#721c24');

    pw.Font mainFont;
    pw.Font boldFont;
    try {
      mainFont = await PdfGoogleFonts.notoSansTamilRegular();
      boldFont = await PdfGoogleFonts.notoSansTamilBold();
    } catch (_) {
      try {
        mainFont = await PdfGoogleFonts.latoRegular();
        boldFont = await PdfGoogleFonts.latoBold();
      } catch (_) {
        mainFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: maroonColor, width: 2),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'Sembukutty Sastha Kovil',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: maroonColor,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    docTitle,
                    style: pw.TextStyle(
                      font: mainFont,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: maroonColor, thickness: 1.5),
                pw.SizedBox(height: 8),

                // Serial & Date
                _buildRow('${txn.documentLabel} No.', txn.serialNumber ?? '—', mainFont, boldFont),
                pw.SizedBox(height: 4),
                _buildRow('Date & Time', formattedDate, mainFont, boldFont),

                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                pw.SizedBox(height: 8),

                // Type-specific details
                if (!isVoucher && !isTransfer) ...[
                  _buildRow('Received From', txn.memberName.isNotEmpty ? txn.memberName : '—', mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Address', txn.address.isNotEmpty ? txn.address : '—', mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Phone Number', txn.memberPhone.isNotEmpty ? txn.memberPhone : '—', mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Purpose', txn.purpose.isNotEmpty ? txn.purpose : docTitle, mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Mode of Payment', txn.mode == 'cash' ? 'Cash' : 'Bank Transfer', mainFont, boldFont),
                  if (txn.utrNumber.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _buildRow('UTR No. / Ref No.', txn.utrNumber, mainFont, boldFont),
                  ],
                ] else if (isVoucher) ...[
                  _buildRow('Paid To', txn.paidTo.isNotEmpty ? txn.paidTo : '—', mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Purpose', txn.remarks.isNotEmpty ? txn.remarks : '—', mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Paid From', txn.mode == 'cash' ? 'Cash' : 'Bank', mainFont, boldFont),
                ] else ...[
                  _buildRow('Transaction', txn.direction == 'deposit' ? 'Cash Deposited to Bank' : 'Cash Withdrawn from Bank', mainFont, boldFont),
                  pw.SizedBox(height: 4),
                  _buildRow('Remarks', txn.remarks.isNotEmpty ? txn.remarks : '—', mainFont, boldFont),
                ],

                pw.SizedBox(height: 12),

                // Amount Box
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: maroonColor, style: pw.BorderStyle.dashed),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        amountFormatted,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: maroonColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        amountInWords,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: mainFont,
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                pw.SizedBox(height: 8),

                // Footer
                _buildRow('Handled by', staffName, mainFont, boldFont),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Signature: ______________________',
                  style: pw.TextStyle(font: mainFont, fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildRow(String label, String value, pw.Font mainFont, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: mainFont, fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: boldFont, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
        ),
      ],
    );
  }

  /// Direct printing / PDF preview
  static Future<void> printOrShare(TransactionModel txn, String staffName) async {
    final pdfBytes = await generatePdf(txn, staffName);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${txn.serialNumber ?? "doc"}.pdf',
    );
  }
}
