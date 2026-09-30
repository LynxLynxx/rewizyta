import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';

/// What Rewizyta is not, and the privacy link.
class SiteFooter extends StatelessComponent {
  const SiteFooter({super.key});

  @override
  Component build(BuildContext context) {
    return footer(classes: 'site-footer', [
      div(classes: 'container site-footer-inner', [
        strong([.text('Czym Rewizyta nie jest')]),
        span([
          .text(
            'Nie giełdą zleceń, nie CRM-em, nie programem do faktur, nie narzędziem dla firm z zespołem. '
            'Jedna osoba, jeden telefon, jedno zadanie: żeby żaden klient nie przepadł.',
          ),
        ]),
        a(href: '/prywatnosc/', classes: 'site-footer-privacy', [.text('Polityka prywatności')]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.site-footer').styles(
      border: .only(
        top: .solid(color: Palette.line, width: 1.px),
      ),
    ),
    css('.site-footer-inner', [
      css('&').styles(
        display: .flex,
        padding: .only(top: 32.px, bottom: 48.px),
        flexDirection: .column,
        gap: Gap(row: 6.px),
        color: Palette.text2,
        fontSize: 15.px,
        lineHeight: 1.55.em,
      ),
      css('strong').styles(color: Palette.ink, fontWeight: .w600),
      css('span').styles(maxWidth: 44.em),
    ]),
    css('.site-footer-privacy').styles(
      margin: .only(top: 12.px),
      alignSelf: .start,
      color: Palette.muted,
      fontSize: 14.px,
    ),
  ];
}
