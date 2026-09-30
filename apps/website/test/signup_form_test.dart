import 'package:jaspr_test/jaspr_test.dart';
import 'package:rewizyta_website/waitlist/signup_form.dart';
import 'package:rewizyta_website/waitlist/survey.dart';

Finder buttonWithText(String text) => find.ancestor(of: find.text(text), matching: find.tag('button'));

Future<void> answerEveryQuestion(ComponentTester tester) async {
  for (final question in survey) {
    await tester.click(buttonWithText(question.options.first.label));
    await tester.click(buttonWithText('Dalej'));
  }
}

void main() {
  testComponents('starts with the first question and its options', (tester) async {
    tester.pumpComponent(const SignupForm());

    expect(find.text('Pytanie 1 z ${survey.length}'), findsOneComponent);
    expect(find.text(survey.first.title), findsOneComponent);
    for (final option in survey.first.options) {
      expect(find.text(option.label), findsOneComponent);
    }
    expect(find.text('Wstecz'), findsNothing);
  });

  testComponents('"Dalej" waits for an answer, then moves on', (tester) async {
    tester.pumpComponent(const SignupForm());

    await tester.click(buttonWithText('Dalej'));
    expect(find.text(survey.first.title), findsOneComponent);

    await tester.click(buttonWithText('Kominiarz'));
    await tester.click(buttonWithText('Dalej'));
    expect(find.text(survey[1].title), findsOneComponent);
    expect(find.text('Pytanie 2 z ${survey.length}'), findsOneComponent);

    await tester.click(buttonWithText('Wstecz'));
    expect(find.text(survey.first.title), findsOneComponent);
  });

  testComponents('picking "Inne" opens a text field', (tester) async {
    tester.pumpComponent(const SignupForm());
    expect(find.tag('input'), findsNothing);

    await tester.click(buttonWithText('Inne'));

    expect(find.tag('input'), findsOneComponent);
  });

  testComponents('after the last question asks where to send the code', (tester) async {
    tester.pumpComponent(const SignupForm());

    await answerEveryQuestion(tester);

    expect(find.text('Ostatni krok'), findsOneComponent);
    expect(find.text('Gdzie wysłać kod?'), findsOneComponent);
    expect(find.text('Wyślij i odbierz kod'), findsOneComponent);
  });

  testComponents('sending an empty contact step shows the e-mail and consent errors instead of posting', (
    tester,
  ) async {
    tester.pumpComponent(const SignupForm());
    await answerEveryQuestion(tester);

    await tester.click(buttonWithText('Wyślij i odbierz kod'));

    expect(find.text('Sprawdź adres e-mail.'), findsOneComponent);
    expect(find.text('Zaznacz zgodę, żeby się zapisać.'), findsOneComponent);
    expect(find.text('Wysyłam…'), findsNothing);
  });
}
