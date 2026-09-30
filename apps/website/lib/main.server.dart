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
        link(rel: 'stylesheet', href: '/styles.css'),
      ],
      body: const App(),
    ),
  );
}
