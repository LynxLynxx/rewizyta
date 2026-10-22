/// The Polish alphabet plus q, v and x in their Latin places. SQLite's
/// `ORDER BY` compares code units and puts Ł, Ś and Ż after Z.
const _alphabet = 'aąbcćdeęfghijklłmnńoópqrsśtuvwxyzźż';

const _folds = {
  'ą': 'a',
  'ć': 'c',
  'ę': 'e',
  'ł': 'l',
  'ń': 'n',
  'ó': 'o',
  'ś': 's',
  'ź': 'z',
  'ż': 'z',
};

/// Compares names in Polish dictionary order, case-insensitively first and by
/// case only to break a tie. Digits and punctuation sort before letters,
/// letters outside the alphabet (é, ü) after ż.
int comparePolish(String a, String b) {
  final byLetters = _compareRanks(a.toLowerCase(), b.toLowerCase());
  return byLetters != 0 ? byLetters : a.compareTo(b);
}

/// Lower case without Polish diacritics, so a search for "lodz" finds "Łódź".
String foldPolish(String value) =>
    value.toLowerCase().split('').map((char) => _folds[char] ?? char).join();

int _compareRanks(String a, String b) {
  final x = a.runes.toList();
  final y = b.runes.toList();
  for (var i = 0; i < x.length && i < y.length; i++) {
    final diff = _rank(x[i]) - _rank(y[i]);
    if (diff != 0) return diff;
  }
  return x.length - y.length;
}

int _rank(int rune) {
  final index = _alphabet.indexOf(String.fromCharCode(rune));
  if (index >= 0) return 0x110000 + index;
  return rune < 0x80 ? rune : 0x120000 + rune;
}
