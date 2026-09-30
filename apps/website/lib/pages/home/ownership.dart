import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';

/// Open source, self-hostable, exportable.
class Ownership extends StatelessComponent {
  const Ownership({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'section container', [
      div(classes: 'ownership', [
        h2([.text('Twoi klienci są Twoi.')]),
        p([
          .text(
            'Otwarty kod. Możesz postawić Rewizytę na własnym serwerze i w każdej chwili wyeksportować '
            'wszystkich klientów do pliku. Nie sprzedajemy danych i nie zamykamy ich u siebie.',
          ),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.ownership', [
      css('&').styles(
        display: .grid,
        padding: .all(24.px),
        border: .all(color: Palette.line, width: 1.px, style: .solid),
        radius: .circular(14.px),
        gap: Gap(row: 20.px, column: 32.px),
        raw: {'grid-template-columns': 'repeat(auto-fit, minmax(min(100%, 300px), 1fr))'},
      ),
      css('h2').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(24px, 3.2vw, 30px)'),
        fontWeight: .w700,
        letterSpacing: (-0.02).em,
        lineHeight: 1.15.em,
      ),
      css('p').styles(
        margin: .zero,
        color: Palette.text2,
        fontSize: 16.px,
        lineHeight: 1.55.em,
        raw: {'text-wrap': 'pretty'},
      ),
    ]),
  ];
}
