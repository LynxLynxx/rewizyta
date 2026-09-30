import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/site_page.dart';
import '../constants/theme.dart';

/// Pre-rendered to `404.html`, which the host serves for any path it does not
/// know (`not_found_handling` in `wrangler.jsonc`).
class NotFoundPage extends StatelessComponent {
  const NotFoundPage({super.key});

  @override
  Component build(BuildContext context) {
    return SitePage(indexed: false, [
      section(classes: 'container not-found', [
        h1([.text('Nie ma takiej strony')]),
        p([.text('Adres może być niepełny albo nieaktualny.')]),
        a(href: '/', [.text('Przejdź na stronę główną')]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.not-found', [
      css('&').styles(
        display: .flex,
        padding: .only(top: 48.px, bottom: 96.px),
        flexDirection: .column,
        alignItems: .start,
        gap: Gap(row: 14.px),
      ),
      css('h1').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(28px, 4vw, 38px)'),
        fontWeight: .w700,
        letterSpacing: (-0.02).em,
      ),
      css('p').styles(margin: .zero, color: Palette.text2, fontSize: 17.px),
      css('a').styles(fontSize: 16.px, fontWeight: .w500),
    ]),
  ];
}
