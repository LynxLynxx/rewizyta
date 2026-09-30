import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';

/// Notebook and spreadsheet against Rewizyta, one situation per row.
class Comparison extends StatelessComponent {
  const Comparison({super.key});

  static const _rows = [
    (
      'Przypomnienie dla klienta',
      'Nie ma. Klient zapomina, idzie do kogoś innego.',
      'SMS 30 i 7 dni przed terminem, z Twoim numerem.',
    ),
    (
      'Klient dzwoni',
      'Szukasz w zeszycie albo pytasz, kiedy byłeś.',
      'Karta z historią na ekranie, zanim odbierzesz.',
    ),
    ('Kto w tym miesiącu', 'Przeglądanie stron i kolumn.', 'Jedna lista: termin w tym miesiącu.'),
    ('Piwnica bez zasięgu', 'Excel w domu na komputerze.', 'Wszystko w telefonie, synchronizacja później.'),
  ];

  @override
  Component build(BuildContext context) {
    return section(classes: 'section container', [
      h2(classes: 'section-title', [.text('Zeszyt i Excel kontra Rewizyta')]),
      table(classes: 'comparison', [
        thead([
          tr([
            th(attributes: {'scope': 'col'}, [.text('ZESZYT / EXCEL')]),
            th(attributes: {'scope': 'col'}, [.text('REWIZYTA')]),
          ]),
        ]),
        for (final (situation, before, after) in _rows)
          tbody([
            tr(classes: 'comparison-situation', [
              th(attributes: {'scope': 'rowgroup', 'colspan': '2'}, [.text(situation)]),
            ]),
            tr(classes: 'comparison-values', [
              td(classes: 'comparison-before', [.text(before)]),
              td([.text(after)]),
            ]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.comparison', [
      css('&').styles(
        width: 100.percent,
        border: .all(color: Palette.line, width: 1.px, style: .solid),
        radius: .circular(14.px),
        overflow: .hidden,
        backgroundColor: Palette.white,
        raw: {'border-collapse': 'separate', 'border-spacing': '0', 'table-layout': 'fixed'},
      ),
      css('th, td').styles(
        padding: .zero,
        textAlign: .left,
        fontSize: 15.px,
        fontWeight: .w400,
        lineHeight: 1.45.em,
        raw: {'vertical-align': 'top'},
      ),
      css('thead th').styles(
        padding: .only(top: 12.px, bottom: 12.px, left: 16.px),
        border: .only(
          bottom: .solid(color: Palette.line, width: 1.px),
        ),
        color: Palette.muted,
        fontSize: 13.px,
        fontWeight: .w600,
        letterSpacing: 0.03.em,
      ),
      css('thead th:last-child').styles(
        padding: .only(right: 16.px, left: 12.px),
      ),
      css('.comparison-situation th').styles(
        padding: .only(top: 14.px, left: 16.px, right: 16.px, bottom: 8.px),
        fontWeight: .w600,
      ),
      css('.comparison-values td').styles(
        padding: .only(bottom: 14.px, left: 16.px, right: 6.px),
        border: .only(
          bottom: .solid(color: Palette.lineLight, width: 1.px),
        ),
      ),
      css('.comparison-values td:last-child').styles(
        padding: .only(bottom: 14.px, left: 6.px, right: 16.px),
      ),
      css('tbody:last-child .comparison-values td').styles(border: .none),
    ]),
    css('.comparison-before').styles(color: Palette.muted),
  ];
}
