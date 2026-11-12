import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/text_page.dart';
import '../constants/site.dart';

/// `/pomoc/`: the FAQ and the contact address (the App Store "Support URL").
/// Pre-launch wording; rewritten for the shipped app at launch.
class SupportPage extends StatelessComponent {
  const SupportPage({super.key});

  @override
  Component build(BuildContext context) {
    return TextPage(
      title: 'Pomoc',
      description: 'Odpowiedzi na częste pytania o Rewizytę i adres, pod który możesz napisać.',
      intro: [
        p([
          .text(
            'Aplikacja jeszcze nie wystartowała, więc odpowiadamy tu na pytania o listę oczekujących '
            'i o to, jak Rewizyta będzie działać.',
          ),
        ]),
        p([
          .text('Pytanie, problem albo pomysł? Napisz na '),
          a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
          .text('.'),
        ]),
      ],
      sections: [
        textSection('Kiedy aplikacja będzie dostępna?', [
          p([
            .text(
              'Start planujemy wiosną 2027. Jeśli zapisałeś się na listę, dostaniesz wtedy jeden e-mail. '
              'Bez newslettera.',
            ),
          ]),
        ]),
        textSection('Nie dostałem e-maila z linkiem albo kodem', [
          p([
            .text(
              'Sprawdź folder Spam i zakładkę Oferty. Kod był też na ekranie zaraz po zapisie. Jeśli nic '
              'nie przyszło, napisz do nas z adresu podanego przy zapisie.',
            ),
          ]),
        ]),
        textSection('Jak wypisać się z listy?', [
          p([
            .text(
              'Kliknij link „Wypisz się” w dowolnym e-mailu od nas albo napisz do nas. Twoje dane '
              'usuniemy po 30 dniach; zostanie tylko skrót adresu, dzięki któremu nie napiszemy '
              'do Ciebie ponownie.',
            ),
          ]),
        ]),
        textSection('Czy Rewizyta działa bez zasięgu?', [
          p([
            .text(
              'Tak, także w kotłowni i w piwnicy. Wszystko zapisuje się w telefonie, a gdy wróci zasięg, '
              'aplikacja sama wyśle zmiany. Internetu potrzeba tylko do kilku rzeczy, np. do eksportu '
              'danych i usunięcia konta.',
            ),
          ]),
        ]),
        textSection('Kiedy klient dostaje SMS?', [
          p([
            .text(
              'Domyślnie 30 i 7 dni przed terminem przeglądu (możesz to zmienić), z Twoim numerem '
              'w treści, więc klient dzwoni prosto '
              'do Ciebie. SMS-y wysyła nasz serwer, więc wychodzą też wtedy, gdy Twój telefon jest '
              'wyłączony.',
            ),
          ]),
        ]),
        textSection('Na jakich telefonach działa?', [
          p([.text('Na start na telefonach z Androidem; wersję na iPhone’a planujemy później.')]),
        ]),
        textSection('Czy mogę wyeksportować klientów?', [
          p([.text('Tak, w każdej chwili, do pliku, w ustawieniach aplikacji.')]),
        ]),
        textSection('Czy mogę postawić Rewizytę na własnym serwerze?', [
          p([.text('Tak. Kod jest otwarty; możesz uruchomić własny serwer i nie korzystać z naszego.')]),
        ]),
        textSection('Jak usunąć konto?', [
          p([
            .text('W aplikacji albo e-mailem, bez instalowania jej ponownie. Wszystko opisujemy na stronie '),
            a(href: '/usun-konto/', [.text('Usuwanie konta')]),
            .text('.'),
          ]),
        ]),
      ],
    );
  }
}
