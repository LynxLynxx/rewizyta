import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';

/// Three steps, on a white band.
class HowItWorks extends StatelessComponent {
  const HowItWorks({super.key});

  static const _steps = [
    (
      'Wpisujesz klientów',
      'Import z kontaktów albo wklej numer. Adres, urządzenia, notatki, co i kiedy zrobione.',
    ),
    (
      'Ustawiasz cykl',
      '12 miesięcy komin i gaz, 60 miesięcy pomiary. Terminy liczą się same, widzisz, kto wypada w tym miesiącu.',
    ),
    (
      'Klient sam dzwoni',
      'SMS 30 i 7 dni przed terminem, z Twoim numerem. Gdy dzwoni, widzisz jego kartę. Tylko umawiasz.',
    ),
  ];

  @override
  Component build(BuildContext context) {
    return section(classes: 'how', [
      div(classes: 'container how-inner', [
        h2(classes: 'section-title', [.text('Jak to działa')]),
        ol(classes: 'how-steps', [
          for (final (i, (title, body)) in _steps.indexed)
            li(classes: 'how-step', [
              span(classes: 'how-number', attributes: {'aria-hidden': 'true'}, [.text('${i + 1}')]),
              h3([.text(title)]),
              p([.text(body)]),
            ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.how').styles(
      border: .symmetric(
        vertical: .solid(color: Palette.line, width: 1.px),
      ),
      backgroundColor: Palette.white,
    ),
    css('.how-inner').styles(
      display: .flex,
      padding: .symmetric(vertical: 44.px),
      flexDirection: .column,
      gap: Gap(row: 28.px),
    ),
    css('.how-steps').styles(
      display: .grid,
      padding: .zero,
      margin: .zero,
      gap: Gap(row: 28.px, column: 28.px),
      listStyle: .none,
      raw: {'grid-template-columns': 'repeat(auto-fit, minmax(min(100%, 260px), 1fr))'},
    ),
    css('.how-step', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap(row: 8.px),
      ),
      css('h3').styles(margin: .zero, fontSize: 20.px, fontWeight: .w600),
      css('p').styles(margin: .zero, color: Palette.text2, fontSize: 16.px, lineHeight: 1.5.em),
    ]),
    css('.how-number').styles(color: Palette.accentText, fontFamily: monoFont, fontSize: 14.px),
  ];
}
