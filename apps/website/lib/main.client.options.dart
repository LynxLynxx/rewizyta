// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:rewizyta_website/waitlist/confirm_action.dart'
    deferred as _confirm_action;
import 'package:rewizyta_website/waitlist/signup_form.dart'
    deferred as _signup_form;
import 'package:rewizyta_website/waitlist/unsubscribe_action.dart'
    deferred as _unsubscribe_action;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'confirm_action': ClientLoader(
      (p) => _confirm_action.ConfirmAction(),
      loader: _confirm_action.loadLibrary,
    ),
    'signup_form': ClientLoader(
      (p) => _signup_form.SignupForm(),
      loader: _signup_form.loadLibrary,
    ),
    'unsubscribe_action': ClientLoader(
      (p) => _unsubscribe_action.UnsubscribeAction(),
      loader: _unsubscribe_action.loadLibrary,
    ),
  },
);
