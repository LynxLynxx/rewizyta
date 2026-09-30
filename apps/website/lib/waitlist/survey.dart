/// One answer a visitor can pick. [key] is what the server stores; [label] is
/// what the page shows, so rewording a label does not split the answers.
class SurveyOption {
  const SurveyOption(this.key, this.label);

  final String key;
  final String label;
}

class SurveyQuestion {
  const SurveyQuestion({
    required this.key,
    required this.title,
    required this.hint,
    required this.options,
    this.multi = false,
    this.otherKey,
  });

  final String key;
  final String title;
  final String hint;
  final List<SurveyOption> options;

  /// Several options may be picked.
  final bool multi;

  /// The option that opens a free-text field, sent as `<key>_other`.
  final String? otherKey;
}

/// The waitlist questions. Keys and option keys must match
/// `supabase/functions/_shared/waitlist/survey.ts`, which refuses anything else.
const survey = [
  SurveyQuestion(
    key: 'trade',
    title: 'Jaką usługę wykonujesz?',
    hint: 'Można zaznaczyć kilka.',
    multi: true,
    otherKey: 'other',
    options: [
      SurveyOption('chimney', 'Kominiarz'),
      SurveyOption('gas', 'Gaz, kotły'),
      SurveyOption('hvac', 'Klimatyzacja, pompy ciepła'),
      SurveyOption('other', 'Inne'),
    ],
  ),
  SurveyQuestion(
    key: 'clients',
    title: 'Ilu masz stałych klientów?',
    hint: 'Mniej więcej.',
    options: [
      SurveyOption('under_50', 'Mniej niż 50'),
      SurveyOption('50_200', '50–200'),
      SurveyOption('200_500', '200–500'),
      SurveyOption('over_500', 'Ponad 500'),
    ],
  ),
  SurveyQuestion(
    key: 'platform',
    title: 'Jakiego telefonu używasz w pracy?',
    hint: 'Od tego zależy, na który zrobimy aplikację najpierw.',
    options: [
      SurveyOption('android', 'Android (Samsung, Xiaomi, Motorola i inne)'),
      SurveyOption('iphone', 'iPhone'),
      SurveyOption('both', 'Mam oba'),
    ],
  ),
  SurveyQuestion(
    key: 'records',
    title: 'Gdzie trzymasz dane klientów?',
    hint: 'Można zaznaczyć kilka.',
    multi: true,
    otherKey: 'other_app',
    options: [
      SurveyOption('notebook', 'Zeszyt'),
      SurveyOption('spreadsheet', 'Excel'),
      SurveyOption('phone_contacts', 'Kontakty w telefonie'),
      SurveyOption('kiedyserwis', 'KiedySerwis'),
      SurveyOption('other_app', 'Inny program'),
    ],
  ),
  SurveyQuestion(
    key: 'reminders',
    title: 'Jak przypominasz klientom o kolejnej wizycie?',
    hint: 'Wybierz jedno.',
    options: [
      SurveyOption('none', 'Nie przypominam'),
      SurveyOption('call', 'Dzwonię'),
      SurveyOption('manual_sms', 'Wysyłam SMS ręcznie'),
      SurveyOption('automatic', 'Automatycznie'),
    ],
  ),
  SurveyQuestion(
    key: 'lost_clients',
    title: 'Ilu klientów rocznie przepada, bo nikt nie przypomniał?',
    hint: 'Wybierz jedno.',
    options: [
      SurveyOption('none', 'Żaden'),
      SurveyOption('few', 'Kilku'),
      SurveyOption('a_dozen_or_more', 'Kilkunastu lub więcej'),
      SurveyOption('unknown', 'Nie wiem'),
    ],
  ),
  SurveyQuestion(
    key: 'would_pay',
    title:
        'Czy zapłacisz 39 zł/mies. za aplikację, która sama wysyła przypomnienia '
        'i pokazuje kartę klienta, gdy dzwoni?',
    hint: 'Szczerze — to nam najbardziej pomoże.',
    options: [
      SurveyOption('yes', 'Tak'),
      SurveyOption('maybe', 'Może'),
      SurveyOption('no', 'Nie'),
    ],
  ),
];
