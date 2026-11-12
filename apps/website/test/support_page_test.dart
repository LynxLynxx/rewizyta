import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/constants/site.dart';
import 'package:rewizyta_website/pages/support_page.dart';

void main() {
  testComponents('answers the common questions', (tester) async {
    tester.pumpComponent(const SupportPage());

    // The footer links here with the same word.
    expect(find.descendant(of: find.tag('h1'), matching: find.text('Pomoc')), findsOneComponent);
    for (final heading in [
      'Kiedy aplikacja będzie dostępna?',
      'Nie dostałem e-maila z linkiem albo kodem',
      'Jak wypisać się z listy?',
      'Czy Rewizyta działa bez zasięgu?',
      'Kiedy klient dostaje SMS?',
      'Na jakich telefonach działa?',
      'Czy mogę wyeksportować klientów?',
      'Czy mogę postawić Rewizytę na własnym serwerze?',
      'Jak usunąć konto?',
    ]) {
      expect(find.text(heading), findsOneComponent, reason: heading);
    }
  });

  testComponents('gives the contact address and leads to account deletion', (tester) async {
    tester.pumpComponent(const SupportPage());

    expect(find.ancestor(of: find.text(contactEmail), matching: find.tag('a')), findsOneComponent);
    expect(find.ancestor(of: find.text('Usuwanie konta'), matching: find.tag('a')), findsOneComponent);
  });
}
