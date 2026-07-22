// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capture_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CapturePhoto {

 Uint8List get bytes;/// Dev seam: the fake camera stamps which sample-frame scenario this
/// is (`capture_samples.json`), and `MeasurementRepositoryFake` runs
/// the QC table over that scenario's simulated metrics. Live-camera
/// photos carry `null` and evaluate as the passing defaults.
 String? get sampleId;
/// Create a copy of CapturePhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapturePhotoCopyWith<CapturePhoto> get copyWith => _$CapturePhotoCopyWithImpl<CapturePhoto>(this as CapturePhoto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapturePhoto&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.sampleId, sampleId) || other.sampleId == sampleId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes),sampleId);

@override
String toString() {
  return 'CapturePhoto(bytes: $bytes, sampleId: $sampleId)';
}


}

/// @nodoc
abstract mixin class $CapturePhotoCopyWith<$Res>  {
  factory $CapturePhotoCopyWith(CapturePhoto value, $Res Function(CapturePhoto) _then) = _$CapturePhotoCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes, String? sampleId
});




}
/// @nodoc
class _$CapturePhotoCopyWithImpl<$Res>
    implements $CapturePhotoCopyWith<$Res> {
  _$CapturePhotoCopyWithImpl(this._self, this._then);

  final CapturePhoto _self;
  final $Res Function(CapturePhoto) _then;

/// Create a copy of CapturePhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bytes = null,Object? sampleId = freezed,}) {
  return _then(_self.copyWith(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,sampleId: freezed == sampleId ? _self.sampleId : sampleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CapturePhoto].
extension CapturePhotoPatterns on CapturePhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapturePhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapturePhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapturePhoto value)  $default,){
final _that = this;
switch (_that) {
case _CapturePhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapturePhoto value)?  $default,){
final _that = this;
switch (_that) {
case _CapturePhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uint8List bytes,  String? sampleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapturePhoto() when $default != null:
return $default(_that.bytes,_that.sampleId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uint8List bytes,  String? sampleId)  $default,) {final _that = this;
switch (_that) {
case _CapturePhoto():
return $default(_that.bytes,_that.sampleId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uint8List bytes,  String? sampleId)?  $default,) {final _that = this;
switch (_that) {
case _CapturePhoto() when $default != null:
return $default(_that.bytes,_that.sampleId);case _:
  return null;

}
}

}

/// @nodoc


class _CapturePhoto implements CapturePhoto {
  const _CapturePhoto({required this.bytes, this.sampleId});
  

@override final  Uint8List bytes;
/// Dev seam: the fake camera stamps which sample-frame scenario this
/// is (`capture_samples.json`), and `MeasurementRepositoryFake` runs
/// the QC table over that scenario's simulated metrics. Live-camera
/// photos carry `null` and evaluate as the passing defaults.
@override final  String? sampleId;

/// Create a copy of CapturePhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapturePhotoCopyWith<_CapturePhoto> get copyWith => __$CapturePhotoCopyWithImpl<_CapturePhoto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapturePhoto&&const DeepCollectionEquality().equals(other.bytes, bytes)&&(identical(other.sampleId, sampleId) || other.sampleId == sampleId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes),sampleId);

@override
String toString() {
  return 'CapturePhoto(bytes: $bytes, sampleId: $sampleId)';
}


}

/// @nodoc
abstract mixin class _$CapturePhotoCopyWith<$Res> implements $CapturePhotoCopyWith<$Res> {
  factory _$CapturePhotoCopyWith(_CapturePhoto value, $Res Function(_CapturePhoto) _then) = __$CapturePhotoCopyWithImpl;
@override @useResult
$Res call({
 Uint8List bytes, String? sampleId
});




}
/// @nodoc
class __$CapturePhotoCopyWithImpl<$Res>
    implements _$CapturePhotoCopyWith<$Res> {
  __$CapturePhotoCopyWithImpl(this._self, this._then);

  final _CapturePhoto _self;
  final $Res Function(_CapturePhoto) _then;

/// Create a copy of CapturePhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? sampleId = freezed,}) {
  return _then(_CapturePhoto(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,sampleId: freezed == sampleId ? _self.sampleId : sampleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
