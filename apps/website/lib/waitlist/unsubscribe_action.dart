import 'package:jaspr/jaspr.dart';

import 'mail_action.dart';

/// `/wypisz/`: the unsubscribe button every mail links to.
@client
class UnsubscribeAction extends StatefulComponent {
  const UnsubscribeAction({super.key});

  @override
  State<UnsubscribeAction> createState() => MailActionState(MailAction.unsubscribe);
}
