import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/site_page.dart';
import '../../constants/site.dart';
import '../../constants/theme.dart';
import 'audience.dart';
import 'comparison.dart';
import 'hero.dart';
import 'how_it_works.dart';
import 'ownership.dart';
import 'signup_section.dart';

/// The waitlist home page. Pre-rendered; only the sign-up form runs in the browser.
class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) {
    return SitePage([
      Document.head(
        children: [
          for (final (property, content) in [
            ('og:title', 'Klient dzwoni. Ty już wiesz, kiedy u niego byłeś.'),
            ('og:description', siteDescription),
            ('og:url', '$siteUrl/'),
          ])
            meta(attributes: {'property': property, 'content': content}),
        ],
      ),
      const Hero(),
      const HowItWorks(),
      const Audience(),
      const Comparison(),
      const Ownership(),
      const SignupSection(),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.section').styles(
      display: .flex,
      padding: .only(top: 44.px, bottom: 8.px),
      flexDirection: .column,
      gap: Gap(row: 20.px),
    ),
    css('.section-title').styles(
      margin: .zero,
      fontSize: Unit.expression('clamp(26px, 3.6vw, 34px)'),
      fontWeight: .w700,
      letterSpacing: (-0.02).em,
      lineHeight: 1.1.em,
    ),
    css('.section-label').styles(
      margin: .zero,
      color: Palette.muted,
      fontSize: 14.px,
      fontWeight: .w600,
    ),
  ];
}
