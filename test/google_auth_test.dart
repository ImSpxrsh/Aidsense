import 'package:aidsense_app/google_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('falls back to Apple OAuth when the token audience is rejected', () {
    final error = StateError(
      'AuthApiException(message: Unacceptable audience in id_token:[com.aidsense.app], status code: 400, code: null)',
    );

    expect(shouldFallbackToAppleOAuth(error), isTrue);
  });

  test('does not fallback for unrelated Apple auth errors', () {
    final error = StateError(
        'AuthApiException(message: invalid_request, status code: 400)');

    expect(shouldFallbackToAppleOAuth(error), isFalse);
  });
}
