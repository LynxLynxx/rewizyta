import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';

/// The trades Rewizyta is for.
class Audience extends StatelessComponent {
  const Audience({super.key});

  static const _trades = [
    'Kominiarze',
    'Przeglądy gazowe',
    'Kotły i pompy ciepła',
    'Klimatyzacja',
    'Wywóz szamb',
    'Filtry wody',
    'Alarmy i gaśnice',
    'Pomiary elektryczne',
  ];

  @override
  Component build(BuildContext context) {
    return section(classes: 'section container audience', [
      h2(classes: 'section-label', [.text('Dla kogo')]),
      ul(classes: 'audience-trades', [
        for (final trade in _trades) li(classes: 'audience-trade', [.text(trade)]),
      ]),
      p(classes: 'audience-note', [
        .text('Jedna osoba, kilkaset stałych klientów, którzy wracają co rok albo co pięć lat.'),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.audience').styles(gap: Gap(row: 12.px)),
    css('.audience-trades').styles(
      display: .flex,
      padding: .zero,
      margin: .zero,
      flexWrap: .wrap,
      gap: Gap(row: 8.px, column: 8.px),
      listStyle: .none,
    ),
    css('.audience-trade').styles(
      padding: .symmetric(vertical: 8.px, horizontal: 12.px),
      border: .all(color: Palette.line, width: 1.px, style: .solid),
      radius: .circular(5.px),
      fontSize: 16.px,
      backgroundColor: Palette.white,
    ),
    css('.audience-note').styles(
      maxWidth: 44.em,
      margin: .zero,
      color: Palette.text2,
      fontSize: 17.px,
      lineHeight: 1.55.em,
      raw: {'text-wrap': 'pretty'},
    ),
  ];
}
