final _typedMoney = RegExp(r'^(\d{1,7})(?:[.,](\d{1,2}))?$');
final _currency = RegExp(r'\s|zł$', caseSensitive: false);

/// Reads a typed amount in złoty (`180`, `180,5`, `180.50`, `1 200 zł`) as
/// grosze, or null when it is not one.
int? parseMoney(String text) {
  final match = _typedMoney.firstMatch(text.trim().replaceAll(_currency, ''));
  if (match == null) return null;
  return int.parse(match[1]!) * 100 + int.parse((match[2] ?? '0').padRight(2, '0'));
}
