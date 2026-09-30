import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';
import '../../waitlist/signup_form.dart';

/// What signing up gives, beside the survey form.
class SignupSection extends StatelessComponent {
  const SignupSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: SignupForm.sectionId, classes: 'container signup-section', [
      div(classes: 'signup-intro', [
        h2([.text('Zapisz się na listę')]),
        p([
          .text(
            'Siedem pytań, około minuty. Odpowiedzi mówią nam, co zrobić najpierw. '
            'Na koniec dostajesz kod na ',
          ),
          strong([.text('3 miesiące za darmo')]),
          .text(' — na ekranie i e-mailem.'),
        ]),
        p(classes: 'signup-intro-note', [
          .text('Start planujemy wiosną 2027. Wtedy wyślemy jeden e-mail. Bez newslettera.'),
        ]),
      ]),
      const SignupForm(),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.signup-section').styles(
      display: .grid,
      padding: .only(top: 56.px, bottom: 64.px),
      alignItems: .start,
      gap: Gap(row: 36.px, column: 36.px),
      raw: {
        'grid-template-columns': 'repeat(auto-fit, minmax(min(100%, 340px), 1fr))',
        'scroll-margin-top': '12px',
      },
    ),
    css('.signup-intro', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap(row: 14.px),
      ),
      css('h2').styles(
        margin: .zero,
        fontSize: Unit.expression('clamp(28px, 4vw, 38px)'),
        fontWeight: .w700,
        letterSpacing: (-0.02).em,
        lineHeight: 1.1.em,
      ),
      css('p').styles(
        margin: .zero,
        color: Palette.text2,
        fontSize: 17.px,
        lineHeight: 1.5.em,
        raw: {'text-wrap': 'pretty'},
      ),
      css('strong').styles(fontWeight: .w600),
    ]),
    css('.signup-intro .signup-intro-note').styles(color: Palette.muted, fontSize: 15.px),
  ];
}
