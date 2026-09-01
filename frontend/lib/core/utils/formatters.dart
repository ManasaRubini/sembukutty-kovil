import 'package:intl/intl.dart';

final _inrFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final _inrFormatterDecimal = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String formatINR(double amount) => _inrFormatter.format(amount);
String formatINRDecimal(double amount) => _inrFormatterDecimal.format(amount);

String formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '—';
  try {
    final d = DateTime.parse(isoDate);
    return DateFormat('d MMM yyyy').format(d);
  } catch (_) {
    return isoDate;
  }
}

String formatDateTime(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal());
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

String firstOfMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
}
