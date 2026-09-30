import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/site_page.dart';

/// `/potwierdz/` and `/wypisz/`: pages only a mail link leads to, each one
/// card with one button ([action]). Kept out of search results.
class MailPage extends StatelessComponent {
  const MailPage(this.action, {super.key});

  final Component action;

  @override
  Component build(BuildContext context) {
    return SitePage(indexed: false, [
      section(classes: 'container mail-page', [action]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.mail-page').styles(
      padding: .only(top: 32.px, bottom: 72.px),
    ),
  ];
}
