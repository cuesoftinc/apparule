// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capture_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CaptureState {

 CaptureStep get step;/// Height is canonical cm; the unit is a display preference (MI-13).
 double? get heightCm; MeasureUnit get unit; bool get heightInvalid;/// The camera acquired and previewing.
 bool get cameraReady;/// Non-null while the 3-2-1 runs (MI-12).
 CountdownCount? get countdown;/// The captured frame — the processing constellation draws over it.
 Uint8List? get photoBytes;/// The `pending_save` result (results step).
 MeasurementSession? get session;/// First-failure-only QC wire code (qc-fail step).
 String? get qcFailCode; bool get saving;/// Save landed — the screen routes to the vault (C7).
 bool get saved;
/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptureStateCopyWith<CaptureState> get copyWith => _$CaptureStateCopyWithImpl<CaptureState>(this as CaptureState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptureState&&(identical(other.step, step) || other.step == step)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.heightInvalid, heightInvalid) || other.heightInvalid == heightInvalid)&&(identical(other.cameraReady, cameraReady) || other.cameraReady == cameraReady)&&(identical(other.countdown, countdown) || other.countdown == countdown)&&const DeepCollectionEquality().equals(other.photoBytes, photoBytes)&&(identical(other.session, session) || other.session == session)&&(identical(other.qcFailCode, qcFailCode) || other.qcFailCode == qcFailCode)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,step,heightCm,unit,heightInvalid,cameraReady,countdown,const DeepCollectionEquality().hash(photoBytes),session,qcFailCode,saving,saved);

@override
String toString() {
  return 'CaptureState(step: $step, heightCm: $heightCm, unit: $unit, heightInvalid: $heightInvalid, cameraReady: $cameraReady, countdown: $countdown, photoBytes: $photoBytes, session: $session, qcFailCode: $qcFailCode, saving: $saving, saved: $saved)';
}


}

/// @nodoc
abstract mixin class $CaptureStateCopyWith<$Res>  {
  factory $CaptureStateCopyWith(CaptureState value, $Res Function(CaptureState) _then) = _$CaptureStateCopyWithImpl;
@useResult
$Res call({
 CaptureStep step, double? heightCm, MeasureUnit unit, bool heightInvalid, bool cameraReady, CountdownCount? countdown, Uint8List? photoBytes, MeasurementSession? session, String? qcFailCode, bool saving, bool saved
});


$MeasurementSessionCopyWith<$Res>? get session;

}
/// @nodoc
class _$CaptureStateCopyWithImpl<$Res>
    implements $CaptureStateCopyWith<$Res> {
  _$CaptureStateCopyWithImpl(this._self, this._then);

  final CaptureState _self;
  final $Res Function(CaptureState) _then;

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? heightCm = freezed,Object? unit = null,Object? heightInvalid = null,Object? cameraReady = null,Object? countdown = freezed,Object? photoBytes = freezed,Object? session = freezed,Object? qcFailCode = freezed,Object? saving = null,Object? saved = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CaptureStep,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasureUnit,heightInvalid: null == heightInvalid ? _self.heightInvalid : heightInvalid // ignore: cast_nullable_to_non_nullable
as bool,cameraReady: null == cameraReady ? _self.cameraReady : cameraReady // ignore: cast_nullable_to_non_nullable
as bool,countdown: freezed == countdown ? _self.countdown : countdown // ignore: cast_nullable_to_non_nullable
as CountdownCount?,photoBytes: freezed == photoBytes ? _self.photoBytes : photoBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as MeasurementSession?,qcFailCode: freezed == qcFailCode ? _self.qcFailCode : qcFailCode // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $MeasurementSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [CaptureState].
extension CaptureStatePatterns on CaptureState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaptureState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaptureState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaptureState value)  $default,){
final _that = this;
switch (_that) {
case _CaptureState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaptureState value)?  $default,){
final _that = this;
switch (_that) {
case _CaptureState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CaptureStep step,  double? heightCm,  MeasureUnit unit,  bool heightInvalid,  bool cameraReady,  CountdownCount? countdown,  Uint8List? photoBytes,  MeasurementSession? session,  String? qcFailCode,  bool saving,  bool saved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptureState() when $default != null:
return $default(_that.step,_that.heightCm,_that.unit,_that.heightInvalid,_that.cameraReady,_that.countdown,_that.photoBytes,_that.session,_that.qcFailCode,_that.saving,_that.saved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CaptureStep step,  double? heightCm,  MeasureUnit unit,  bool heightInvalid,  bool cameraReady,  CountdownCount? countdown,  Uint8List? photoBytes,  MeasurementSession? session,  String? qcFailCode,  bool saving,  bool saved)  $default,) {final _that = this;
switch (_that) {
case _CaptureState():
return $default(_that.step,_that.heightCm,_that.unit,_that.heightInvalid,_that.cameraReady,_that.countdown,_that.photoBytes,_that.session,_that.qcFailCode,_that.saving,_that.saved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CaptureStep step,  double? heightCm,  MeasureUnit unit,  bool heightInvalid,  bool cameraReady,  CountdownCount? countdown,  Uint8List? photoBytes,  MeasurementSession? session,  String? qcFailCode,  bool saving,  bool saved)?  $default,) {final _that = this;
switch (_that) {
case _CaptureState() when $default != null:
return $default(_that.step,_that.heightCm,_that.unit,_that.heightInvalid,_that.cameraReady,_that.countdown,_that.photoBytes,_that.session,_that.qcFailCode,_that.saving,_that.saved);case _:
  return null;

}
}

}

/// @nodoc


class _CaptureState implements CaptureState {
  const _CaptureState({this.step = CaptureStep.height, this.heightCm, this.unit = MeasureUnit.cm, this.heightInvalid = false, this.cameraReady = false, this.countdown, this.photoBytes, this.session, this.qcFailCode, this.saving = false, this.saved = false});
  

@override@JsonKey() final  CaptureStep step;
/// Height is canonical cm; the unit is a display preference (MI-13).
@override final  double? heightCm;
@override@JsonKey() final  MeasureUnit unit;
@override@JsonKey() final  bool heightInvalid;
/// The camera acquired and previewing.
@override@JsonKey() final  bool cameraReady;
/// Non-null while the 3-2-1 runs (MI-12).
@override final  CountdownCount? countdown;
/// The captured frame — the processing constellation draws over it.
@override final  Uint8List? photoBytes;
/// The `pending_save` result (results step).
@override final  MeasurementSession? session;
/// First-failure-only QC wire code (qc-fail step).
@override final  String? qcFailCode;
@override@JsonKey() final  bool saving;
/// Save landed — the screen routes to the vault (C7).
@override@JsonKey() final  bool saved;

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaptureStateCopyWith<_CaptureState> get copyWith => __$CaptureStateCopyWithImpl<_CaptureState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptureState&&(identical(other.step, step) || other.step == step)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.heightInvalid, heightInvalid) || other.heightInvalid == heightInvalid)&&(identical(other.cameraReady, cameraReady) || other.cameraReady == cameraReady)&&(identical(other.countdown, countdown) || other.countdown == countdown)&&const DeepCollectionEquality().equals(other.photoBytes, photoBytes)&&(identical(other.session, session) || other.session == session)&&(identical(other.qcFailCode, qcFailCode) || other.qcFailCode == qcFailCode)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,step,heightCm,unit,heightInvalid,cameraReady,countdown,const DeepCollectionEquality().hash(photoBytes),session,qcFailCode,saving,saved);

@override
String toString() {
  return 'CaptureState(step: $step, heightCm: $heightCm, unit: $unit, heightInvalid: $heightInvalid, cameraReady: $cameraReady, countdown: $countdown, photoBytes: $photoBytes, session: $session, qcFailCode: $qcFailCode, saving: $saving, saved: $saved)';
}


}

/// @nodoc
abstract mixin class _$CaptureStateCopyWith<$Res> implements $CaptureStateCopyWith<$Res> {
  factory _$CaptureStateCopyWith(_CaptureState value, $Res Function(_CaptureState) _then) = __$CaptureStateCopyWithImpl;
@override @useResult
$Res call({
 CaptureStep step, double? heightCm, MeasureUnit unit, bool heightInvalid, bool cameraReady, CountdownCount? countdown, Uint8List? photoBytes, MeasurementSession? session, String? qcFailCode, bool saving, bool saved
});


@override $MeasurementSessionCopyWith<$Res>? get session;

}
/// @nodoc
class __$CaptureStateCopyWithImpl<$Res>
    implements _$CaptureStateCopyWith<$Res> {
  __$CaptureStateCopyWithImpl(this._self, this._then);

  final _CaptureState _self;
  final $Res Function(_CaptureState) _then;

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? heightCm = freezed,Object? unit = null,Object? heightInvalid = null,Object? cameraReady = null,Object? countdown = freezed,Object? photoBytes = freezed,Object? session = freezed,Object? qcFailCode = freezed,Object? saving = null,Object? saved = null,}) {
  return _then(_CaptureState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CaptureStep,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasureUnit,heightInvalid: null == heightInvalid ? _self.heightInvalid : heightInvalid // ignore: cast_nullable_to_non_nullable
as bool,cameraReady: null == cameraReady ? _self.cameraReady : cameraReady // ignore: cast_nullable_to_non_nullable
as bool,countdown: freezed == countdown ? _self.countdown : countdown // ignore: cast_nullable_to_non_nullable
as CountdownCount?,photoBytes: freezed == photoBytes ? _self.photoBytes : photoBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as MeasurementSession?,qcFailCode: freezed == qcFailCode ? _self.qcFailCode : qcFailCode // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $MeasurementSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
