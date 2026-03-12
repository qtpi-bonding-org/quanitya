import 'dart:convert';
import 'dart:io';

import 'package:jose/jose.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Integration tests for [PowerSyncEndpoint].
///
/// Requires POWERSYNC_JWT_PRIVATE_KEY_PEM env var set to a base64-encoded
/// RSA PEM private key. Use `scripts/run_powersync_tests.sh` to generate
/// a key and run these tests automatically.
void main() {
  final hasPemKey =
      Platform.environment['POWERSYNC_JWT_PRIVATE_KEY_PEM']?.isNotEmpty == true;
  final hasJwkKey =
      Platform.environment['POWERSYNC_JWT_PRIVATE_KEY_JWK']?.isNotEmpty == true;
  final hasSigningKey = hasPemKey || hasJwkKey;

  withServerpod(
    'PowerSyncEndpoint integration',
    rollbackDatabase: RollbackDatabase.afterEach,
    (sessionBuilder, endpoints) {
      const testAccountId = '42';
      late TestSessionBuilder authedSession;

      setUp(() {
        authedSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testAccountId,
            {},
          ),
        );
      });

      group('getToken', () {
        test(
          'returns a PowerSyncToken with non-empty fields',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);

            expect(result.token, isNotEmpty);
            expect(result.expiresAt, isNotEmpty);
            expect(result.endpoint, isNotEmpty);
          },
        );

        test(
          'token is a valid 3-part JWT',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);
            final parts = result.token.split('.');

            expect(parts.length, equals(3), reason: 'JWT must have 3 parts');
          },
        );

        test(
          'JWT header specifies RS256 algorithm',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);
            final jws = JsonWebSignature.fromCompactSerialization(result.token);
            final header = jws.commonProtectedHeader;

            expect(header.algorithm, equals('RS256'));
          },
        );

        test(
          'JWT claims contain correct sub and user_id',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);
            final jwt = JsonWebToken.unverified(result.token);
            final claims = jwt.claims;

            expect(claims.subject, equals(testAccountId));
            expect(claims.toJson()['user_id'], equals(testAccountId));
          },
        );

        test(
          'JWT claims contain correct audience and issuer',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);
            final jwt = JsonWebToken.unverified(result.token);
            final claims = jwt.claims;

            expect(claims.toJson()['aud'], equals('powersync'));
            expect(claims.toJson()['iss'], equals('quanitya-cloud'));
          },
        );

        test(
          'JWT exp is approximately 5 minutes from now',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final before = DateTime.now();
            final result = await endpoints.powerSync.getToken(authedSession);
            final jwt = JsonWebToken.unverified(result.token);
            final exp = jwt.claims.expiry!;

            // Token should expire between 4m50s and 5m10s from now
            // (generous window to avoid flaky tests)
            final minExpiry = before.add(const Duration(minutes: 4, seconds: 50));
            final maxExpiry = before.add(const Duration(minutes: 5, seconds: 10));

            expect(
              exp.isAfter(minExpiry) && exp.isBefore(maxExpiry),
              isTrue,
              reason: 'Token expiry ($exp) should be ~5min from now '
                  '(between $minExpiry and $maxExpiry)',
            );
          },
        );

        test(
          'JWT iat is close to current time',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final before = DateTime.now();
            final result = await endpoints.powerSync.getToken(authedSession);
            final jwt = JsonWebToken.unverified(result.token);
            final iat = jwt.claims.issuedAt!;

            final diff = before.difference(iat).abs();
            expect(
              diff.inSeconds,
              lessThan(5),
              reason: 'iat should be within 5s of current time',
            );
          },
        );

        test(
          'expiresAt is a valid ISO8601 timestamp',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);
            final parsed = DateTime.tryParse(result.expiresAt);

            expect(parsed, isNotNull, reason: 'expiresAt must be valid ISO8601');
          },
        );

        test(
          'endpoint returns POWERSYNC_URL when set',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final result = await endpoints.powerSync.getToken(authedSession);
            final expectedUrl = Platform.environment['POWERSYNC_URL'];

            if (expectedUrl != null && expectedUrl.isNotEmpty) {
              expect(result.endpoint, equals(expectedUrl));
            } else {
              // Falls back to OPENOPS_SERVER_FQDN or localhost
              expect(result.endpoint, isNotEmpty);
            }
          },
        );

        test(
          'different users get different sub claims',
          skip: hasSigningKey
              ? null
              : 'Requires POWERSYNC_JWT_PRIVATE_KEY_PEM or _JWK env var',
          () async {
            final otherSession = sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                '99',
                {},
              ),
            );

            final token42 = await endpoints.powerSync.getToken(authedSession);
            final token99 = await endpoints.powerSync.getToken(otherSession);

            final jwt42 = JsonWebToken.unverified(token42.token);
            final jwt99 = JsonWebToken.unverified(token99.token);

            expect(jwt42.claims.subject, equals('42'));
            expect(jwt99.claims.subject, equals('99'));
            expect(token42.token, isNot(equals(token99.token)));
          },
        );
      });
    },
  );
}
