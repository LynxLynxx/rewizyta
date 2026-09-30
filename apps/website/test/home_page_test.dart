import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/pages/home/home_page.dart';
import 'package:rewizyta_website/waitlist/signup_form.dart';

void main() {
  testComponents('renders every section of the waitlist page', (tester) async {
    tester.pumpComponent(const HomePage());

    for (final heading in [
      'Klient dzwoni. Ty już wiesz, kiedy u niego byłeś.',
      'Jak to działa',
      'Dla kogo',
      'Zeszyt i Excel kontra Rewizyta',
      'Twoi klienci są Twoi.',
      'Czym Rewizyta nie jest',
    ]) {
      expect(find.text(heading), findsOneComponent, reason: heading);
    }
    expect(
      find.descendant(of: find.tag('h2'), matching: find.text('Zapisz się na listę')),
      findsOneComponent,
    );
    expect(find.byType(SignupForm), findsOneComponent);
  });

  testComponents('the phone illustration uses the fixture number only', (tester) async {
    tester.pumpComponent(const HomePage());

    expect(find.text('601 234 567'), findsOneComponent);
  });
}
