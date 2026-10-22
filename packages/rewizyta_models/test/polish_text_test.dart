import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:test/test.dart';

void main() {
  test('comparePolish sorts in Polish dictionary order', () {
    final names = ['Żak', 'Zając', 'Łukasik', 'Lis', 'Ćwik', 'Cichy', 'Ślusarz', 'Sowa', 'adam']
      ..sort(comparePolish);

    expect(names, ['adam', 'Cichy', 'Ćwik', 'Lis', 'Łukasik', 'Sowa', 'Ślusarz', 'Zając', 'Żak']);
  });

  test('comparePolish ignores case until it breaks a tie', () {
    expect(comparePolish('anna', 'Bartek'), lessThan(0));
    expect(comparePolish('Anna', 'anna'), lessThan(0));
    expect(comparePolish('Anna', 'Anna'), 0);
  });

  test('comparePolish puts a prefix and digits first', () {
    expect(comparePolish('Nowak', 'Nowakowski'), lessThan(0));
    expect(comparePolish('2 Bracia', 'Adam'), lessThan(0));
  });

  test('foldPolish lowers the case and drops the diacritics', () {
    expect(foldPolish('Łódź Ąę Ćń Śź Ż'), 'lodz ae cn sz z');
  });
}
