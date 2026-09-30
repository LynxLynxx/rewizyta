import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/waitlist/confirm_action.dart';
import 'package:rewizyta_website/waitlist/mail_action.dart';
import 'package:rewizyta_website/waitlist/unsubscribe_action.dart';

void main() {
  group('mailToken', () {
    const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz0123456789-_AbCdE';

    test('reads the token from the fragment the mail links carry', () {
      expect(mailToken('t=$token'), token);
      expect(mailToken('utm_source=x&t=$token'), token);
    });

    test('refuses a link cut short or tampered with', () {
      expect(mailToken(''), isNull);
      expect(mailToken('t='), isNull);
      expect(mailToken('t=${token.substring(1)}'), isNull);
      expect(mailToken('t=${token}x'), isNull);
      expect(mailToken('t=${token.replaceFirst('A', '+')}'), isNull);
      expect(mailToken('token=$token'), isNull);
    });
  });

  // Pre-rendering (and the VM) has no fragment: the page ships with the button,
  // and the browser checks the link once it runs.
  testComponents('the confirm page offers the confirm button', (tester) async {
    tester.pumpComponent(const ConfirmAction());

    expect(find.text('Potwierdź zapis na listę'), findsOneComponent);
    expect(find.ancestor(of: find.text('Potwierdzam zapis'), matching: find.tag('button')), findsOneComponent);
  });

  testComponents('the unsubscribe page offers the unsubscribe button', (tester) async {
    tester.pumpComponent(const UnsubscribeAction());

    expect(find.text('Wypisz się z listy'), findsOneComponent);
    expect(find.ancestor(of: find.text('Wypisz mnie'), matching: find.tag('button')), findsOneComponent);
  });
}
