import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/pages/not_found_page.dart';

void main() {
  testComponents('says the page does not exist and leads home', (tester) async {
    tester.pumpComponent(const NotFoundPage());

    expect(find.text('Nie ma takiej strony'), findsOneComponent);
    expect(find.ancestor(of: find.text('Przejdź na stronę główną'), matching: find.tag('a')), findsOneComponent);
  });
}
