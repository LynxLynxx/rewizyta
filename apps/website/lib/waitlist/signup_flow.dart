import 'survey.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Where the visitor is and what they have entered: one step per question,
/// then the contact step. Immutable; every change returns a new flow.
/// The server checks everything again (`waitlist-signup`), so these checks
/// are for the visitor's sake only.
class SignupFlow {
  const SignupFlow({
    this.step = 0,
    this.answers = const {},
    this.otherTexts = const {},
    this.email = '',
    this.phone = '',
    this.consent = false,
    this.showErrors = false,
  });

  /// `0 ..< survey.length` are the questions, [contactStep] the contact form.
  final int step;
  final Map<String, List<String>> answers;
  final Map<String, String> otherTexts;
  final String email;
  final String phone;
  final bool consent;

  /// Set once the visitor tried to send an incomplete contact step.
  final bool showErrors;

  static int get contactStep => survey.length;

  bool get isContact => step == contactStep;

  SurveyQuestion? get question => isContact ? null : survey[step];

  List<String> get selected => answers[question?.key] ?? const [];

  bool get showsOther {
    final q = question;
    return q?.otherKey != null && selected.contains(q!.otherKey);
  }

  String get otherText => otherTexts[question?.key] ?? '';

  bool get emailValid => _emailPattern.hasMatch(email.trim());

  /// Loose on purpose: nine digits for Polish numbers, up to fifteen with a
  /// country code. The server does the real E.164 normalisation.
  bool get phoneValid {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.trim().isEmpty || (digits.length >= 9 && digits.length <= 15);
  }

  bool get canContinue => isContact ? emailValid && phoneValid && consent : selected.isNotEmpty;

  bool get canGoBack => step > 0;

  String get progressLabel => isContact ? 'Ostatni krok' : 'Pytanie ${step + 1} z ${survey.length}';

  /// 0 before the first answer, 1 when the contact step is sent.
  double get progress => step / (survey.length + 1);

  SignupFlow toggle(String option) {
    final q = question!;
    final current = selected;
    final next = q.multi
        ? (current.contains(option) ? current.where((o) => o != option).toList() : [...current, option])
        : [option];
    return _copy(answers: {...answers, q.key: next});
  }

  SignupFlow withOtherText(String text) => _copy(otherTexts: {...otherTexts, question!.key: text});

  SignupFlow withEmail(String value) => _copy(email: value);

  SignupFlow withPhone(String value) => _copy(phone: value);

  SignupFlow withConsent(bool value) => _copy(consent: value);

  SignupFlow next() {
    if (isContact) return _copy(showErrors: true);
    if (!canContinue) return this;
    return _copy(step: step + 1);
  }

  SignupFlow back() => canGoBack ? _copy(step: step - 1, showErrors: false) : this;

  /// The survey as `waitlist-signup` expects it: option keys, a list for
  /// multiple choice, the free text as `<question>_other` when "other" is picked.
  Map<String, Object> get answersJson {
    final json = <String, Object>{};
    for (final q in survey) {
      final picked = answers[q.key];
      if (picked == null || picked.isEmpty) continue;
      json[q.key] = q.multi ? picked : picked.single;
      final other = otherTexts[q.key]?.trim() ?? '';
      if (q.otherKey != null && picked.contains(q.otherKey) && other.isNotEmpty) {
        json['${q.key}_other'] = other;
      }
    }
    return json;
  }

  SignupFlow _copy({
    int? step,
    Map<String, List<String>>? answers,
    Map<String, String>? otherTexts,
    String? email,
    String? phone,
    bool? consent,
    bool? showErrors,
  }) {
    return SignupFlow(
      step: step ?? this.step,
      answers: answers ?? this.answers,
      otherTexts: otherTexts ?? this.otherTexts,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      consent: consent ?? this.consent,
      showErrors: showErrors ?? this.showErrors,
    );
  }
}
