import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'constants/theme.dart';
import 'pages/home/home_page.dart';
import 'pages/mail_page.dart';
import 'pages/not_found_page.dart';
import 'pages/privacy_page.dart';
import 'waitlist/confirm_action.dart';
import 'waitlist/unsubscribe_action.dart';

/// The site's routes. Every route is pre-rendered to its own HTML file.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(
          path: '/',
          title: 'Rewizyta – terminy przeglądów i przypomnienia SMS dla serwisantów',
          builder: (context, state) => const HomePage(),
        ),
        // The mail pages and the privacy notice keep these paths after launch:
        // every mail already sent links to them.
        Route(
          path: '/potwierdz',
          title: 'Potwierdź zapis – Rewizyta',
          builder: (context, state) => const MailPage(ConfirmAction()),
        ),
        Route(
          path: '/wypisz',
          title: 'Wypisz się – Rewizyta',
          builder: (context, state) => const MailPage(UnsubscribeAction()),
        ),
        Route(
          path: '/prywatnosc',
          title: 'Polityka prywatności – Rewizyta',
          builder: (context, state) => const PrivacyPage(),
        ),
        // Built as a file of its own (the path has an extension); the host
        // serves it for every unknown path.
        Route(
          path: '/404.html',
          title: 'Nie ma takiej strony – Rewizyta',
          builder: (context, state) => const NotFoundPage(),
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.container').styles(
      width: 100.percent,
      maxWidth: pageMaxWidth,
      padding: .symmetric(horizontal: pagePadding),
      margin: .symmetric(horizontal: .auto),
    ),
  ];
}
