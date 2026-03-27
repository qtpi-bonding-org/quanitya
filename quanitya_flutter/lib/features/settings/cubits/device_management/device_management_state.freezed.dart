// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_management_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceManagementState {

 UiFlowStatus get status; List<AccountDevice> get devices; String? get currentDevicePublicKey; UuidValue? get revokingDeviceId; String? get deviceName; bool get hasExistingKeys; Object? get error; DeviceManagementOperation? get lastOperation;
/// Create a copy of DeviceManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceManagementStateCopyWith<DeviceManagementState> get copyWith => _$DeviceManagementStateCopyWithImpl<DeviceManagementState>(this as DeviceManagementState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceManagementState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.devices, devices)&&(identical(other.currentDevicePublicKey, currentDevicePublicKey) || other.currentDevicePublicKey == currentDevicePublicKey)&&(identical(other.revokingDeviceId, revokingDeviceId) || other.revokingDeviceId == revokingDeviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.hasExistingKeys, hasExistingKeys) || other.hasExistingKeys == hasExistingKeys)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.lastOperation, lastOperation) || other.lastOperation == lastOperation));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(devices),currentDevicePublicKey,revokingDeviceId,deviceName,hasExistingKeys,const DeepCollectionEquality().hash(error),lastOperation);

@override
String toString() {
  return 'DeviceManagementState(status: $status, devices: $devices, currentDevicePublicKey: $currentDevicePublicKey, revokingDeviceId: $revokingDeviceId, deviceName: $deviceName, hasExistingKeys: $hasExistingKeys, error: $error, lastOperation: $lastOperation)';
}


}

/// @nodoc
abstract mixin class $DeviceManagementStateCopyWith<$Res>  {
  factory $DeviceManagementStateCopyWith(DeviceManagementState value, $Res Function(DeviceManagementState) _then) = _$DeviceManagementStateCopyWithImpl;
@useResult
$Res call({
 UiFlowStatus status, List<AccountDevice> devices, String? currentDevicePublicKey, UuidValue? revokingDeviceId, String? deviceName, bool hasExistingKeys, Object? error, DeviceManagementOperation? lastOperation
});




}
/// @nodoc
class _$DeviceManagementStateCopyWithImpl<$Res>
    implements $DeviceManagementStateCopyWith<$Res> {
  _$DeviceManagementStateCopyWithImpl(this._self, this._then);

  final DeviceManagementState _self;
  final $Res Function(DeviceManagementState) _then;

/// Create a copy of DeviceManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? devices = null,Object? currentDevicePublicKey = freezed,Object? revokingDeviceId = freezed,Object? deviceName = freezed,Object? hasExistingKeys = null,Object? error = freezed,Object? lastOperation = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UiFlowStatus,devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<AccountDevice>,currentDevicePublicKey: freezed == currentDevicePublicKey ? _self.currentDevicePublicKey : currentDevicePublicKey // ignore: cast_nullable_to_non_nullable
as String?,revokingDeviceId: freezed == revokingDeviceId ? _self.revokingDeviceId : revokingDeviceId // ignore: cast_nullable_to_non_nullable
as UuidValue?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,hasExistingKeys: null == hasExistingKeys ? _self.hasExistingKeys : hasExistingKeys // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,lastOperation: freezed == lastOperation ? _self.lastOperation : lastOperation // ignore: cast_nullable_to_non_nullable
as DeviceManagementOperation?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceManagementState].
extension DeviceManagementStatePatterns on DeviceManagementState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceManagementState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceManagementState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceManagementState value)  $default,){
final _that = this;
switch (_that) {
case _DeviceManagementState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceManagementState value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceManagementState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UiFlowStatus status,  List<AccountDevice> devices,  String? currentDevicePublicKey,  UuidValue? revokingDeviceId,  String? deviceName,  bool hasExistingKeys,  Object? error,  DeviceManagementOperation? lastOperation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceManagementState() when $default != null:
return $default(_that.status,_that.devices,_that.currentDevicePublicKey,_that.revokingDeviceId,_that.deviceName,_that.hasExistingKeys,_that.error,_that.lastOperation);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UiFlowStatus status,  List<AccountDevice> devices,  String? currentDevicePublicKey,  UuidValue? revokingDeviceId,  String? deviceName,  bool hasExistingKeys,  Object? error,  DeviceManagementOperation? lastOperation)  $default,) {final _that = this;
switch (_that) {
case _DeviceManagementState():
return $default(_that.status,_that.devices,_that.currentDevicePublicKey,_that.revokingDeviceId,_that.deviceName,_that.hasExistingKeys,_that.error,_that.lastOperation);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UiFlowStatus status,  List<AccountDevice> devices,  String? currentDevicePublicKey,  UuidValue? revokingDeviceId,  String? deviceName,  bool hasExistingKeys,  Object? error,  DeviceManagementOperation? lastOperation)?  $default,) {final _that = this;
switch (_that) {
case _DeviceManagementState() when $default != null:
return $default(_that.status,_that.devices,_that.currentDevicePublicKey,_that.revokingDeviceId,_that.deviceName,_that.hasExistingKeys,_that.error,_that.lastOperation);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceManagementState extends DeviceManagementState {
  const _DeviceManagementState({this.status = UiFlowStatus.idle, final  List<AccountDevice> devices = const [], this.currentDevicePublicKey, this.revokingDeviceId, this.deviceName, this.hasExistingKeys = false, this.error, this.lastOperation}): _devices = devices,super._();
  

@override@JsonKey() final  UiFlowStatus status;
 final  List<AccountDevice> _devices;
@override@JsonKey() List<AccountDevice> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}

@override final  String? currentDevicePublicKey;
@override final  UuidValue? revokingDeviceId;
@override final  String? deviceName;
@override@JsonKey() final  bool hasExistingKeys;
@override final  Object? error;
@override final  DeviceManagementOperation? lastOperation;

/// Create a copy of DeviceManagementState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceManagementStateCopyWith<_DeviceManagementState> get copyWith => __$DeviceManagementStateCopyWithImpl<_DeviceManagementState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceManagementState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._devices, _devices)&&(identical(other.currentDevicePublicKey, currentDevicePublicKey) || other.currentDevicePublicKey == currentDevicePublicKey)&&(identical(other.revokingDeviceId, revokingDeviceId) || other.revokingDeviceId == revokingDeviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.hasExistingKeys, hasExistingKeys) || other.hasExistingKeys == hasExistingKeys)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.lastOperation, lastOperation) || other.lastOperation == lastOperation));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_devices),currentDevicePublicKey,revokingDeviceId,deviceName,hasExistingKeys,const DeepCollectionEquality().hash(error),lastOperation);

@override
String toString() {
  return 'DeviceManagementState(status: $status, devices: $devices, currentDevicePublicKey: $currentDevicePublicKey, revokingDeviceId: $revokingDeviceId, deviceName: $deviceName, hasExistingKeys: $hasExistingKeys, error: $error, lastOperation: $lastOperation)';
}


}

/// @nodoc
abstract mixin class _$DeviceManagementStateCopyWith<$Res> implements $DeviceManagementStateCopyWith<$Res> {
  factory _$DeviceManagementStateCopyWith(_DeviceManagementState value, $Res Function(_DeviceManagementState) _then) = __$DeviceManagementStateCopyWithImpl;
@override @useResult
$Res call({
 UiFlowStatus status, List<AccountDevice> devices, String? currentDevicePublicKey, UuidValue? revokingDeviceId, String? deviceName, bool hasExistingKeys, Object? error, DeviceManagementOperation? lastOperation
});




}
/// @nodoc
class __$DeviceManagementStateCopyWithImpl<$Res>
    implements _$DeviceManagementStateCopyWith<$Res> {
  __$DeviceManagementStateCopyWithImpl(this._self, this._then);

  final _DeviceManagementState _self;
  final $Res Function(_DeviceManagementState) _then;

/// Create a copy of DeviceManagementState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? devices = null,Object? currentDevicePublicKey = freezed,Object? revokingDeviceId = freezed,Object? deviceName = freezed,Object? hasExistingKeys = null,Object? error = freezed,Object? lastOperation = freezed,}) {
  return _then(_DeviceManagementState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UiFlowStatus,devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<AccountDevice>,currentDevicePublicKey: freezed == currentDevicePublicKey ? _self.currentDevicePublicKey : currentDevicePublicKey // ignore: cast_nullable_to_non_nullable
as String?,revokingDeviceId: freezed == revokingDeviceId ? _self.revokingDeviceId : revokingDeviceId // ignore: cast_nullable_to_non_nullable
as UuidValue?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,hasExistingKeys: null == hasExistingKeys ? _self.hasExistingKeys : hasExistingKeys // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,lastOperation: freezed == lastOperation ? _self.lastOperation : lastOperation // ignore: cast_nullable_to_non_nullable
as DeviceManagementOperation?,
  ));
}


}

// dart format on
