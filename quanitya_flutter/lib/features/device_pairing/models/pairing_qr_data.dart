import 'package:freezed_annotation/freezed_annotation.dart';

part 'pairing_qr_data.freezed.dart';
part 'pairing_qr_data.g.dart';

/// Actions available for device pairing QR codes
enum PairingAction {
  pair,
}

/// QR code payload for device pairing.
/// 
/// Contains Device B's public keys (for encryption) and label.
/// Device A scans this, encrypts the SDK with Device B's public key,
/// and registers Device B with the server.
@freezed
abstract class PairingQrData with _$PairingQrData {
  const PairingQrData._();
  const factory PairingQrData({
    /// Action identifier - currently only "pair" supported
    required PairingAction action,
    
    /// Device B's public KeyDuo as JWK Set JSON.
    /// Contains RSA public key (for encryption) + ECDSA public key (for signing).
    required String devicePublicKeyJwk,
    
    /// Human-readable device label (e.g., "iPhone 15")
    required String label,
  }) = _PairingQrData;

  factory PairingQrData.fromJson(Map<String, dynamic> json) =>
      _$PairingQrDataFromJson(json);
}
