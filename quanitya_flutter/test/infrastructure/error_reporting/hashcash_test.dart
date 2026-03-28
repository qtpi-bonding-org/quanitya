import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/crypto/utils/hashcash.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  group('Hashcash', () {
    test('mint produces valid stamp with correct format', () async {
      final challenge = 'test-challenge-123';
      final stamp = await Hashcash.mint(challenge, difficulty: 16); // Lower difficulty for faster test

      // Verify format: "1:difficulty:challenge:nonce"
      expect(stamp, startsWith('1:16:test-challenge-123:'));

      final parts = stamp.split(':');
      expect(parts.length, equals(4));
      expect(parts[0], equals('1')); // Version
      expect(parts[1], equals('16')); // Difficulty
      expect(parts[2], equals('test-challenge-123')); // Challenge
      expect(int.tryParse(parts[3]), isNotNull); // Nonce is integer
    });

    test('mint produces stamp with required leading zero bits', () async {
      final challenge = 'test-challenge-456';
      final difficulty = 16;
      final stamp = await Hashcash.mint(challenge, difficulty: difficulty);

      // Verify hash has required leading zero bits
      final hash = sha1.convert(utf8.encode(stamp));
      final zeroBits = _countLeadingZeroBits(hash.bytes);

      expect(zeroBits, greaterThanOrEqualTo(difficulty));
    });

    test('mint with different challenges produces different stamps', () async {
      final stamp1 = await Hashcash.mint('challenge-1', difficulty: 16);
      final stamp2 = await Hashcash.mint('challenge-2', difficulty: 16);

      expect(stamp1, isNot(equals(stamp2)));
      expect(stamp1, contains('challenge-1'));
      expect(stamp2, contains('challenge-2'));
    });

    test('mint completes in reasonable time for difficulty 16', () async {
      final challenge = 'performance-test';
      final stopwatch = Stopwatch()..start();

      final stamp = await Hashcash.mint(challenge, difficulty: 16);

      stopwatch.stop();

      // Should complete within 30 seconds even on slow CI machines
      expect(stopwatch.elapsed.inSeconds, lessThan(30));
      expect(stamp, contains(challenge));

      // Verify it's actually valid
      final hash = sha1.convert(utf8.encode(stamp));
      final zeroBits = _countLeadingZeroBits(hash.bytes);
      expect(zeroBits, greaterThanOrEqualTo(16));
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
