// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:rewizyta_website/components/site_footer.dart' as _site_footer;
import 'package:rewizyta_website/components/site_header.dart' as _site_header;
import 'package:rewizyta_website/pages/home/audience.dart' as _audience;
import 'package:rewizyta_website/pages/home/comparison.dart' as _comparison;
import 'package:rewizyta_website/pages/home/hero.dart' as _hero;
import 'package:rewizyta_website/pages/home/home_page.dart' as _home_page;
import 'package:rewizyta_website/pages/home/how_it_works.dart' as _how_it_works;
import 'package:rewizyta_website/pages/home/ownership.dart' as _ownership;
import 'package:rewizyta_website/pages/home/signup_section.dart'
    as _signup_section;
import 'package:rewizyta_website/pages/mail_page.dart' as _mail_page;
import 'package:rewizyta_website/pages/not_found_page.dart' as _not_found_page;
import 'package:rewizyta_website/pages/privacy_page.dart' as _privacy_page;
import 'package:rewizyta_website/waitlist/confirm_action.dart'
    as _confirm_action;
import 'package:rewizyta_website/waitlist/mail_action.dart' as _mail_action;
import 'package:rewizyta_website/waitlist/signup_form.dart' as _signup_form;
import 'package:rewizyta_website/waitlist/unsubscribe_action.dart'
    as _unsubscribe_action;
import 'package:rewizyta_website/app.dart' as _app;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _confirm_action.ConfirmAction: ClientTarget<_confirm_action.ConfirmAction>(
      'confirm_action',
    ),
    _signup_form.SignupForm: ClientTarget<_signup_form.SignupForm>(
      'signup_form',
    ),
    _unsubscribe_action.UnsubscribeAction:
        ClientTarget<_unsubscribe_action.UnsubscribeAction>(
          'unsubscribe_action',
        ),
  },
  styles: () => [
    ..._app.App.styles,
    ..._site_footer.SiteFooter.styles,
    ..._site_header.SiteHeader.styles,
    ..._mail_page.MailPage.styles,
    ..._not_found_page.NotFoundPage.styles,
    ..._privacy_page.PrivacyPage.styles,
    ..._audience.Audience.styles,
    ..._comparison.Comparison.styles,
    ..._hero.Hero.styles,
    ..._hero.IncomingCallCard.styles,
    ..._home_page.HomePage.styles,
    ..._how_it_works.HowItWorks.styles,
    ..._ownership.Ownership.styles,
    ..._signup_section.SignupSection.styles,
    ..._mail_action.MailActionState.styles,
    ..._signup_form.SignupFormState.styles,
  ],
);
