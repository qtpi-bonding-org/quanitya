import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/data_encryption_service.dart';
import 'entitlement_exception.dart';
import 'i_entitlement_service.dart';

/// Entitlement tag for cloud sync access.
const String syncDaysTag = 'sync_days';

@LazySingleton(as: IEntitlementService)
class EntitlementService implements IEntitlementService {
  final Client _client;
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryptionService _encryption;

  EntitlementService(this._client, this._keyRepository, this._encryption);

  @override
  Future<List<AccountEntitlement>> getEntitlements() {
    return tryMethod(
      () async {
        final auth = await _getAuthParams();
        return await _client.modules.anonaccred.commerce.getEntitlements(
          auth.publicKeyHex,
          auth.signature,
          auth.accountId,
        );
      },
      EntitlementException.new,
      'getEntitlements',
    );
  }

  @override
  Future<double> getEntitlementBalance(String tag) {
    return tryMethod(
      () async {
        final auth = await _getAuthParams();
        return await _client.modules.anonaccred.commerce.getEntitlementBalance(
          auth.publicKeyHex,
          auth.signature,
          auth.accountId,
          tag,
        );
      },
      EntitlementException.new,
      'getEntitlementBalance',
    );
  }

  @override
  Future<bool> hasSyncAccess() {
    return tryMethod(
      () async {
        final balance = await getEntitlementBalance(syncDaysTag);
        return balance > 0;
      },
      EntitlementException.new,
      'hasSyncAccess',
    );
  }

  @override
  Future<void> consumeEntitlement(String tag, double quantity) {
    return tryMethod(
      () async {
        final auth = await _getAuthParams();
        await _client.modules.anonaccred.commerce.consumeEntitlement(
          auth.publicKeyHex,
          auth.signature,
          auth.accountId,
          tag,
          quantity,
        );
      },
      EntitlementException.new,
      'consumeEntitlement',
    );
  }

  /// Get authentication parameters needed for commerce API calls.
  Future<_AuthParams> _getAuthParams() async {
    final publicKeyHex = await _keyRepository.getDeviceSigningPublicKeyHex();
    if (publicKeyHex == null) {
      throw const EntitlementException('Device key not found');
    }

    // Authenticate with server to get accountId
    final challenge = await _client.modules.anonaccred.device
        .generateAuthChallenge(publicKeyHex);
    final signature = await _encryption.signWithDeviceKey(challenge);
    final authResult = await _client.modules.anonaccred.device
        .authenticateDevice(challenge, signature);

    if (!authResult.success || authResult.accountId == null) {
      throw const EntitlementException('Authentication failed');
    }

    return _AuthParams(
      publicKeyHex: publicKeyHex,
      signature: signature,
      accountId: authResult.accountId!,
    );
  }
}

class _AuthParams {
  final String publicKeyHex;
  final String signature;
  final int accountId;

  const _AuthParams({
    required this.publicKeyHex,
    required this.signature,
    required this.accountId,
  });
}
