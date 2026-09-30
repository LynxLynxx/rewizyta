import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL of the Supabase edge functions, set at build time:
/// `jaspr build --dart-define=FUNCTIONS_URL=https://<ref>.supabase.co/functions/v1`.
/// Defaults to `supabase start` on this machine.
const functionsUrl = String.fromEnvironment('FUNCTIONS_URL', defaultValue: 'http://127.0.0.1:54321/functions/v1');

/// What happened to the mail the sign-up asked for.
enum MailDelivery {
  sent,

  /// One went out to this address in the last 15 minutes, so none was sent now.
  throttled,

  /// The mail provider refused it; another try works after 15 minutes.
  failed,
}

/// What `waitlist-signup` answered, in the terms the page needs.
sealed class SignupOutcome {
  const SignupOutcome();
}

/// A new address: the code is shown on the page and sent with the confirmation mail.
final class SignupCreated extends SignupOutcome {
  const SignupCreated({required this.promoCode, required this.mail});

  final String promoCode;
  final MailDelivery mail;
}

/// An address already on the list. The code goes only by mail, never to the page.
final class SignupKnown extends SignupOutcome {
  const SignupKnown({required this.confirmed, required this.mail});

  final bool confirmed;
  final MailDelivery mail;
}

enum SignupFailureReason { invalidEmail, invalidPhone, rateLimited, other }

final class SignupFailed extends SignupOutcome {
  const SignupFailed(this.reason);

  final SignupFailureReason reason;
}

/// What `waitlist-confirm` or `waitlist-unsubscribe` answered.
enum TokenOutcome {
  /// Confirmed, or unsubscribed (also when it already was).
  done,

  /// The server does not know the token: already used, or the sign-up is gone.
  invalid,

  /// A network or server error; worth another try.
  failed,
}

class WaitlistClient {
  WaitlistClient({this.baseUrl = functionsUrl, http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  /// Posts the sign-up. Never throws: a network error is [SignupFailureReason.other].
  /// [decoy] is whatever filled the hidden `website` field; people leave it empty.
  Future<SignupOutcome> signup({
    required String email,
    required Map<String, Object> answers,
    required String phone,
    required bool consent,
    String? source,
    String decoy = '',
  }) async {
    final body = <String, Object>{
      'email': email.trim(),
      'answers': answers,
      'consent': consent,
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (source != null && source.isNotEmpty) 'source': source,
      // The server drops a sign-up with this filled, pretending success.
      'website': decoy,
    };

    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$baseUrl/waitlist-signup'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
    } on Exception {
      return const SignupFailed(SignupFailureReason.other);
    }

    final json = _decode(response.body);
    if (response.statusCode == 200) {
      final mail = switch (json['mail']) {
        'sent' => MailDelivery.sent,
        'throttled' => MailDelivery.throttled,
        'failed' => MailDelivery.failed,
        // A function from before `mail` only says whether the mail went out.
        _ => json['mailSent'] == true ? MailDelivery.sent : MailDelivery.failed,
      };
      return switch (json['status']) {
        'created' when json['promoCode'] is String => SignupCreated(
          promoCode: json['promoCode'] as String,
          mail: mail,
        ),
        'confirmed' => SignupKnown(confirmed: true, mail: mail),
        'pending' || 'resubscribed' => SignupKnown(confirmed: false, mail: mail),
        _ => const SignupFailed(SignupFailureReason.other),
      };
    }
    return SignupFailed(switch ((response.statusCode, json['error'])) {
      (400, 'invalid_email') => SignupFailureReason.invalidEmail,
      (400, 'invalid_phone') => SignupFailureReason.invalidPhone,
      (429, _) => SignupFailureReason.rateLimited,
      _ => SignupFailureReason.other,
    });
  }

  /// The button on `/potwierdz/`. Never throws.
  Future<TokenOutcome> confirm(String token) => _postToken('waitlist-confirm', token, doneStatus: 'confirmed');

  /// The button on `/wypisz/`. Never throws.
  Future<TokenOutcome> unsubscribe(String token) =>
      _postToken('waitlist-unsubscribe', token, doneStatus: 'unsubscribed');

  Future<TokenOutcome> _postToken(String function, String token, {required String doneStatus}) async {
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$baseUrl/$function'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
    } on Exception {
      return TokenOutcome.failed;
    }

    return switch ((response.statusCode, _decode(response.body)['status'])) {
      (200, final status) when status == doneStatus => TokenOutcome.done,
      (200, 'invalid') => TokenOutcome.invalid,
      // A malformed token; the page checks the shape first, so this is a link cut short.
      (400, _) => TokenOutcome.invalid,
      _ => TokenOutcome.failed,
    };
  }

  static Map<String, Object?> _decode(String body) {
    try {
      final json = jsonDecode(body);
      return json is Map<String, Object?> ? json : const {};
    } on FormatException {
      return const {};
    }
  }
}
