// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_management_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DeviceManagementState {
  UiFlowStatus get status => throw _privateConstructorUsedError;
  List<AccountDevice> get devices => throw _privateConstructorUsedError;
  String? get currentDevicePublicKey => throw _privateConstructorUsedError;
  UuidValue? get revokingDeviceId => throw _privateConstructorUsedError;
  String? get deviceName => throw _privateConstructorUsedError;
  bool get hasExistingKeys => throw _privateConstructorUsedError;
  Object? get error => throw _privateConstructorUsedError;
  DeviceManagementOperation? get lastOperation =>
      throw _privateConstructorUsedError;

  /// Create a copy of DeviceManagementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceManagementStateCopyWith<DeviceManagementState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceManagementStateCopyWith<$Res> {
  factory $DeviceManagementStateCopyWith(
    DeviceManagementState value,
    $Res Function(DeviceManagementState) then,
  ) = _$DeviceManagementStateCopyWithImpl<$Res, DeviceManagementState>;
  @useResult
  $Res call({
    UiFlowStatus status,
    List<AccountDevice> devices,
    String? currentDevicePublicKey,
    UuidValue? revokingDeviceId,
    String? deviceName,
    bool hasExistingKeys,
    Object? error,
    DeviceManagementOperation? lastOperation,
  });
}

/// @nodoc
class _$DeviceManagementStateCopyWithImpl<
  $Res,
  $Val extends DeviceManagementState
>
    implements $DeviceManagementStateCopyWith<$Res> {
  _$DeviceManagementStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceManagementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? devices = null,
    Object? currentDevicePublicKey = freezed,
    Object? revokingDeviceId = freezed,
    Object? deviceName = freezed,
    Object? hasExistingKeys = null,
    Object? error = freezed,
    Object? lastOperation = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as UiFlowStatus,
            devices: null == devices
                ? _value.devices
                : devices // ignore: cast_nullable_to_non_nullable
                      as List<AccountDevice>,
            currentDevicePublicKey: freezed == currentDevicePublicKey
                ? _value.currentDevicePublicKey
                : currentDevicePublicKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            revokingDeviceId: freezed == revokingDeviceId
                ? _value.revokingDeviceId
                : revokingDeviceId // ignore: cast_nullable_to_non_nullable
                      as UuidValue?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasExistingKeys: null == hasExistingKeys
                ? _value.hasExistingKeys
                : hasExistingKeys // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error ? _value.error : error,
            lastOperation: freezed == lastOperation
                ? _value.lastOperation
                : lastOperation // ignore: cast_nullable_to_non_nullable
                      as DeviceManagementOperation?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceManagementStateImplCopyWith<$Res>
    implements $DeviceManagementStateCopyWith<$Res> {
  factory _$$DeviceManagementStateImplCopyWith(
    _$DeviceManagementStateImpl value,
    $Res Function(_$DeviceManagementStateImpl) then,
  ) = __$$DeviceManagementStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    UiFlowStatus status,
    List<AccountDevice> devices,
    String? currentDevicePublicKey,
    UuidValue? revokingDeviceId,
    String? deviceName,
    bool hasExistingKeys,
    Object? error,
    DeviceManagementOperation? lastOperation,
  });
}

/// @nodoc
class __$$DeviceManagementStateImplCopyWithImpl<$Res>
    extends
        _$DeviceManagementStateCopyWithImpl<$Res, _$DeviceManagementStateImpl>
    implements _$$DeviceManagementStateImplCopyWith<$Res> {
  __$$DeviceManagementStateImplCopyWithImpl(
    _$DeviceManagementStateImpl _value,
    $Res Function(_$DeviceManagementStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceManagementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? devices = null,
    Object? currentDevicePublicKey = freezed,
    Object? revokingDeviceId = freezed,
    Object? deviceName = freezed,
    Object? hasExistingKeys = null,
    Object? error = freezed,
    Object? lastOperation = freezed,
  }) {
    return _then(
      _$DeviceManagementStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as UiFlowStatus,
        devices: null == devices
            ? _value._devices
            : devices // ignore: cast_nullable_to_non_nullable
                  as List<AccountDevice>,
        currentDevicePublicKey: freezed == currentDevicePublicKey
            ? _value.currentDevicePublicKey
            : currentDevicePublicKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        revokingDeviceId: freezed == revokingDeviceId
            ? _value.revokingDeviceId
            : revokingDeviceId // ignore: cast_nullable_to_non_nullable
                  as UuidValue?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasExistingKeys: null == hasExistingKeys
            ? _value.hasExistingKeys
            : hasExistingKeys // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error ? _value.error : error,
        lastOperation: freezed == lastOperation
            ? _value.lastOperation
            : lastOperation // ignore: cast_nullable_to_non_nullable
                  as DeviceManagementOperation?,
      ),
    );
  }
}

/// @nodoc

class _$DeviceManagementStateImpl extends _DeviceManagementState {
  const _$DeviceManagementStateImpl({
    this.status = UiFlowStatus.idle,
    final List<AccountDevice> devices = const [],
    this.currentDevicePublicKey,
    this.revokingDeviceId,
    this.deviceName,
    this.hasExistingKeys = false,
    this.error,
    this.lastOperation,
  }) : _devices = devices,
       super._();

  @override
  @JsonKey()
  final UiFlowStatus status;
  final List<AccountDevice> _devices;
  @override
  @JsonKey()
  List<AccountDevice> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  final String? currentDevicePublicKey;
  @override
  final UuidValue? revokingDeviceId;
  @override
  final String? deviceName;
  @override
  @JsonKey()
  final bool hasExistingKeys;
  @override
  final Object? error;
  @override
  final DeviceManagementOperation? lastOperation;

  @override
  String toString() {
    return 'DeviceManagementState(status: $status, devices: $devices, currentDevicePublicKey: $currentDevicePublicKey, revokingDeviceId: $revokingDeviceId, deviceName: $deviceName, hasExistingKeys: $hasExistingKeys, error: $error, lastOperation: $lastOperation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceManagementStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            (identical(other.currentDevicePublicKey, currentDevicePublicKey) ||
                other.currentDevicePublicKey == currentDevicePublicKey) &&
            (identical(other.revokingDeviceId, revokingDeviceId) ||
                other.revokingDeviceId == revokingDeviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.hasExistingKeys, hasExistingKeys) ||
                other.hasExistingKeys == hasExistingKeys) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.lastOperation, lastOperation) ||
                other.lastOperation == lastOperation));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    const DeepCollectionEquality().hash(_devices),
    currentDevicePublicKey,
    revokingDeviceId,
    deviceName,
    hasExistingKeys,
    const DeepCollectionEquality().hash(error),
    lastOperation,
  );

  /// Create a copy of DeviceManagementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceManagementStateImplCopyWith<_$DeviceManagementStateImpl>
  get copyWith =>
      __$$DeviceManagementStateImplCopyWithImpl<_$DeviceManagementStateImpl>(
        this,
        _$identity,
      );
}

abstract class _DeviceManagementState extends DeviceManagementState {
  const factory _DeviceManagementState({
    final UiFlowStatus status,
    final List<AccountDevice> devices,
    final String? currentDevicePublicKey,
    final UuidValue? revokingDeviceId,
    final String? deviceName,
    final bool hasExistingKeys,
    final Object? error,
    final DeviceManagementOperation? lastOperation,
  }) = _$DeviceManagementStateImpl;
  const _DeviceManagementState._() : super._();

  @override
  UiFlowStatus get status;
  @override
  List<AccountDevice> get devices;
  @override
  String? get currentDevicePublicKey;
  @override
  UuidValue? get revokingDeviceId;
  @override
  String? get deviceName;
  @override
  bool get hasExistingKeys;
  @override
  Object? get error;
  @override
  DeviceManagementOperation? get lastOperation;

  /// Create a copy of DeviceManagementState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceManagementStateImplCopyWith<_$DeviceManagementStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
