import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

void main() {
  group('Error Reporting Integration', () {
    test('should configure ErrorPrivserver with required parameters', () {
      // Act
      ErrorPrivserver.configure(ErrorPrivserverConfig(
        storage: SharedPrefsErrorBoxStorage(),
        reporter: (errorEntry) async {
          // Mock reporter - just complete successfully
          return true;
        },
        errorCodeMapper: ErrorCodeMapper.mapError,
        exceptionMapper: (error) => null, // Mock exception mapper
      ));

      // Assert
      expect(ErrorPrivserver.isConfigured, isTrue);
    });

    test('should map error codes correctly', () {
      // Test the error code mapper
      expect(ErrorCodeMapper.mapError(Exception('Network error')), equals('NET_UNKNOWN'));
      expect(ErrorCodeMapper.mapError(ArgumentError('Invalid argument')), equals('VAL_003'));
      expect(ErrorCodeMapper.mapError(StateError('Invalid state')), equals('STATE_001'));
      expect(ErrorCodeMapper.mapError(FormatException('Format error')), equals('VAL_002'));
      expect(ErrorCodeMapper.mapError(TypeError()), equals('TYPE_001'));
      expect(ErrorCodeMapper.mapError(RangeError('Out of range')), equals('RANGE_001'));
      expect(ErrorCodeMapper.mapError('Unknown error'), equals('ERR_STRING'));
    });
  });
}
