import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../waitlist/signup_form.dart';

/// Logo and the "sign up" link.
class SiteHeader extends StatelessComponent {
  const SiteHeader({super.key});

  @override
  Component build(BuildContext context) {
    return header(classes: 'site-header container', [
      a(href: '/', classes: 'site-logo', [
        span(classes: 'site-logo-mark', attributes: {'aria-hidden': 'true'}, [span([])]),
        span([.text('Rewizyta')]),
      ]),
      // From the home page itself this only scrolls; from any other page it goes home first.
      a(href: '/#${SignupForm.sectionId}', classes: 'site-header-link', [.text('Zapisz się')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.site-header').styles(
      display: .flex,
      padding: .symmetric(vertical: 18.px),
      justifyContent: .spaceBetween,
      alignItems: .center,
      gap: Gap(column: 12.px),
    ),
    css('.site-logo', [
      css('&').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap(column: 10.px),
        color: Palette.ink,
        fontSize: 19.px,
        fontWeight: .w700,
        textDecoration: TextDecoration(line: .none),
        letterSpacing: (-0.01).em,
      ),
      css('.site-logo-mark').styles(
        display: .grid,
        width: 28.px,
        height: 28.px,
        radius: .circular(6.px),
        backgroundColor: Palette.ink,
        raw: {'place-items': 'center'},
      ),
      css('.site-logo-mark span').styles(
        width: 10.px,
        height: 10.px,
        radius: .circular(50.percent),
        backgroundColor: Palette.accent,
      ),
    ]),
    css('.site-header-link').styles(fontSize: 15.px, fontWeight: .w500),
  ];
}
