/// Displays an E.164 number the Polish way: `+48601234567` → `601 234 567`.
/// Foreign numbers keep their prefix: `+4915112345678` → `+49 151 123 456 78`.
String formatPhone(String e164) {
  if (e164.startsWith('+48') && e164.length == 12) {
    final digits = e164.substring(3);
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }
  final buffer = StringBuffer();
  for (var i = 0; i < e164.length; i++) {
    if (i > 2 && (i - 3) % 3 == 0) buffer.write(' ');
    buffer.write(e164[i]);
  }
  return buffer.toString();
}
