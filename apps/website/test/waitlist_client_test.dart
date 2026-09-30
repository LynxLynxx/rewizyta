import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewizyta_website/waitlist/waitlist_client.dart';
import 'package:test/test.dart';

void main() {
  late http.Request sent;

  WaitlistClient clientAnswering(int status, Object body) {
    return WaitlistClient(
      baseUrl: 'https://api.example.com/functions/v1',
      httpClient: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
      }),
    );
  }

  Future<SignupOutcome> signup(WaitlistClient client, {String phone = ''}) {
    return client.signup(
      email: ' jan@example.com ',
      answers: {
        'trade': ['chimney'],
      },
      phone: phone,
      consent: true,
      source: 'fb',
    );
  }

  test('posts the sign-up as JSON with an empty decoy field', () async {
    final client = clientAnswering(200, {'status': 'created', 'promoCode': 'REWI-7K3M-9QZT', 'mailSent': true});

    await signup(client, phone: ' 601 234 567 ');

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://api.example.com/functions/v1/waitlist-signup');
    expect(sent.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {
      'email': 'jan@example.com',
      'answers': {
        'trade': ['chimney'],
      },
      'consent': true,
      'phone': '601 234 567',
      'source': 'fb',
      'website': '',
    });
  });

  test('leaves out an empty phone number', () async {
    final client = clientAnswering(200, {'status': 'pending', 'mailSent': true});

    await signup(client);

    expect((jsonDecode(sent.body) as Map).containsKey('phone'), isFalse);
  });

  test('a new address gets its promo code', () async {
    final outcome = await signup(
      clientAnswering(200, {'status': 'created', 'promoCode': 'REWI-7K3M-9QZT', 'mailSent': false}),
    );

    expect(outcome, isA<SignupCreated>().having((o) => o.promoCode, 'promoCode', 'REWI-7K3M-9QZT'));
    expect((outcome as SignupCreated).mailSent, isFalse);
  });

  test('a known address is reported without a code', () async {
    final confirmed = await signup(clientAnswering(200, {'status': 'confirmed', 'mailSent': true}));
    final pending = await signup(clientAnswering(200, {'status': 'resubscribed', 'mailSent': false}));

    expect(confirmed, isA<SignupKnown>().having((o) => o.confirmed, 'confirmed', isTrue));
    expect(pending, isA<SignupKnown>().having((o) => o.confirmed, 'confirmed', isFalse));
    expect((pending as SignupKnown).mailSent, isFalse);
  });

  test('server refusals map to what the page can say', () async {
    Future<SignupFailureReason?> reason(int status, Object body) async {
      final outcome = await signup(clientAnswering(status, body));
      return outcome is SignupFailed ? outcome.reason : null;
    }

    expect(await reason(400, {'error': 'invalid_email'}), SignupFailureReason.invalidEmail);
    expect(await reason(400, {'error': 'invalid_phone'}), SignupFailureReason.invalidPhone);
    expect(await reason(429, {'error': 'rate_limited'}), SignupFailureReason.rateLimited);
    expect(await reason(400, {'error': 'invalid_answers'}), SignupFailureReason.other);
    expect(await reason(500, {'error': 'server_error'}), SignupFailureReason.other);
    expect(await reason(502, 'Bad gateway'), SignupFailureReason.other);
    expect(await reason(200, {'status': 'created'}), SignupFailureReason.other);
  });

  test('a network error does not throw', () async {
    final client = WaitlistClient(
      baseUrl: 'https://api.example.com/functions/v1',
      httpClient: MockClient((_) => throw http.ClientException('offline')),
    );

    final outcome = await signup(client);

    expect(outcome, isA<SignupFailed>().having((o) => o.reason, 'reason', SignupFailureReason.other));
  });

  group('mail links', () {
    const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz0123456789-_AbCdE';

    test('confirm posts the token to waitlist-confirm', () async {
      final client = clientAnswering(200, {'status': 'confirmed'});

      expect(await client.confirm(token), TokenOutcome.done);
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.example.com/functions/v1/waitlist-confirm');
      expect(sent.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(sent.body), {'token': token});
    });

    test('unsubscribe posts the token to waitlist-unsubscribe', () async {
      final client = clientAnswering(200, {'status': 'unsubscribed'});

      expect(await client.unsubscribe(token), TokenOutcome.done);
      expect(sent.url.toString(), 'https://api.example.com/functions/v1/waitlist-unsubscribe');
      expect(jsonDecode(sent.body), {'token': token});
    });

    test('an unknown or used token is invalid, not an error', () async {
      expect(await clientAnswering(200, {'status': 'invalid'}).confirm(token), TokenOutcome.invalid);
      expect(await clientAnswering(200, {'status': 'invalid'}).unsubscribe(token), TokenOutcome.invalid);
      expect(await clientAnswering(400, {'error': 'invalid_request'}).confirm(token), TokenOutcome.invalid);
    });

    test('anything else is worth another try', () async {
      expect(await clientAnswering(500, {'error': 'server_error'}).confirm(token), TokenOutcome.failed);
      expect(await clientAnswering(502, 'Bad gateway').unsubscribe(token), TokenOutcome.failed);
      // The other function's success is not this one's.
      expect(await clientAnswering(200, {'status': 'unsubscribed'}).confirm(token), TokenOutcome.failed);

      final offline = WaitlistClient(
        baseUrl: 'https://api.example.com/functions/v1',
        httpClient: MockClient((_) => throw http.ClientException('offline')),
      );
      expect(await offline.unsubscribe(token), TokenOutcome.failed);
    });
  });
}
