/// The entrypoint for the **server** environment: pre-renders every route at build time.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      lang: 'pl',
      meta: {
        'description':
            'Książka klientów w telefonie dla kominiarzy i serwisantów. Pamięta terminy przeglądów, '
            'sama wysyła klientom SMS i pokazuje kartę klienta, gdy dzwoni.',
        'theme-color': '#F6F4EF',
      },
      head: [
        // The header mark as the site icon: the SVG where it is supported, the ICO
        // (16, 32, 48) elsewhere, the PNG for iOS home screens. The `sizes` on the
        // ICO makes browsers that understand SVG prefer it.
        link(rel: 'icon', href: '/favicon.ico', attributes: {'sizes': '32x32'}),
        link(rel: 'icon', href: '/favicon.svg', type: 'image/svg+xml'),
        link(rel: 'apple-touch-icon', href: '/apple-touch-icon.png'),
        link(rel: 'stylesheet', href: '/styles.css'),
      ],
      body: const App(),
    ),
  );
}
