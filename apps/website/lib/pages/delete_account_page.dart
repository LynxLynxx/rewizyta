import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/text_page.dart';
import '../constants/site.dart';

/// `/usun-konto/`: how to delete the account in the app and by e-mail without
/// reinstalling it (the Play Data safety "Delete account URL"). What it
/// promises must match `docs/TRD.md`, "Account export and deletion".
class DeleteAccountPage extends StatelessComponent {
  const DeleteAccountPage({super.key});

  @override
  Component build(BuildContext context) {
    return TextPage(
      title: 'Usuwanie konta',
      description:
          'Jak usunąć konto w Rewizycie: w aplikacji albo e-mailem, bez instalowania jej ponownie. '
          'Co usuwamy, co zostaje i jak długo.',
      intro: [
        p([.text('Dotyczy konta w aplikacji Rewizyta, którą tworzy firma $controllerName.')]),
        p([
          .text(
            'Start aplikacji planujemy wiosną 2027. Do tego czasu nie ma kont, a ta strona opisuje, jak '
            'będzie wyglądało ich usuwanie.',
          ),
        ]),
        p([
          .text(
            'Jesteś tylko na liście oczekujących? To nie konto: wypisz się linkiem z dowolnego e-maila od nas.',
          ),
        ]),
      ],
      sections: [
        textSection('Usuń konto w aplikacji', [
          p([.text('Więcej → Ustawienia → Usuń konto. Potrzebny jest internet.')]),
          p([
            .text(
              'Aplikacja najpierw zaproponuje eksport danych, potem poprosi o ponowne zalogowanie '
              'i potwierdzenie.',
            ),
          ]),
          p([.text('Konto usuwamy od razu i tego nie da się cofnąć, więc najpierw zrób eksport.')]),
        ]),
        textSection('Bez aplikacji: napisz do nas', [
          p([
            .text('Napisz na '),
            a(href: 'mailto:$contactEmail?subject=${Uri.encodeComponent('Usuń konto')}', [.text(contactEmail)]),
            .text(
              ' (temat: Usuń konto) i podaj adres e-mail, na który założone jest konto. '
              'Nie musisz instalować aplikacji.',
            ),
          ]),
          p([
            .text(
              'Żeby nikt nie usunął konta za Ciebie, wyślemy na adres konta prośbę o potwierdzenie. '
              'Nie prosimy o hasło ani dokumenty.',
            ),
          ]),
          p([
            .text(
              'Gdy odpowiesz z tego adresu, usuniemy konto tak samo jak aplikacja i napiszemy, że gotowe. '
              'Zrobimy to najpóźniej w ciągu miesiąca od Twojej wiadomości.',
            ),
          ]),
        ]),
        textSection('Co usuwamy', [
          ul([
            li([.text('Wszystkie dane konta: profil, klientów, urządzenia, wizyty, terminy wizyt i historię SMS-ów.')]),
            li([.text('Zaplanowane SMS-y: żaden już nie wyjdzie.')]),
            li([.text('Twoje dane w narzędziach do statystyk i raportów błędów.')]),
            li([
              .text(
                'Na telefonach, na których jesteś zalogowany, aplikacja wyloguje się i wyczyści dane '
                'przy następnym uruchomieniu.',
              ),
            ]),
          ]),
        ]),
        textSection('Co zostaje i jak długo', [
          ul([
            li([.text('Kopie zapasowe bazy: dane znikną z nich w ciągu 30 dni.')]),
            li([
              .text(
                'Zapis, że konto usunięto: data i skrót identyfikatora konta, z którego nie da się odczytać, '
                'kim jesteś. Bez danych osobowych.',
              ),
            ]),
            li([
              .text(
                'Operator SMS przechowuje własne zapisy doręczeń przez czas, który określa jego umowa '
                'z nami.',
              ),
            ]),
          ]),
        ]),
        textSection('Chcesz usunąć tylko część danych?', [
          p([
            .text(
              'Usuń klienta, urządzenie albo wizytę w aplikacji. Z serwera znikną po 30 dniach; tyle czasu '
              'dostają Twoje inne telefony, żeby się o tym dowiedzieć.',
            ),
          ]),
        ]),
      ],
    );
  }
}
