import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/constants/site.dart';
import 'package:rewizyta_website/pages/privacy_page.dart';

void main() {
  testComponents('covers what GDPR art. 13 asks for', (tester) async {
    tester.pumpComponent(const PrivacyPage());

    // The footer links here with the same words.
    expect(find.descendant(of: find.tag('h1'), matching: find.text('Polityka prywatności')), findsOneComponent);
    for (final heading in [
      'Kto odpowiada za Twoje dane',
      'Co zbieramy, po co i na jakiej podstawie',
      'Czego nie robimy',
      'Komu powierzamy dane',
      'Jak długo przechowujemy dane',
      'Twoje prawa',
      'Czy musisz podać dane',
    ]) {
      expect(find.text(heading), findsOneComponent, reason: heading);
    }
  });

  testComponents('names every company that processes the data', (tester) async {
    tester.pumpComponent(const PrivacyPage());

    for (final processor in ['Supabase Inc. (USA)', 'Brevo (Francja)', 'Cloudflare, Inc. (USA)']) {
      expect(find.text(processor), findsOneComponent, reason: processor);
    }
  });

  testComponents('names the controller and how to reach them', (tester) async {
    tester.pumpComponent(const PrivacyPage());

    expect(find.textContaining(controllerName), findsOneComponent);
    expect(find.textContaining('NIP $controllerTaxId'), findsOneComponent);
    expect(find.ancestor(of: find.text(contactEmail), matching: find.tag('a')), findsOneComponent);
  });
}
