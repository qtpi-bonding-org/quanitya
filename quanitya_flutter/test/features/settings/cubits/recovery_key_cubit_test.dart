import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_state.dart';
import 'package:quanitya_flutter/infrastructure/auth/account_service.dart';
import 'package:quanitya_flutter/infrastructure/auth/auth_service.dart';

@GenerateMocks([AccountService])
import 'recovery_key_cubit_test.mocks.dart';

void main() {
  group('RecoveryKeyCubit', () {
    late MockAccountService mockAccountService;

    setUp(() {
      mockAccountService = MockAccountService();
    });

    RecoveryKeyCubit buildCubit() => RecoveryKeyCubit(mockAccountService);

    test('initial state is idle', () {
      final cubit = buildCubit();
      
      expect(cubit.state.status, equals(UiFlowStatus.idle));
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.error, isNull);
      
      cubit.close();
    });

    group('validateRecoveryKey', () {
      const validJwk = '{"keys":[{"kty":"EC","crv":"P-256"}]}';

      test('emits loading then success on valid key', () async {
        when(mockAccountService.validateRecoveryKey(validJwk))
            .thenAnswer((_) async {});

        final cubit = buildCubit();
        final states = <RecoveryKeyState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.validateRecoveryKey(validJwk);
        await Future.delayed(Duration.zero); // Let stream emit

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.success));
        expect(states.last.lastOperation, equals(RecoveryKeyOperation.validate));
        
        verify(mockAccountService.validateRecoveryKey(validJwk)).called(1);
      });

      test('emits loading then failure on invalid key', () async {
        when(mockAccountService.validateRecoveryKey(any))
            .thenThrow(const AccountRecoveryException('Invalid key'));

        final cubit = buildCubit();
        final states = <RecoveryKeyState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.validateRecoveryKey('invalid');
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.failure));
        expect(states.last.error, isA<AccountRecoveryException>());
      });
    });

    group('recoverAccount', () {
      const validJwk = '{"keys":[{"kty":"EC","crv":"P-256"}]}';
      const deviceLabel = 'Test Device';

      test('emits loading then success on successful recovery', () async {
        when(mockAccountService.recoverAccount(
          ultimatePrivateKey: validJwk,
          deviceLabel: deviceLabel,
        )).thenAnswer((_) async {});

        final cubit = buildCubit();
        final states = <RecoveryKeyState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.recoverAccount(jwk: validJwk, deviceLabel: deviceLabel);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.success));
        expect(states.last.lastOperation, equals(RecoveryKeyOperation.recover));
        
        verify(mockAccountService.recoverAccount(
          ultimatePrivateKey: validJwk,
          deviceLabel: deviceLabel,
        )).called(1);
      });

      test('emits loading then failure when account not found', () async {
        when(mockAccountService.recoverAccount(
          ultimatePrivateKey: anyNamed('ultimatePrivateKey'),
          deviceLabel: anyNamed('deviceLabel'),
        )).thenThrow(const AccountRecoveryException('No account found'));

        final cubit = buildCubit();
        final states = <RecoveryKeyState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.recoverAccount(jwk: validJwk, deviceLabel: deviceLabel);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.failure));
        expect(states.last.error, isA<AccountRecoveryException>());
      });
    });
  });

}
