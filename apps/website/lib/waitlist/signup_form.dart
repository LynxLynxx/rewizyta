import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../constants/site.dart';
import '../constants/theme.dart';
import 'signup_flow.dart';
import 'waitlist_client.dart';

/// The survey, the contact step and the promo code, plus the sticky "sign up"
/// bar on phones. The one interactive part of the home page; everything else
/// is pre-rendered HTML.
@client
class SignupForm extends StatefulComponent {
  const SignupForm({super.key});

  /// The hero's call to action. While it or the form is on screen, the sticky bar hides.
  static const heroCtaId = 'zapisz-sie';

  /// The section that holds the form; every "sign up" link points here.
  static const sectionId = 'ankieta';

  @override
  State<SignupForm> createState() => SignupFormState();
}

class SignupFormState extends State<SignupForm> {
  final _client = WaitlistClient();

  SignupFlow _flow = const SignupFlow();
  bool _sending = false;
  SignupOutcome? _outcome;

  /// The address the last request went out with; the field may change meanwhile.
  String _submittedEmail = '';

  /// Null until "Skopiuj kod" is pressed; false when the browser refused the clipboard.
  bool? _copied;

  /// What a bot typed into the hidden decoy field; the server drops such sign-ups.
  String _decoy = '';

  bool _stickyVisible = false;
  web.IntersectionObserver? _observer;
  web.MediaQueryList? _narrow;
  JSFunction? _onNarrowChange;
  final _onScreen = <String, bool>{SignupForm.heroCtaId: true, SignupForm.sectionId: false};

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _watchStickyBar();
  }

  @override
  void dispose() {
    _observer?.disconnect();
    if (_onNarrowChange != null) _narrow?.removeEventListener('change', _onNarrowChange);
    super.dispose();
  }

  /// Shows the sticky bar on narrow screens once the hero's button has
  /// scrolled away, and hides it again at the form.
  void _watchStickyBar() {
    _narrow = web.window.matchMedia('(max-width: 720px)');
    _onNarrowChange = ((web.Event _) => _syncStickyBar()).toJS;
    _narrow!.addEventListener('change', _onNarrowChange);

    _observer = web.IntersectionObserver(
      ((JSArray<web.IntersectionObserverEntry> entries, web.IntersectionObserver _) {
        for (final entry in entries.toDart) {
          _onScreen[entry.target.id] = entry.isIntersecting;
        }
        _syncStickyBar();
      }).toJS,
    );
    for (final id in _onScreen.keys) {
      final element = web.document.getElementById(id);
      if (element != null) _observer!.observe(element);
    }
  }

  void _syncStickyBar() {
    final visible = (_narrow?.matches ?? false) && !_onScreen.values.any((v) => v);
    if (visible != _stickyVisible && mounted) setState(() => _stickyVisible = visible);
  }

  Future<void> _submit() async {
    // A second click lands before the rebuild disables the button; a second
    // request would find the new address and hide its promo code.
    if (_sending) return;
    if (!_flow.canContinue) {
      setState(() => _flow = _flow.next());
      return;
    }
    setState(() {
      _sending = true;
      _outcome = null;
      _submittedEmail = _flow.email.trim();
    });
    final outcome = await _client.signup(
      email: _submittedEmail,
      answers: _flow.answersJson,
      phone: _flow.phone,
      consent: _flow.consent,
      source: Uri.base.queryParameters['utm_source'] ?? Uri.base.queryParameters['ref'],
      decoy: _decoy,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _outcome = outcome;
    });
  }

  /// A server refusal of the e-mail or phone describes the old value, not the one being typed.
  void _clearServerError() {
    if (_outcome is SignupFailed) _outcome = null;
  }

  Future<void> _copyCode(String code) async {
    bool copied;
    try {
      await web.window.navigator.clipboard.writeText(code).toDart;
      copied = true;
    } catch (_) {
      // Permission refused, or no clipboard at all outside HTTPS.
      copied = false;
    }
    if (mounted) setState(() => _copied = copied);
  }

  bool get _done => _outcome is SignupCreated || _outcome is SignupKnown;

  @override
  Component build(BuildContext context) {
    return div(classes: 'signup-card', [
      if (!_done) _progress(),
      if (_done) _result() else if (_flow.isContact) _contact() else _question(),
      if (!_done) _nextButton(),
      if (_stickyVisible) _stickyBar(),
    ]);
  }

  Component _progress() {
    return div(classes: 'signup-progress', [
      div(classes: 'signup-progress-row', [
        span([.text(_flow.progressLabel)]),
        if (_flow.canGoBack)
          button(
            type: ButtonType.button,
            classes: 'signup-back',
            onClick: () => setState(() => _flow = _flow.back()),
            [.text('Wstecz')],
          ),
      ]),
      div(
        classes: 'signup-progress-track',
        attributes: {'aria-hidden': 'true'},
        [
          div(
            classes: 'signup-progress-bar',
            styles: Styles(width: Unit.percent((_flow.progress * 100).roundToDouble())),
            [],
          ),
        ],
      ),
    ]);
  }

  Component _question() {
    final question = _flow.question!;
    final selected = _flow.selected;
    return fieldset(classes: 'signup-step', [
      legend(classes: 'signup-heading', [
        h3([.text(question.title)]),
        span(classes: 'signup-hint', [.text(question.hint)]),
      ]),
      div(classes: 'signup-options', [
        for (final option in question.options)
          button(
            type: ButtonType.button,
            classes: 'signup-option',
            attributes: {
              'role': question.multi ? 'checkbox' : 'radio',
              'aria-checked': '${selected.contains(option.key)}',
            },
            onClick: () => setState(() => _flow = _flow.toggle(option.key)),
            [
              span(
                classes: 'signup-mark ${question.multi ? 'is-square' : 'is-round'}',
                attributes: {'aria-hidden': 'true'},
                [if (selected.contains(option.key)) .text('✓')],
              ),
              span([.text(option.label)]),
            ],
          ),
      ]),
      if (_flow.showsOther)
        input<String>(
          type: InputType.text,
          classes: 'signup-input',
          value: _flow.otherText,
          attributes: {'placeholder': 'Wpisz, co dokładnie', 'aria-label': 'Co dokładnie', 'maxlength': '200'},
          onInput: (value) => setState(() => _flow = _flow.withOtherText(value)),
        ),
    ]);
  }

  Component _contact() {
    final emailError =
        (_flow.showErrors && !_flow.emailValid) ||
        (_outcome is SignupFailed && (_outcome as SignupFailed).reason == SignupFailureReason.invalidEmail);
    final phoneError =
        (_flow.showErrors && !_flow.phoneValid) ||
        (_outcome is SignupFailed && (_outcome as SignupFailed).reason == SignupFailureReason.invalidPhone);
    final consentError = _flow.showErrors && !_flow.consent;

    return div(classes: 'signup-step', [
      div(classes: 'signup-heading', [
        h3([.text('Gdzie wysłać kod?')]),
        span(classes: 'signup-hint', [.text('Kod pokażemy też tutaj, od razu.')]),
      ]),
      label(classes: 'signup-field', [
        .text('E-mail'),
        input<String>(
          type: InputType.email,
          classes: 'signup-input${emailError ? ' has-error' : ''}',
          value: _flow.email,
          attributes: {
            'inputmode': 'email',
            'autocomplete': 'email',
            'placeholder': 'jan.kowalski@example.pl',
            'required': '',
            if (emailError) 'aria-invalid': 'true',
            if (emailError) 'aria-describedby': 'signup-email-error',
          },
          onInput: (value) => setState(() {
            _flow = _flow.withEmail(value);
            _clearServerError();
          }),
        ),
      ]),
      if (emailError)
        span(
          id: 'signup-email-error',
          classes: 'signup-error',
          attributes: {'role': 'alert'},
          [.text('Sprawdź adres e-mail.')],
        ),
      label(classes: 'signup-field', [
        span([
          .text('Telefon '),
          span(classes: 'signup-optional', [.text('— nieobowiązkowo')]),
        ]),
        input<String>(
          type: InputType.tel,
          classes: 'signup-input is-mono${phoneError ? ' has-error' : ''}',
          value: _flow.phone,
          attributes: {
            'inputmode': 'tel',
            'autocomplete': 'tel',
            'placeholder': '601 234 567',
            if (phoneError) 'aria-invalid': 'true',
            if (phoneError) 'aria-describedby': 'signup-phone-error',
          },
          onInput: (value) => setState(() {
            _flow = _flow.withPhone(value);
            _clearServerError();
          }),
        ),
        span(classes: 'signup-optional', [.text('Jeśli możemy oddzwonić na 10 minut rozmowy.')]),
      ]),
      if (phoneError)
        span(
          id: 'signup-phone-error',
          classes: 'signup-error',
          attributes: {'role': 'alert'},
          [.text('Sprawdź numer telefonu.')],
        ),
      label(classes: 'signup-consent${consentError ? ' has-error' : ''}', [
        input<bool>(
          type: InputType.checkbox,
          checked: _flow.consent,
          attributes: {
            if (consentError) 'aria-invalid': 'true',
            if (consentError) 'aria-describedby': 'signup-consent-error',
          },
          onChange: (value) => setState(() => _flow = _flow.withConsent(value)),
        ),
        span([.text('Zgadzam się na kontakt w sprawie Rewizyty. Mogę się wypisać w każdej chwili.')]),
      ]),
      if (consentError)
        span(
          id: 'signup-consent-error',
          classes: 'signup-error',
          attributes: {'role': 'alert'},
          [.text('Zaznacz zgodę, żeby się zapisać.')],
        ),
      // A decoy for bots. People never see it; a filled one is dropped by the server.
      div(
        classes: 'visually-hidden',
        attributes: {'aria-hidden': 'true'},
        [
          input<String>(
            type: InputType.text,
            name: 'website',
            attributes: {'tabindex': '-1', 'autocomplete': 'off'},
            onInput: (value) => _decoy = value,
          ),
        ],
      ),
      if (_outcome case SignupFailed(:final reason)
          when reason == SignupFailureReason.rateLimited || reason == SignupFailureReason.other)
        span(
          classes: 'signup-error',
          attributes: {'role': 'alert'},
          [
            .text(
              reason == SignupFailureReason.rateLimited
                  ? 'Za dużo prób naraz. Spróbuj ponownie za 10 minut.'
                  : 'Nie udało się wysłać. Sprawdź połączenie i spróbuj ponownie.',
            ),
          ],
        ),
      p(classes: 'signup-privacy', [
        .text(
          'Administratorem danych jest $controllerName. Używamy ich tylko do wysłania kodu '
          'i wiadomości o starcie. Możesz poprosić o ich usunięcie w każdej chwili. ',
        ),
        a(href: '/prywatnosc/', [.text('Polityka prywatności')]),
      ]),
    ]);
  }

  Component _nextButton() {
    final label = _sending ? 'Wysyłam…' : (_flow.isContact ? 'Wyślij i odbierz kod' : 'Dalej');
    return button(
      type: ButtonType.button,
      classes: 'signup-next${_flow.canContinue && !_sending ? ' is-ready' : ''}',
      disabled: _sending,
      onClick: _flow.isContact ? _submit : () => setState(() => _flow = _flow.next()),
      [.text(label)],
    );
  }

  Component _result() {
    final email = _submittedEmail;
    return div(
      classes: 'signup-step',
      attributes: {'role': 'status'},
      [
        switch (_outcome) {
          SignupCreated(:final promoCode, :final mail) => div(classes: 'signup-step', [
            h3(classes: 'signup-done-title', [.text('Dziękujemy! Potwierdź jeszcze adres e-mail.')]),
            div(classes: 'signup-code', [
              span(classes: 'signup-hint', [.text('Twój kod bonusowy')]),
              span(classes: 'signup-code-value', [.text(promoCode)]),
              span([.text('3 miesiące za darmo przy starcie.')]),
            ]),
            button(
              type: ButtonType.button,
              classes: 'signup-copy',
              onClick: () => _copyCode(promoCode),
              [.text(_copied == true ? 'Skopiowano' : 'Skopiuj kod')],
            ),
            if (_copied == false)
              p(
                classes: 'signup-note',
                attributes: {'role': 'alert'},
                [
                  .text('Nie udało się skopiować. Zaznacz kod powyżej i skopiuj go ręcznie.'),
                ],
              ),
            p(classes: 'signup-note', [
              .text(
                mail == MailDelivery.sent
                    ? 'Wysłaliśmy na $email link potwierdzający i ten sam kod. '
                          'Bez potwierdzenia nie napiszemy więcej.'
                    : 'E-mail z potwierdzeniem nie wyszedł. Zapisz kod i spróbuj ponownie za kwadrans.',
              ),
            ]),
          ]),
          SignupKnown(:final confirmed, :final mail) => div(classes: 'signup-step', [
            h3(classes: 'signup-done-title', [.text('Ten adres jest już na liście.')]),
            p(classes: 'signup-note', [
              .text(switch ((confirmed, mail)) {
                (true, MailDelivery.sent) => 'Wysłaliśmy na $email e-mail z Twoim kodem.',
                (false, MailDelivery.sent) => 'Wysłaliśmy na $email e-mail z linkiem potwierdzającym i kodem.',
                (_, MailDelivery.throttled) =>
                  'Wiadomość na ten adres wysłaliśmy niedawno. Jeśli jej nie ma, także w folderze spam, '
                      'spróbuj ponownie za kwadrans.',
                (_, MailDelivery.failed) => 'Nie udało się wysłać e-maila. Spróbuj ponownie za kwadrans.',
              }),
            ]),
          ]),
          _ => div([]),
        },
        p(classes: 'signup-note', [.text('Znasz kogoś z branży? Prześlij mu tę stronę.')]),
      ],
    );
  }

  Component _stickyBar() {
    return div(classes: 'signup-sticky', [
      a(href: '#${SignupForm.sectionId}', [.text('Zapisz się · 3 miesiące za darmo')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.signup-card', [
      css('&').styles(
        display: .flex,
        padding: .all(22.px),
        border: .all(color: Palette.line, width: 1.px, style: .solid),
        radius: .circular(14.px),
        flexDirection: .column,
        gap: Gap(row: 18.px),
        backgroundColor: Palette.white,
      ),
      css('h3').styles(margin: .zero, fontSize: 21.px, fontWeight: .w600, lineHeight: 1.25.em),
    ]),
    css('.signup-progress', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap(row: 8.px),
      ),
      css('.signup-progress-row').styles(
        display: .flex,
        justifyContent: .spaceBetween,
        color: Palette.muted,
        fontFamily: monoFont,
        fontSize: 13.px,
      ),
      css('.signup-back').styles(
        padding: .zero,
        border: .none,
        cursor: .pointer,
        color: Palette.ink,
        fontFamily: .inherit,
        fontSize: .inherit,
        textDecoration: TextDecoration(line: .underline),
        backgroundColor: Colors.transparent,
      ),
      css('.signup-progress-track').styles(
        height: 4.px,
        radius: .circular(2.px),
        overflow: .hidden,
        backgroundColor: Palette.lineLight,
      ),
      css('.signup-progress-bar').styles(height: 100.percent, backgroundColor: Palette.accent),
    ]),
    css('.signup-step').styles(
      display: .flex,
      minWidth: .zero,
      padding: .zero,
      margin: .zero,
      border: .none,
      flexDirection: .column,
      gap: Gap(row: 14.px),
    ),
    css('.signup-heading').styles(
      display: .flex,
      padding: .zero,
      flexDirection: .column,
      gap: Gap(row: 4.px),
      raw: {'text-wrap': 'pretty'},
    ),
    css('.signup-hint').styles(color: Palette.muted, fontSize: 14.px),
    css('.signup-options').styles(
      display: .flex,
      flexDirection: .column,
      gap: Gap(row: 8.px),
    ),
    css('.signup-option', [
      css('&').styles(
        display: .flex,
        minHeight: 50.px,
        padding: .symmetric(vertical: 10.px, horizontal: 14.px),
        border: .all(color: Palette.line, width: 1.5.px, style: .solid),
        radius: .circular(10.px),
        cursor: .pointer,
        alignItems: .center,
        gap: Gap(column: 12.px),
        color: Palette.ink,
        textAlign: .left,
        fontFamily: .inherit,
        fontSize: 16.px,
        backgroundColor: Palette.white,
      ),
      css('&[aria-checked="true"]').styles(
        border: .all(color: Palette.ink, width: 1.5.px, style: .solid),
        backgroundColor: Palette.accentSelected,
      ),
    ]),
    css('.signup-mark', [
      css('&').styles(
        width: 22.px,
        height: 22.px,
        border: .all(color: Palette.controlLine, width: 1.5.px, style: .solid),
        color: Palette.white,
        textAlign: .center,
        fontSize: 14.px,
        lineHeight: 19.px,
        backgroundColor: Palette.white,
        raw: {'flex': 'none'},
      ),
      css('&.is-square').styles(radius: .circular(5.px)),
      css('&.is-round').styles(radius: .circular(50.percent)),
    ]),
    css('.signup-option[aria-checked="true"] .signup-mark').styles(
      border: .all(color: Palette.ink, width: 1.5.px, style: .solid),
      backgroundColor: Palette.ink,
    ),
    css('.signup-input', [
      css('&').styles(
        minHeight: 52.px,
        padding: .symmetric(horizontal: 14.px),
        border: .all(color: Palette.controlLine, width: 1.5.px, style: .solid),
        radius: .circular(10.px),
        color: Palette.ink,
        fontFamily: .inherit,
        fontSize: 17.px,
        backgroundColor: Palette.white,
      ),
      css('&.is-mono').styles(fontFamily: monoFont),
      css('&.has-error').styles(
        border: .all(color: Palette.error, width: 1.5.px, style: .solid),
      ),
    ]),
    css('.signup-field').styles(
      display: .flex,
      flexDirection: .column,
      gap: Gap(row: 6.px),
      fontSize: 14.px,
      fontWeight: .w500,
    ),
    css('.signup-optional').styles(color: Palette.muted, fontWeight: .w400),
    css('.signup-error').styles(
      margin: .only(top: (-6).px),
      color: Palette.error,
      fontSize: 14.px,
    ),
    css('.signup-consent', [
      css('&').styles(
        display: .flex,
        cursor: .pointer,
        alignItems: .start,
        gap: Gap(column: 10.px),
        color: Palette.text2,
        fontSize: 14.px,
        lineHeight: 1.45.em,
      ),
      css('&.has-error').styles(color: Palette.error),
      css('input').styles(
        width: 20.px,
        height: 20.px,
        margin: .only(top: 1.px),
        raw: {'flex': 'none', 'accent-color': 'var(--ink)'},
      ),
    ]),
    css('.signup-privacy', [
      css('&').styles(margin: .zero, color: Palette.muted, fontSize: 13.px, lineHeight: 1.5.em),
      css('a').styles(color: Palette.text2),
    ]),
    css('.signup-next', [
      css('&').styles(
        minHeight: 54.px,
        border: .none,
        radius: .circular(10.px),
        cursor: .pointer,
        color: Palette.placeholder,
        fontFamily: .inherit,
        fontSize: 17.px,
        fontWeight: .w600,
        backgroundColor: Palette.lineLight,
      ),
      css('&.is-ready').styles(color: Palette.paper, backgroundColor: Palette.ink),
      css('&:disabled').styles(cursor: .wait),
    ]),
    css('.signup-done-title').styles(fontSize: 23.px),
    css('.signup-code').styles(
      display: .flex,
      padding: .all(18.px),
      border: .all(color: Palette.ink, width: 1.5.px, style: .dashed),
      radius: .circular(12.px),
      flexDirection: .column,
      alignItems: .start,
      gap: Gap(row: 6.px),
      color: Palette.text2,
      fontSize: 14.px,
      backgroundColor: Palette.paper,
    ),
    css('.signup-code-value').styles(
      color: Palette.ink,
      fontFamily: monoFont,
      // Fits REWI-XXXX-XXXX on one line down to a 320px screen.
      fontSize: Unit.expression('clamp(21px, 6.4vw, 30px)'),
      fontWeight: .w600,
      letterSpacing: 0.06.em,
      whiteSpace: .noWrap,
    ),
    css('.signup-copy').styles(
      minHeight: 50.px,
      border: .all(color: Palette.ink, width: 1.5.px, style: .solid),
      radius: .circular(10.px),
      cursor: .pointer,
      color: Palette.ink,
      fontFamily: .inherit,
      fontSize: 16.px,
      fontWeight: .w600,
      backgroundColor: Palette.white,
    ),
    css('.signup-note').styles(margin: .zero, color: Palette.muted, fontSize: 14.px, lineHeight: 1.5.em),
    css('.signup-sticky', [
      css('&').styles(
        position: .fixed(left: .zero, right: .zero, bottom: .zero),
        zIndex: ZIndex(10),
        padding: .only(top: 10.px, left: 16.px, right: 16.px),
        border: .only(
          top: .solid(color: Palette.line, width: 1.px),
        ),
        backgroundColor: Palette.white,
        raw: {'padding-bottom': 'calc(10px + env(safe-area-inset-bottom))'},
      ),
      css('a').styles(
        display: .flex,
        minHeight: 52.px,
        radius: .circular(10.px),
        justifyContent: .center,
        alignItems: .center,
        color: Palette.paper,
        fontSize: 17.px,
        fontWeight: .w600,
        textDecoration: TextDecoration(line: .none),
        backgroundColor: Palette.ink,
      ),
    ]),
  ];
}
