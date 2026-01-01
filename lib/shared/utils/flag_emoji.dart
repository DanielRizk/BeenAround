String flagEmojiFromIso2(String iso2) {
  final code = iso2.toUpperCase();
  if (code.length != 2) return '🏳️';

  final int a = code.codeUnitAt(0);
  final int b = code.codeUnitAt(1);

  // A-Z => 65..90
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';

  const int base = 0x1F1E6; // Regional Indicator Symbol Letter A
  final int first = base + (a - 65);
  final int second = base + (b - 65);

  return String.fromCharCode(first) + String.fromCharCode(second);
}