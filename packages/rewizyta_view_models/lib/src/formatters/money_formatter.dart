final _typedMoney = RegExp(r'^(\d{1,7})(?:[.,](\d{1,2}))?$');
final _currency = RegExp(r'\s|zł$', caseSensitive: false);

/// Reads a typed amount in złoty (`180`, `180,5`, `180.50`, `1 200 zł`) as
/// grosze, or null when it is not one.
int? parseMoney(String text) {
  final match = _typedMoney.firstMatch(text.trim().replaceAll(_currency, ''));
  if (match == null) return null;
  return int.parse(match[1]!) * 100 + int.parse((match[2] ?? '0').padRight(2, '0'));
}

/// Grosze as the złoty amount people write: `18000` → `180`, `18050` →
/// `180,50`. No currency: the label or the l10n string carries "zł".
String formatMoney(int grosze) {
  final zloty = grosze ~/ 100;
  final rest = grosze % 100;
  return rest == 0 ? '$zloty' : '$zloty,${'$rest'.padLeft(2, '0')}';
}
