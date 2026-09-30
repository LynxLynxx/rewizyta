import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'site_footer.dart';
import 'site_header.dart';

/// Header, the page's content and the footer: the frame every route shares.
class SitePage extends StatelessComponent {
  const SitePage(this.children, {this.indexed = true, super.key});

  /// False for pages only a mail link leads to; they tell search engines to skip them.
  final bool indexed;

  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div([
      if (!indexed) const Document.head(meta: {'robots': 'noindex'}),
      const SiteHeader(),
      main_(children),
      const SiteFooter(),
    ]);
  }
}
