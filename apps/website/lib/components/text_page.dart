import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import 'site_page.dart';

/// A page of prose: a title, a few lines under it and titled sections. The
/// frame of the privacy notice, the support page and the account deletion page.
class TextPage extends StatelessComponent {
  const TextPage({
    required this.title,
    required this.description,
    required this.intro,
    required this.sections,
    super.key,
  });

  final String title;

  /// The meta description.
  final String description;

  /// Paragraphs under the title.
  final List<Component> intro;

  /// Usually [textSection]s.
  final List<Component> sections;

  @override
  Component build(BuildContext context) {
    return SitePage([
      Document.head(meta: {'description': description}),
      article(classes: 'container text-page', [
        header(classes: 'text-page-header', [
          h1([.text(title)]),
          ...intro,
        ]),
        ...sections,
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.text-page', [
      css('&').styles(
        display: .flex,
        padding: .only(top: 32.px, bottom: 72.px),
        flexDirection: .column,
        gap: Gap(row: 32.px),
      ),
      css('section, .text-page-header').styles(
        display: .flex,
        maxWidth: 44.em,
        flexDirection: .column,
        gap: Gap(row: 12.px),
      ),
      css('h1').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(30px, 4.4vw, 42px)'),
        fontWeight: .w700,
        letterSpacing: (-0.02).em,
        lineHeight: 1.1.em,
      ),
      css('h2').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(21px, 2.6vw, 24px)'),
        fontWeight: .w600,
        lineHeight: 1.25.em,
      ),
      css('p, li').styles(
        color: Palette.text2,
        fontSize: 16.px,
        lineHeight: 1.6.em,
        raw: {'text-wrap': 'pretty'},
      ),
      css('p').styles(margin: .zero),
      css('ul').styles(
        display: .flex,
        padding: .only(left: 20.px),
        margin: .zero,
        flexDirection: .column,
        gap: Gap(row: 8.px),
      ),
      css('strong').styles(color: Palette.ink, fontWeight: .w600),
    ]),
    css('.text-page .text-page-date').styles(color: Palette.muted, fontFamily: monoFont, fontSize: 14.px),
  ];
}

/// A titled section of a [TextPage].
Component textSection(String title, List<Component> children) {
  return section([
    h2([.text(title)]),
    ...children,
  ]);
}

/// A list item that leads with what, in bold, then says why.
Component textItem(String what, String why) {
  return li([
    strong([.text(what)]),
    .text(' – $why'),
  ]);
}
