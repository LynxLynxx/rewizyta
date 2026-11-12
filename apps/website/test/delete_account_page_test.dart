import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/constants/site.dart';
import 'package:rewizyta_website/pages/delete_account_page.dart';

void main() {
  testComponents('covers what the Play deletion URL asks for', (tester) async {
    tester.pumpComponent(const DeleteAccountPage());

    expect(find.descendant(of: find.tag('h1'), matching: find.text('Usuwanie konta')), findsOneComponent);
    for (final heading in [
      'Usuń konto w aplikacji',
      'Bez aplikacji: napisz do nas',
      'Co usuwamy',
      'Co zostaje i jak długo',
      'Chcesz usunąć tylko część danych?',
    ]) {
      expect(find.text(heading), findsOneComponent, reason: heading);
    }
  });

  testComponents('names the developer and how to ask by e-mail', (tester) async {
    tester.pumpComponent(const DeleteAccountPage());

    expect(find.textContaining(controllerName), findsOneComponent);
    expect(find.ancestor(of: find.text(contactEmail), matching: find.tag('a')), findsOneComponent);
  });

  testComponents('states how long deletion and backups take', (tester) async {
    tester.pumpComponent(const DeleteAccountPage());

    expect(find.textContaining('w ciągu miesiąca'), findsOneComponent);
    // Backups and the partial deletion.
    expect(find.textContaining('30 dni'), findsNComponents(2));
  });
}
