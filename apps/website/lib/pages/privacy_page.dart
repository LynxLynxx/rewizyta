import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/site_page.dart';
import '../constants/site.dart';
import '../constants/theme.dart';

/// `/prywatnosc/`: the privacy notice for the site and the waitlist (GDPR
/// art. 13). What it promises must match `docs/DATABASE.md`, "Personal data,
/// encryption and retention"; from launch it grows the app's policy.
class PrivacyPage extends StatelessComponent {
  const PrivacyPage({super.key});

  static const lastChanged = '30 września 2026 r.';

  @override
  Component build(BuildContext context) {
    return SitePage([
      const Document.head(
        meta: {'description': 'Jakie dane zbiera lista oczekujących Rewizyty, po co i jak długo je przechowujemy.'},
      ),
      article(classes: 'container privacy', [
        header(classes: 'privacy-header', [
          h1([.text('Polityka prywatności')]),
          p([
            .text(
              'Dotyczy tej strony i listy oczekujących Rewizyty. Aplikacji jeszcze nie ma; '
              'gdy wystartuje, dopiszemy tu jej zasady.',
            ),
          ]),
          p(classes: 'privacy-date', [.text('Ostatnia zmiana: $lastChanged')]),
        ]),
        _section('Kto odpowiada za Twoje dane', [
          p([
            .text(
              'Administratorem danych jest firma $controllerName (NIP $controllerTaxId), która tworzy '
              'Rewizytę. W sprawie swoich danych napisz na ',
            ),
            a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
            .text('. Odpowiemy najpóźniej w ciągu miesiąca.'),
          ]),
        ]),
        _section('Co zbieramy, po co i na jakiej podstawie', [
          ul([
            _item(
              'Adres e-mail i przypisany do niego kod',
              'żeby wysłać link potwierdzający i kod na 3 miesiące za darmo, a po potwierdzeniu '
                  'wiadomość o starcie aplikacji. Podstawa: Twoja zgoda (art. 6 ust. 1 lit. a RODO).',
            ),
            _item(
              'Numer telefonu, jeśli go podasz',
              'żeby oddzwonić na krótką rozmowę o Twojej pracy. Podstawa: Twoja zgoda.',
            ),
            _item(
              'Odpowiedzi z ankiety',
              'żeby zdecydować, co zbudować najpierw i na jakie telefony. Oglądamy je zbiorczo. '
                  'Podstawa: nasz prawnie uzasadniony interes, czyli zaplanowanie aplikacji '
                  '(art. 6 ust. 1 lit. f RODO).',
            ),
            _item(
              'Źródło zapisu i daty zapisu, potwierdzenia oraz wypisania',
              'żeby wiedzieć, skąd przychodzą zapisy, i móc wykazać, kiedy zgoda została wyrażona '
                  'lub cofnięta. Podstawa: prawnie uzasadniony interes.',
            ),
            li([
              strong([.text('Adresu IP nie zapisujemy w bazie.')]),
              .text(
                ' Żeby chronić formularz przed spamem, liczymy zapisy z jednego adresu po jego skrócie '
                '(HMAC z tajnym kluczem), a liczniki kasujemy po dobie. Podstawa: prawnie uzasadniony '
                'interes, czyli bezpieczeństwo.',
              ),
            ]),
          ]),
        ]),
        _section('Czego nie robimy', [
          ul([
            li([
              .text(
                'Strona nie używa plików cookie ani narzędzi analitycznych. Czcionki i wszystkie pliki '
                'leżą na naszym hostingu; nie osadzamy niczego z innych serwisów, np. Google Fonts.',
              ),
            ]),
            li([.text('Nie sprzedajemy danych i nie przekazujemy ich nikomu do marketingu.')]),
            li([.text('Nie profilujemy i nie podejmujemy decyzji automatycznie.')]),
            li([
              .text(
                'Bez potwierdzenia adresu nie napiszemy nic poza pierwszą wiadomością. '
                'Po potwierdzeniu: wiadomość o starcie, bez newslettera.',
              ),
            ]),
          ]),
        ]),
        _section('Komu powierzamy dane', [
          p([.text('Korzystamy z firm, które przetwarzają dane w naszym imieniu, na podstawie umów powierzenia:')]),
          ul([
            _item(
              'Supabase Inc. (USA)',
              'baza danych i funkcje serwera. Dane są przechowywane we Frankfurcie (Niemcy).',
            ),
            _item('Brevo (Francja)', 'wysyłka e-maili.'),
            _item(
              'Cloudflare, Inc. (USA)',
              'DNS i hosting tej strony. Formularz wysyła dane prosto do Supabase, z pominięciem Cloudflare.',
            ),
          ]),
          p([
            .text(
              'Supabase i Cloudflare mają siedziby w USA. Ewentualny dostęp do danych z USA opiera się '
              'na standardowych klauzulach umownych zatwierdzonych przez Komisję Europejską. Każda '
              'z tych firm przez krótki czas trzyma techniczne logi zapytań (np. adres IP i godzinę) '
              'dla bezpieczeństwa, według własnych zasad.',
            ),
          ]),
        ]),
        _section('Jak długo przechowujemy dane', [
          ul([
            li([
              .text(
                'Dane z listy: do 12 miesięcy po starcie aplikacji. Jeśli wypiszesz się wcześniej, '
                'usuniemy je po 30 dniach. Zostaje tylko skrót adresu e-mail, z którego nie da się '
                'odczytać adresu; dzięki niemu nie napiszemy do Ciebie ponownie.',
              ),
            ]),
            li([.text('Liczniki chroniące przed spamem: jedną dobę.')]),
          ]),
        ]),
        _section('Twoje prawa', [
          p([.text('W każdej chwili możesz:')]),
          ul([
            li([
              .text(
                'wypisać się jednym kliknięciem (link jest w każdej wiadomości) albo napisać do nas. '
                'To cofa zgodę; nie zmienia tego, co działo się przed jej cofnięciem.',
              ),
            ]),
            li([.text('dostać kopię swoich danych, poprawić je albo poprosić o ich usunięcie;')]),
            li([.text('zażądać ograniczenia przetwarzania albo przeniesienia danych;')]),
            li([
              .text(
                'sprzeciwić się przetwarzaniu opartemu na naszym uzasadnionym interesie, '
                'np. analizie odpowiedzi z ankiety;',
              ),
            ]),
            li([
              .text(
                'złożyć skargę do Prezesa Urzędu Ochrony Danych Osobowych '
                '(ul. Stawki 2, 00-193 Warszawa, ',
              ),
              a(href: 'https://uodo.gov.pl', [.text('uodo.gov.pl')]),
              .text(').'),
            ]),
          ]),
        ]),
        _section('Czy musisz podać dane', [
          p([
            .text(
              'Nie. Zapis jest dobrowolny, ale bez adresu e-mail nie wyślemy kodu ani wiadomości '
              'o starcie. Numer telefonu jest nieobowiązkowy.',
            ),
          ]),
        ]),
      ]),
    ]);
  }

  static Component _section(String title, List<Component> children) {
    return section([
      h2([.text(title)]),
      ...children,
    ]);
  }

  static Component _item(String what, String why) {
    return li([
      strong([.text(what)]),
      .text(' – $why'),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.privacy', [
      css('&').styles(
        display: .flex,
        padding: .only(top: 32.px, bottom: 72.px),
        flexDirection: .column,
        gap: Gap(row: 32.px),
      ),
      css('section, .privacy-header').styles(
        display: .flex,
        maxWidth: 44.em,
        flexDirection: .column,
        gap: Gap(row: 12.px),
      ),
      css('h1').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(30px, 4.4vw, 42px)'),
        fontWeight: .w700,
        letterSpacing: (-0.02).em,
        lineHeight: 1.1.em,
      ),
      css('h2').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(21px, 2.6vw, 24px)'),
        fontWeight: .w600,
        lineHeight: 1.25.em,
      ),
      css('p, li').styles(
        color: Palette.text2,
        fontSize: 16.px,
        lineHeight: 1.6.em,
        raw: {'text-wrap': 'pretty'},
      ),
      css('p').styles(margin: .zero),
      css('ul').styles(
        display: .flex,
        padding: .only(left: 20.px),
        margin: .zero,
        flexDirection: .column,
        gap: Gap(row: 8.px),
      ),
      css('strong').styles(color: Palette.ink, fontWeight: .w600),
    ]),
    css('.privacy .privacy-date').styles(color: Palette.muted, fontFamily: monoFont, fontSize: 14.px),
  ];
}
