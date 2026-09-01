/// Convert an amount to Indian currency words.
/// e.g. 12500 → "Rupees Twelve Thousand Five Hundred Only"
const _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen'
];

const _tens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
  'Sixty', 'Seventy', 'Eighty', 'Ninety'
];

String _twoDigits(int n) {
  if (n < 20) return _ones[n];
  final t = _tens[n ~/ 10];
  final o = n % 10 == 0 ? '' : ' ${_ones[n % 10]}';
  return '$t$o';
}

String _threeDigits(int n) {
  if (n >= 100) {
    final h = '${_ones[n ~/ 100]} Hundred';
    final rest = n % 100;
    return rest == 0 ? h : '$h ${_twoDigits(rest)}';
  }
  return _twoDigits(n);
}

String amountToWords(double amount) {
  if (amount < 0) return 'Rupees Zero Only';

  int rupees = amount.truncate();
  int paise = ((amount - rupees) * 100).round();

  if (rupees == 0 && paise == 0) return 'Rupees Zero Only';

  final parts = <String>[];

  final crore = rupees ~/ 10000000;
  rupees %= 10000000;
  final lakh = rupees ~/ 100000;
  rupees %= 100000;
  final thousand = rupees ~/ 1000;
  rupees %= 1000;
  final remainder = rupees;

  if (crore > 0) parts.add('${_threeDigits(crore)} Crore');
  if (lakh > 0) parts.add('${_threeDigits(lakh)} Lakh');
  if (thousand > 0) parts.add('${_threeDigits(thousand)} Thousand');
  if (remainder > 0) parts.add(_threeDigits(remainder));

  final rupeeWords = parts.isEmpty ? 'Rupees Zero' : 'Rupees ${parts.join(' ')}';

  if (paise > 0) {
    return '$rupeeWords and ${_twoDigits(paise)} Paise Only';
  }
  return '$rupeeWords Only';
}
