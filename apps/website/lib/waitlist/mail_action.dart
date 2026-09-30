import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/site.dart';
import '../constants/theme.dart';
import 'signup_form.dart';
import 'waitlist_client.dart';

final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// The token a waitlist mail puts in its link's fragment (`#t=…`), or null
/// when the link arrived cut short. Same shape as `_shared/waitlist/tokens.ts`.
String? mailToken(String fragment) {
  for (final part in fragment.split('&')) {
    final token = part.startsWith('t=') ? part.substring(2) : null;
    if (token != null && _tokenPattern.hasMatch(token)) return token;
  }
  return null;
}

/// What a mail link asks the reader to do. Each has its own `@client`
/// component (`ConfirmAction`, `UnsubscribeAction`), because Jaspr allows one
/// per library; both run [MailActionState].
enum MailAction { confirm, unsubscribe }

enum _Phase { ready, sending, failed, done, invalid, noToken }

typedef _Copy = ({String title, String text, ({String label, String href})? link});

/// One button that posts the mail's token, then what the server said. Runs in
/// the browser because the token rides in the fragment, which never reaches a
/// server. Mail links never act by themselves: link scanners open every URL
/// in a message and would confirm or unsubscribe on the reader's behalf.
class MailActionState<T extends StatefulComponent> extends State<T> {
  MailActionState(this.action);

  final MailAction action;
  final _client = WaitlistClient();

  String? _token;
  _Phase _phase = _Phase.ready;

  @override
  void initState() {
    super.initState();
    // Pre-rendering has no fragment and shows the button; the browser then checks the link.
    if (kIsWeb) {
      _token = mailToken(Uri.base.fragment);
      if (_token == null) _phase = _Phase.noToken;
    }
  }

  Future<void> _send() async {
    final token = _token;
    // A second click lands before the rebuild disables the button.
    if (token == null || _phase == _Phase.sending) return;
    setState(() => _phase = _Phase.sending);
    final outcome = await switch (action) {
      MailAction.confirm => _client.confirm(token),
      MailAction.unsubscribe => _client.unsubscribe(token),
    };
    if (!mounted) return;
    setState(
      () => _phase = switch (outcome) {
        TokenOutcome.done => _Phase.done,
        TokenOutcome.invalid => _Phase.invalid,
        TokenOutcome.failed => _Phase.failed,
      },
    );
  }

  bool get _showsButton => _phase == _Phase.ready || _phase == _Phase.sending || _phase == _Phase.failed;

  static const _signupAgain = (label: 'Zapisz się ponownie', href: '/#${SignupForm.sectionId}');

  _Copy get _copy => switch ((action, _phase)) {
    (_, _Phase.noToken) => (
      title: 'Link jest niepełny',
      text:
          'Otwórz go jeszcze raz z wiadomości. Jeśli to nie pomoże, skopiuj cały adres z wiadomości '
          'do paska przeglądarki.',
      link: null,
    ),
    (MailAction.confirm, _Phase.done) => (
      title: 'Adres potwierdzony. Dziękujemy!',
      text:
          'Napiszemy, gdy Rewizyta będzie gotowa. Zachowaj kod z wiadomości: wpiszesz go w aplikacji '
          'i dostaniesz 3 miesiące za darmo.',
      link: null,
    ),
    (MailAction.confirm, _Phase.invalid) => (
      title: 'Ten link już nie działa',
      text:
          'Jeśli adres jest już potwierdzony, nic więcej nie trzeba robić. Jeśli nie, zapisz się '
          'jeszcze raz tym samym adresem, a wyślemy nowy link.',
      link: _signupAgain,
    ),
    (MailAction.confirm, _) => (
      title: 'Potwierdź zapis na listę',
      text: 'Jedno kliknięcie. Bez potwierdzenia nie napiszemy do Ciebie, także gdy Rewizyta wystartuje.',
      link: null,
    ),
    (MailAction.unsubscribe, _Phase.done) => (
      title: 'Wypisano',
      text: 'Nie napiszemy już na ten adres. Dane z listy usuniemy po 30 dniach.',
      link: (label: 'Zmiana zdania? Zapisz się ponownie', href: _signupAgain.href),
    ),
    (MailAction.unsubscribe, _Phase.invalid) => (
      title: 'Nie znaleźliśmy tego adresu',
      text:
          'Dane mogły zostać już usunięte. Jeśli mimo to dostajesz od nas wiadomości, '
          'napisz na $contactEmail.',
      link: null,
    ),
    (MailAction.unsubscribe, _) => (
      title: 'Wypisz się z listy',
      text: 'Po kliknięciu nie wyślemy na ten adres żadnej wiadomości, także tej o starcie aplikacji.',
      link: null,
    ),
  };

  String get _buttonLabel => switch ((action, _phase == _Phase.sending)) {
    (MailAction.confirm, false) => 'Potwierdzam zapis',
    (MailAction.confirm, true) => 'Potwierdzam…',
    (MailAction.unsubscribe, false) => 'Wypisz mnie',
    (MailAction.unsubscribe, true) => 'Wypisuję…',
  };

  @override
  Component build(BuildContext context) {
    final copy = _copy;
    return div(classes: 'mail-card', [
      h1([.text(copy.title)]),
      div(
        classes: 'mail-card-status',
        attributes: {'role': 'status'},
        [
          p([.text(copy.text)]),
          if (_phase == _Phase.failed)
            p(classes: 'mail-card-error', [.text('Nie udało się. Sprawdź połączenie i spróbuj ponownie.')]),
        ],
      ),
      if (_showsButton)
        button(
          type: ButtonType.button,
          classes: 'mail-card-button',
          disabled: _phase == _Phase.sending,
          onClick: _send,
          [.text(_buttonLabel)],
        ),
      if (copy.link case final link?) a(href: link.href, classes: 'mail-card-link', [.text(link.label)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.mail-card', [
      css('&').styles(
        display: .flex,
        maxWidth: 560.px,
        padding: .all(28.px),
        border: .all(color: Palette.line, width: 1.px, style: .solid),
        radius: .circular(14.px),
        flexDirection: .column,
        gap: Gap(row: 18.px),
        backgroundColor: Palette.white,
      ),
      css('h1').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(26px, 4vw, 32px)'),
        fontWeight: .w700,
        letterSpacing: (-0.02).em,
        lineHeight: 1.15.em,
      ),
      css('p').styles(
        margin: .zero,
        color: Palette.text2,
        fontSize: 17.px,
        lineHeight: 1.5.em,
        raw: {'text-wrap': 'pretty'},
      ),
    ]),
    css('.mail-card-status').styles(
      display: .flex,
      flexDirection: .column,
      gap: Gap(row: 10.px),
    ),
    css('.mail-card .mail-card-error').styles(color: Palette.error, fontSize: 15.px),
    css('.mail-card-button', [
      css('&').styles(
        minHeight: 54.px,
        border: .none,
        radius: .circular(10.px),
        cursor: .pointer,
        color: Palette.paper,
        fontFamily: .inherit,
        fontSize: 17.px,
        fontWeight: .w600,
        backgroundColor: Palette.ink,
      ),
      css('&:disabled').styles(cursor: .wait),
    ]),
    css('.mail-card-link').styles(alignSelf: .start, fontSize: 16.px, fontWeight: .w500),
  ];
}
