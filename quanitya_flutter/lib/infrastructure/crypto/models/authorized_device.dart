import 'package:freezed_annotation/freezed_annotation.dart';

part 'authorized_device.freezed.dart';
part 'authorized_device.g.dart';

/// Represents an authorized device in the user's account
/// 
/// Contains the device's public key and authorization metadata.
/// Used for device management and revocation operations.
@freezed
class AuthorizedDevice with _$AuthorizedDevice {
  const factory AuthorizedDevice({
    required String publicKey,
    required DateTime authorizedAt,
    String? deviceName, // Optional user-provided label
  }) = _AuthorizedDevice;

  factory AuthorizedDevice.fromJson(Map<String, dynamic> json) =>
      _$AuthorizedDeviceFromJson(json);
}