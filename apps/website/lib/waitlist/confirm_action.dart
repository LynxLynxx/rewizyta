import 'package:jaspr/jaspr.dart';

import 'mail_action.dart';

/// `/potwierdz/`: the double opt-in button the confirmation mail links to.
@client
class ConfirmAction extends StatefulComponent {
  const ConfirmAction({super.key});

  @override
  State<ConfirmAction> createState() => MailActionState(MailAction.confirm);
}
