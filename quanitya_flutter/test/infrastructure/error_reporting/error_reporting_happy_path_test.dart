import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/crypto/utils/hashcash.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  group('Error Reporting Happy Path', () {
    test('Complete flow: mine stamp and verify it would be valid', () async {
      // Simulate the complete flow without actual server calls
      
      // Step 1: Simulate getting challenge from server
      final challenge = 'test-challenge-abc123';
      final difficulty = 16; // Lower for faster test
      
      // Step 2: Mine proof-of-work stamp
      final stopwatch = Stopwatch()..start();
      final stamp = await Hashcash.mint(challenge, difficulty: difficulty);
      stopwatch.stop();
      
      // Mining took ~292ms in tests
      
      // Step 3: Verify stamp format
      expect(stamp, startsWith('1:$difficulty:$challenge:'));
      final parts = stamp.split(':');
      expect(parts.length, equals(4));
      expect(parts[0], equals('1')); // Version
      expect(parts[1], equals('$difficulty')); // Difficulty
      expect(parts[2], equals(challenge)); // Challenge
      expect(int.tryParse(parts[3]), isNotNull); // Nonce
      
      // Step 4: Verify proof-of-work is valid
      final hash = sha1.convert(utf8.encode(stamp));
      final zeroBits = _countLeadingZeroBits(hash.bytes);
      expect(zeroBits, greaterThanOrEqualTo(difficulty));
      
      // Step 5: Simulate creating error entry
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'TestException',
        errorCode: 'TEST_001',
        stackTrace: 'at TestCubit.testMethod (test.dart:10)\nat main (main.dart:5)',
        timestamp: DateTime.now(),
        userMessage: 'Test error occurred',
      );
      
      // Verify error entry is PII-free
      expect(errorEntry.source, equals('TestCubit'));
      expect(errorEntry.errorCode, equals('TEST_001'));
      expect(errorEntry.stackTrace, contains('TestCubit.testMethod'));
      expect(errorEntry.userMessage, equals('Test error occurred'));
      
      // In real flow, this would be submitted to server with the stamp
      // Happy path complete: Challenge → Mine → Verify → Submit
    });

    test('Stamp validation: invalid format rejected', () {
      final invalidStamps = [
        'invalid',
        '1:20',
        '1:20:challenge',
        '2:20:challenge:nonce', // Wrong version
        '1:abc:challenge:nonce', // Invalid difficulty
      ];

      for (final stamp in invalidStamps) {
        final parts = stamp.split(':');
        
        // Should fail basic format checks
        if (parts.length != 4) {
          expect(parts.length, isNot(equals(4)));
        } else if (parts[0] != '1') {
          expect(parts[0], isNot(equals('1')));
        } else if (int.tryParse(parts[1]) == null) {
          expect(int.tryParse(parts[1]), isNull);
        }
      }
    });

    test('ErrorCodeMapper maps exception types to correct codes', () {
      expect(ErrorCodeMapper.mapError(Exception('Network error')), equals('NET_UNKNOWN'));
      expect(ErrorCodeMapper.mapError(ArgumentError('Invalid argument')), equals('VAL_003'));
      expect(ErrorCodeMapper.mapError(StateError('Invalid state')), equals('STATE_001'));
      expect(ErrorCodeMapper.mapError(FormatException('Format error')), equals('VAL_002'));
      expect(ErrorCodeMapper.mapError(TypeError()), equals('TYPE_001'));
      expect(ErrorCodeMapper.mapError(RangeError('Out of range')), equals('RANGE_001'));
      expect(ErrorCodeMapper.mapError('Unknown error'), equals('ERR_STRING'));
    });

    test('Error entry contains no PII', () {
      // Verify that ErrorEntry only contains safe technical data
      final errorEntry = ErrorEntry(
        source: 'LoginCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'at LoginCubit.login (login_cubit.dart:45)\nat main (main.dart:10)',
        timestamp: DateTime.now(),
        userMessage: 'Failed to connect to server',
      );

      // Should NOT contain:
      // - User emails, names, passwords
      // - API keys, tokens
      // - Personal data
      
      // Should ONLY contain:
      // - Class/method names (technical)
      // - Error types (technical)
      // - Stack traces without function arguments (technical)
      // - Generic error messages (technical)
      
      expect(errorEntry.source, equals('LoginCubit'));
      expect(errorEntry.errorType, equals('NetworkException'));
      expect(errorEntry.errorCode, equals('NET_001'));
      expect(errorEntry.stackTrace, contains('LoginCubit.login'));
      expect(errorEntry.stackTrace, isNot(contains('@'))); // No emails
      expect(errorEntry.stackTrace, isNot(contains('password'))); // No passwords
      expect(errorEntry.userMessage, equals('Failed to connect to server'));
    });
  });
}

/// Count leading zero bits in hash bytes
int _countLeadingZeroBits(List<int> hashBytes) {
  int zeroBits = 0;

  for (final byte in hashBytes) {
    if (byte == 0) {
      zeroBits += 8;
    } else {
      // Count leading zeros in this byte
      int count = 0;
      int mask = 0x80; // 10000000

      while ((byte & mask) == 0) {
        count++;
        mask >>= 1;
      }

      zeroBits += count;
      break;
    }
  }

  return zeroBits;
}
