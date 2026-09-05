import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/amount_words.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';

class PdfGenerator {
  /// Generate clean HTML for perfect Tamil & English text rendering
  static String generateHtml(TransactionModel txn, String staffName) {
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

    final detailsRows = StringBuffer();

    if (!isVoucher && !isTransfer) {
      detailsRows.write('''
        <div class="row"><span class="label">Received From</span><span class="val">${_escapeHtml(txn.memberName.isNotEmpty ? txn.memberName : '—')}</span></div>
        <div class="row"><span class="label">Address</span><span class="val">${_escapeHtml(txn.address.isNotEmpty ? txn.address : '—')}</span></div>
        <div class="row"><span class="label">Phone Number</span><span class="val">${_escapeHtml(txn.memberPhone.isNotEmpty ? txn.memberPhone : '—')}</span></div>
        <div class="row"><span class="label">Purpose</span><span class="val">${_escapeHtml(txn.purpose.isNotEmpty ? txn.purpose : docTitle)}</span></div>
        <div class="row"><span class="label">Mode of Payment</span><span class="val">${txn.mode == 'cash' ? 'Cash' : 'Bank Transfer'}</span></div>
        ${txn.utrNumber.isNotEmpty ? '<div class="row"><span class="label">UTR No. / Ref No.</span><span class="val">' + _escapeHtml(txn.utrNumber) + '</span></div>' : ''}
      ''');
    } else if (isVoucher) {
      detailsRows.write('''
        <div class="row"><span class="label">Paid To</span><span class="val">${_escapeHtml(txn.paidTo.isNotEmpty ? txn.paidTo : '—')}</span></div>
        <div class="row"><span class="label">Purpose</span><span class="val">${_escapeHtml(txn.remarks.isNotEmpty ? txn.remarks : '—')}</span></div>
        <div class="row"><span class="label">Paid From</span><span class="val">${txn.mode == 'cash' ? 'Cash' : 'Bank'}</span></div>
      ''');
    } else {
      detailsRows.write('''
        <div class="row"><span class="label">Transaction</span><span class="val">${txn.direction == 'deposit' ? 'Cash Deposited to Bank' : 'Cash Withdrawn from Bank'}</span></div>
        <div class="row"><span class="label">Remarks</span><span class="val">${_escapeHtml(txn.remarks.isNotEmpty ? txn.remarks : '—')}</span></div>
      ''');
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Tamil:wght@400;700&display=swap');
    body {
      font-family: 'Noto Sans Tamil', 'Segoe UI', Arial, sans-serif;
      margin: 0;
      padding: 20px;
      color: #1f2937;
      background: #ffffff;
    }
    .card {
      border: 2px solid #721c24;
      border-radius: 12px;
      padding: 24px;
      max-width: 480px;
      margin: 0 auto;
      box-shadow: 0 4px 6px rgba(0,0,0,0.05);
    }
    .header {
      text-align: center;
      margin-bottom: 16px;
    }
    .om {
      font-size: 32px;
      color: #721c24;
      line-height: 1;
      font-weight: bold;
    }
    .title {
      font-size: 22px;
      font-weight: bold;
      color: #721c24;
      margin: 6px 0 2px 0;
    }
    .subtitle {
      font-size: 12px;
      color: #6b7280;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .divider {
      border-bottom: 2px solid #721c24;
      margin: 14px 0;
    }
    .thin-divider {
      border-bottom: 1px solid #e5e7eb;
      margin: 10px 0;
    }
    .row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin: 8px 0;
      font-size: 13.5px;
    }
    .label {
      color: #4b5563;
      font-size: 13px;
    }
    .val {
      font-weight: bold;
      text-align: right;
      max-width: 65%;
      color: #111827;
      word-break: break-word;
    }
    .amount-box {
      text-align: center;
      background: #fdf3f3;
      border: 1px dashed #721c24;
      border-radius: 10px;
      padding: 14px;
      margin: 16px 0;
    }
    .amount {
      font-size: 28px;
      font-weight: bold;
      color: #721c24;
    }
    .words {
      font-size: 12px;
      font-style: italic;
      color: #6b7280;
      margin-top: 4px;
    }
    .footer {
      margin-top: 18px;
      font-size: 13px;
    }
    .sig-line {
      margin-top: 16px;
      color: #4b5563;
      font-size: 12.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="om">ௐ</div>
      <div class="title">Sembukutty Sastha Kovil</div>
      <div class="subtitle">${_escapeHtml(docTitle)}</div>
      <div class="divider"></div>
    </div>

    <div class="row">
      <span class="label">${txn.documentLabel} No.</span>
      <span class="val">${_escapeHtml(txn.serialNumber ?? '—')}</span>
    </div>
    <div class="row">
      <span class="label">Date & Time</span>
      <span class="val">${_escapeHtml(formattedDate)}</span>
    </div>

    <div class="thin-divider"></div>

    $detailsRows

    <div class="amount-box">
      <div class="amount">$amountFormatted</div>
      <div class="words">${_escapeHtml(amountInWords)}</div>
    </div>

    <div class="thin-divider"></div>

    <div class="row">
      <span class="label">Handled by</span>
      <span class="val">${_escapeHtml(staffName)}</span>
    </div>
    <div class="sig-line">Signature: ______________________</div>
  </div>
</body>
</html>
''';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generate PDF Uint8List bytes with proper Tamil complex script shaping
  static Future<Uint8List> generatePdf(TransactionModel txn, String staffName) async {
    final htmlString = generateHtml(txn, staffName);
    return await Printing.convertHtml(
      format: PdfPageFormat.a5,
      html: htmlString,
    );
  }

  /// Direct printing / PDF preview
  static Future<void> printOrShare(TransactionModel txn, String staffName) async {
    final htmlString = generateHtml(txn, staffName);
    await Printing.layoutPdf(
      onLayout: (format) async => await Printing.convertHtml(
        format: format,
        html: htmlString,
      ),
      name: '${txn.serialNumber ?? "doc"}.pdf',
    );
  }
}
