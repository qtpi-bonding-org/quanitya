// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnalysisInput {

/// User's natural language description of what they want to analyze
 String get intent;/// The starting data type for the analysis script
 AnalysisDataType get startType;
/// Create a copy of AnalysisInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisInputCopyWith<AnalysisInput> get copyWith => _$AnalysisInputCopyWithImpl<AnalysisInput>(this as AnalysisInput, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisInput&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.startType, startType) || other.startType == startType));
}


@override
int get hashCode => Object.hash(runtimeType,intent,startType);

@override
String toString() {
  return 'AnalysisInput(intent: $intent, startType: $startType)';
}


}

/// @nodoc
abstract mixin class $AnalysisInputCopyWith<$Res>  {
  factory $AnalysisInputCopyWith(AnalysisInput value, $Res Function(AnalysisInput) _then) = _$AnalysisInputCopyWithImpl;
@useResult
$Res call({
 String intent, AnalysisDataType startType
});




}
/// @nodoc
class _$AnalysisInputCopyWithImpl<$Res>
    implements $AnalysisInputCopyWith<$Res> {
  _$AnalysisInputCopyWithImpl(this._self, this._then);

  final AnalysisInput _self;
  final $Res Function(AnalysisInput) _then;

/// Create a copy of AnalysisInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intent = null,Object? startType = null,}) {
  return _then(_self.copyWith(
intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as String,startType: null == startType ? _self.startType : startType // ignore: cast_nullable_to_non_nullable
as AnalysisDataType,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalysisInput].
extension AnalysisInputPatterns on AnalysisInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalysisInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalysisInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalysisInput value)  $default,){
final _that = this;
switch (_that) {
case _AnalysisInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalysisInput value)?  $default,){
final _that = this;
switch (_that) {
case _AnalysisInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String intent,  AnalysisDataType startType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalysisInput() when $default != null:
return $default(_that.intent,_that.startType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String intent,  AnalysisDataType startType)  $default,) {final _that = this;
switch (_that) {
case _AnalysisInput():
return $default(_that.intent,_that.startType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String intent,  AnalysisDataType startType)?  $default,) {final _that = this;
switch (_that) {
case _AnalysisInput() when $default != null:
return $default(_that.intent,_that.startType);case _:
  return null;

}
}

}

/// @nodoc


class _AnalysisInput extends AnalysisInput {
  const _AnalysisInput({required this.intent, required this.startType}): super._();
  

/// User's natural language description of what they want to analyze
@override final  String intent;
/// The starting data type for the analysis script
@override final  AnalysisDataType startType;

/// Create a copy of AnalysisInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalysisInputCopyWith<_AnalysisInput> get copyWith => __$AnalysisInputCopyWithImpl<_AnalysisInput>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalysisInput&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.startType, startType) || other.startType == startType));
}


@override
int get hashCode => Object.hash(runtimeType,intent,startType);

@override
String toString() {
  return 'AnalysisInput(intent: $intent, startType: $startType)';
}


}

/// @nodoc
abstract mixin class _$AnalysisInputCopyWith<$Res> implements $AnalysisInputCopyWith<$Res> {
  factory _$AnalysisInputCopyWith(_AnalysisInput value, $Res Function(_AnalysisInput) _then) = __$AnalysisInputCopyWithImpl;
@override @useResult
$Res call({
 String intent, AnalysisDataType startType
});




}
/// @nodoc
class __$AnalysisInputCopyWithImpl<$Res>
    implements _$AnalysisInputCopyWith<$Res> {
  __$AnalysisInputCopyWithImpl(this._self, this._then);

  final _AnalysisInput _self;
  final $Res Function(_AnalysisInput) _then;

/// Create a copy of AnalysisInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intent = null,Object? startType = null,}) {
  return _then(_AnalysisInput(
intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as String,startType: null == startType ? _self.startType : startType // ignore: cast_nullable_to_non_nullable
as AnalysisDataType,
  ));
}


}

// dart format on
