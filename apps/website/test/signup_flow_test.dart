import 'package:rewizyta_website/waitlist/signup_flow.dart';
import 'package:rewizyta_website/waitlist/survey.dart';
import 'package:test/test.dart';

/// A flow with every question answered by its first option, standing on the contact step.
SignupFlow answeredFlow() {
  var flow = const SignupFlow();
  for (final question in survey) {
    flow = flow.toggle(question.options.first.key).next();
  }
  return flow;
}

void main() {
  group('questions', () {
    test('start at the first question and cannot continue without an answer', () {
      const flow = SignupFlow();

      expect(flow.question, same(survey.first));
      expect(flow.progressLabel, 'Pytanie 1 z ${survey.length}');
      expect(flow.canContinue, isFalse);
      expect(flow.canGoBack, isFalse);
      expect(flow.next(), same(flow));
    });

    test('multiple choice toggles options on and off', () {
      final flow = const SignupFlow().toggle('chimney').toggle('gas').toggle('chimney');

      expect(flow.selected, ['gas']);
      expect(flow.canContinue, isTrue);
    });

    test('single choice keeps only the last pick', () {
      final flow = const SignupFlow().toggle('chimney').next().toggle('under_50').toggle('over_500');

      expect(flow.selected, ['over_500']);
    });

    test('the text field opens only for "other"', () {
      final flow = const SignupFlow().toggle('chimney');
      expect(flow.showsOther, isFalse);

      final withOther = flow.toggle('other').withOtherText('szamba');
      expect(withOther.showsOther, isTrue);
      expect(withOther.otherText, 'szamba');
    });

    test('back keeps the answers', () {
      final flow = const SignupFlow().toggle('gas').next().back();

      expect(flow.step, 0);
      expect(flow.selected, ['gas']);
    });

    test('progress runs from 0 to the contact step', () {
      expect(const SignupFlow().progress, 0);
      expect(answeredFlow().progress, closeTo(survey.length / (survey.length + 1), 1e-9));
    });
  });

  group('contact step', () {
    test('follows the last question', () {
      final flow = answeredFlow();

      expect(flow.isContact, isTrue);
      expect(flow.question, isNull);
      expect(flow.progressLabel, 'Ostatni krok');
    });

    test('needs a valid e-mail and the consent; the phone is optional', () {
      final flow = answeredFlow();
      expect(flow.canContinue, isFalse);

      expect(flow.withEmail('jan@example').canContinue, isFalse);
      expect(flow.withEmail(' jan@example.pl ').canContinue, isFalse);
      expect(flow.withEmail(' jan@example.pl ').withConsent(true).canContinue, isTrue);
      expect(flow.withEmail('jan@example.pl').withConsent(true).withPhone('601 234').canContinue, isFalse);
      expect(flow.withEmail('jan@example.pl').withConsent(true).withPhone('601 234 567').canContinue, isTrue);
    });

    test('an incomplete attempt turns the errors on and stays put', () {
      final flow = answeredFlow().next();

      expect(flow.isContact, isTrue);
      expect(flow.showErrors, isTrue);
      expect(flow.back().showErrors, isFalse);
    });
  });

  test('answers are sent as option keys, lists for multiple choice, "other" text only with "other"', () {
    final flow = const SignupFlow()
        .toggle('chimney')
        .toggle('other')
        .withOtherText('  szamba ')
        .next()
        .toggle('50_200')
        .next()
        .toggle('android')
        .next()
        .toggle('notebook')
        .withOtherText('ignored: "other" is not picked');

    expect(flow.answersJson, {
      'trade': ['chimney', 'other'],
      'trade_other': 'szamba',
      'clients': '50_200',
      'platform': 'android',
      'records': ['notebook'],
    });
  });
}
