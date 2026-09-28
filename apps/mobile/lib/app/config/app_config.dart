import 'package:equatable/equatable.dart';

/// Compile-time configuration. Values come from
/// `--dart-define-from-file=.env` (see .env.example); an empty value disables
/// the integration, so a self-hoster without Sentry or PostHog builds the same
/// code with the no-op adapters.
final class const AppConfig({
  required final String supabaseUrl,

  /// Publishable key (`sb_publishable_…`) or the legacy anon JWT; both are
  /// safe to ship in the binary because RLS does the authorisation.
  required final String supabaseKey,
  required final String sentryDsn,
  required final String posthogApiKey,
  required final String posthogHost,
}) with Equatable {
  factory fromEnvironment() => const AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
    posthogApiKey: String.fromEnvironment('POSTHOG_API_KEY'),
    posthogHost: String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://eu.i.posthog.com'),
  );

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  bool get hasSentry => sentryDsn.isNotEmpty;
  bool get hasPosthog => posthogApiKey.isNotEmpty;

  @override
  List<Object?> get props => [supabaseUrl, supabaseKey, sentryDsn, posthogApiKey, posthogHost];
}
