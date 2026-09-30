import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';
import '../../waitlist/signup_form.dart';

/// The promise, the call to action and a phone showing the client card on an
/// incoming call.
class Hero extends StatelessComponent {
  const Hero({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'hero container', [
      div(classes: 'hero-text', [
        div(classes: 'hero-kicker', [.text('DLA KOMINIARZY, SERWISANTÓW I INSPEKTORÓW')]),
        h1([.text('Klient dzwoni. Ty już wiesz, kiedy u niego byłeś.')]),
        p(classes: 'hero-lead', [
          .text(
            'Książka klientów w telefonie. Pamięta każdy termin przeglądu, sama wysyła klientom SMS '
            'przed wizytą i pokazuje historię, gdy klient dzwoni. Działa w kotłowni, w piwnicy, bez zasięgu.',
          ),
        ]),
        div(classes: 'hero-actions', [
          a(href: '#${SignupForm.sectionId}', id: SignupForm.heroCtaId, classes: 'button-primary', [
            .text('Zapisz się na listę'),
          ]),
          span(classes: 'hero-offer', [
            strong([.text('3 miesiące za darmo')]),
            .text(' na start · 7 krótkich pytań'),
            br(),
            span(classes: 'hero-launch', [.text('Start aplikacji: wiosna 2027')]),
          ]),
        ]),
      ]),
      div(classes: 'hero-phone-slot', [const IncomingCallCard()]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.hero').styles(
      display: .flex,
      padding: .only(top: 16.px, bottom: 56.px),
      flexDirection: .row,
      flexWrap: .wrap,
      justifyContent: .center,
      alignItems: .center,
      gap: Gap(row: 40.px, column: 40.px),
    ),
    css('.hero-text', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .start,
        gap: Gap(row: 22.px),
        flex: Flex(grow: 1, shrink: 1, basis: 420.px),
      ),
      css('h1').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(36px, 6vw, 58px)'),
        fontWeight: .w700,
        letterSpacing: (-0.025).em,
        lineHeight: 1.04.em,
        raw: {'text-wrap': 'balance'},
      ),
    ]),
    css('.hero-kicker').styles(
      color: Palette.muted,
      fontFamily: monoFont,
      fontSize: 13.px,
      letterSpacing: 0.02.em,
    ),
    css('.hero-lead').styles(
      maxWidth: 34.em,
      margin: .zero,
      color: Palette.text2,
      fontSize: 19.px,
      lineHeight: 1.5.em,
      raw: {'text-wrap': 'pretty'},
    ),
    css('.hero-actions').styles(
      display: .flex,
      flexWrap: .wrap,
      alignItems: .center,
      gap: Gap(row: 14.px, column: 14.px),
    ),
    css('.hero-offer', [
      css('&').styles(color: Palette.text2, fontSize: 15.px, lineHeight: 1.45.em),
      css('strong').styles(color: Palette.ink, fontWeight: .w600),
    ]),
    css('.hero-launch').styles(color: Palette.muted),
    css('.hero-phone-slot').styles(
      display: .flex,
      justifyContent: .center,
      flex: Flex(grow: 0, shrink: 1, basis: 340.px),
    ),
    css('.button-primary').styles(
      display: .inlineFlex,
      minHeight: 54.px,
      padding: .symmetric(horizontal: 26.px),
      radius: .circular(10.px),
      justifyContent: .center,
      alignItems: .center,
      color: Palette.paper,
      fontSize: 17.px,
      fontWeight: .w600,
      textDecoration: TextDecoration(line: .none),
      backgroundColor: Palette.ink,
    ),
    css('.button-primary:hover').styles(color: Palette.paper),
  ];
}

/// A phone on an incoming call with the caller's client card. Illustration
/// only: the name and address are made up, the number is the repo's fixture.
class IncomingCallCard extends StatelessComponent {
  const IncomingCallCard({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'phone',
      attributes: {
        'role': 'img',
        'aria-label':
            'Połączenie przychodzące, a na ekranie karta klienta: adres, urządzenia, ostatnie wizyty i notatka.',
      },
      [
        div(classes: 'phone-screen', [
          div(classes: 'phone-status', [
            span([.text('9:41')]),
            span([.text('brak zasięgu')]),
          ]),
          div(classes: 'phone-caller', [
            span(classes: 'phone-caller-label', [.text('Połączenie przychodzące')]),
            span(classes: 'phone-caller-name', [.text('Henryk Wiśniewski')]),
            span(classes: 'phone-caller-number', [.text('601 234 567')]),
          ]),
          div(classes: 'client-card', [
            div(classes: 'client-card-top', [
              span(classes: 'client-card-title', [.text('KARTA KLIENTA')]),
              span(classes: 'client-card-due', [.text('przegląd za 12 dni')]),
            ]),
            div(classes: 'client-card-address', [.text('ul. Leśna 12, Nowy Targ')]),
            div(classes: 'client-card-tags', [
              span(classes: 'tag', [.text('2 × komin')]),
              span(classes: 'tag', [.text('kocioł gazowy')]),
            ]),
            div(classes: 'client-card-visits', [
              for (final (date, note) in [
                ('14.10.2025', 'Czyszczenie przewodów, protokół. 180 zł.'),
                ('09.10.2024', 'Czyszczenie, wymiana wkładu.'),
              ])
                div(classes: 'client-card-visit', [
                  span(classes: 'client-card-date', [.text(date)]),
                  span([.text(note)]),
                ]),
            ]),
            div(classes: 'client-card-note', [.text('Pies na podwórku. Wejście od garażu.')]),
          ]),
          div(classes: 'phone-buttons', [
            for (final (label, modifier) in [('Odrzuć', 'is-decline'), ('Odbierz', 'is-answer')])
              div(classes: 'phone-button', [
                div(classes: 'phone-button-circle $modifier', []),
                span([.text(label)]),
              ]),
          ]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.phone').styles(
      width: 100.percent,
      maxWidth: 340.px,
      padding: .all(10.px),
      radius: .circular(40.px),
      shadow: BoxShadow(
        offsetX: .zero,
        offsetY: 30.px,
        blur: 60.px,
        spread: (-30).px,
        color: const Color.rgba(29, 28, 26, 0.45),
      ),
      backgroundColor: Palette.ink,
    ),
    css('.phone-screen').styles(
      display: .flex,
      radius: .circular(31.px),
      overflow: .hidden,
      flexDirection: .column,
      backgroundColor: Palette.ink2,
    ),
    css('.phone-status').styles(
      display: .flex,
      padding: .only(top: 14.px, left: 24.px, right: 24.px),
      justifyContent: .spaceBetween,
      color: Palette.onDarkMuted,
      fontFamily: monoFont,
      fontSize: 12.px,
    ),
    css('.phone-caller').styles(
      display: .flex,
      padding: .only(top: 22.px, left: 20.px, right: 20.px, bottom: 16.px),
      flexDirection: .column,
      gap: Gap(row: 4.px),
      textAlign: .center,
    ),
    css('.phone-caller-label').styles(color: Palette.onDarkMuted, fontSize: 13.px),
    css('.phone-caller-name').styles(color: Palette.paper, fontSize: 24.px, fontWeight: .w600),
    css('.phone-caller-number').styles(color: Palette.onDarkMuted, fontFamily: monoFont, fontSize: 14.px),
    css('.client-card').styles(
      display: .flex,
      padding: .all(16.px),
      margin: .symmetric(horizontal: 12.px),
      radius: .circular(18.px),
      flexDirection: .column,
      gap: Gap(row: 12.px),
      textAlign: .left,
      backgroundColor: Palette.white,
    ),
    css('.client-card-top').styles(
      display: .flex,
      justifyContent: .spaceBetween,
      alignItems: .center,
      gap: Gap(column: 8.px),
    ),
    css('.client-card-title').styles(
      color: Palette.muted,
      fontSize: 12.px,
      fontWeight: .w600,
      letterSpacing: 0.04.em,
    ),
    css('.client-card-due').styles(
      padding: .symmetric(vertical: 3.px, horizontal: 8.px),
      radius: .circular(5.px),
      color: Palette.accentOnBg,
      fontSize: 12.px,
      fontWeight: .w600,
      backgroundColor: Palette.accentBg,
    ),
    css('.client-card-address').styles(fontSize: 15.px, lineHeight: 1.35.em),
    css('.client-card-tags').styles(
      display: .flex,
      flexWrap: .wrap,
      gap: Gap(row: 6.px, column: 6.px),
    ),
    css('.tag').styles(
      padding: .symmetric(vertical: 4.px, horizontal: 8.px),
      border: .all(color: Palette.line, width: 1.px, style: .solid),
      radius: .circular(5.px),
      fontSize: 13.px,
    ),
    css('.client-card-visits').styles(
      display: .flex,
      padding: .only(top: 10.px),
      border: .only(
        top: .solid(color: Palette.lineLight, width: 1.px),
      ),
      flexDirection: .column,
      gap: Gap(row: 8.px),
    ),
    css('.client-card-visit').styles(
      display: .grid,
      gap: Gap(column: 8.px),
      fontSize: 14.px,
      lineHeight: 1.35.em,
      raw: {'grid-template-columns': '78px 1fr'},
    ),
    css('.client-card-date').styles(
      padding: .only(top: 2.px),
      color: Palette.muted,
      fontFamily: monoFont,
      fontSize: 12.px,
    ),
    css('.client-card-note').styles(
      padding: .symmetric(vertical: 8.px, horizontal: 10.px),
      radius: .circular(8.px),
      fontSize: 14.px,
      lineHeight: 1.4.em,
      backgroundColor: Palette.paper,
    ),
    css('.phone-buttons').styles(
      display: .flex,
      padding: .only(top: 20.px, bottom: 24.px),
      justifyContent: .spaceAround,
    ),
    css('.phone-button').styles(
      display: .flex,
      flexDirection: .column,
      alignItems: .center,
      gap: Gap(row: 6.px),
      color: Palette.onDarkMuted,
      fontSize: 12.px,
    ),
    css('.phone-button-circle', [
      css('&').styles(width: 58.px, height: 58.px, radius: .circular(50.percent)),
      css('&.is-decline').styles(backgroundColor: Palette.decline),
      css('&.is-answer').styles(backgroundColor: Palette.ok),
    ]),
  ];
}
