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

 CaptureStep get step;/// The pose the viewfinder is capturing ("Pose 1 of 2"/"Pose 2 of 2"
/// over-media bar title, M-9).
 CapturePose get pose;/// The camera acquired and previewing.
 bool get cameraReady;/// Non-null while the 3-2-1 runs (MI-12).
 CountdownCount? get countdown;/// Accepted frames — a pose-2 QC failure keeps [frontPhoto] (M-10:
/// an accepted pose is never discarded; the retake resubmits it
/// with the fresh side frame).
 CapturePhoto? get frontPhoto; CapturePhoto? get sidePhoto;/// Height is canonical cm; the unit is a display preference (MI-13).
/// Pre-filled from the newest session — when on file, the height
/// step is skipped (flows/vault.md §1).
 double? get heightCm; MeasureUnit get unit; bool get heightInvalid;/// The `pending_save` result (results step).
 MeasurementSession? get session;/// First-failure-only QC wire code + its failing pose (qc-fail step).
 String? get qcFailCode; CapturePose? get qcFailPose; bool get saving;/// Save landed — the screen routes to the vault (C7).
 bool get saved;
/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptureStateCopyWith<CaptureState> get copyWith => _$CaptureStateCopyWithImpl<CaptureState>(this as CaptureState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptureState&&(identical(other.step, step) || other.step == step)&&(identical(other.pose, pose) || other.pose == pose)&&(identical(other.cameraReady, cameraReady) || other.cameraReady == cameraReady)&&(identical(other.countdown, countdown) || other.countdown == countdown)&&(identical(other.frontPhoto, frontPhoto) || other.frontPhoto == frontPhoto)&&(identical(other.sidePhoto, sidePhoto) || other.sidePhoto == sidePhoto)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.heightInvalid, heightInvalid) || other.heightInvalid == heightInvalid)&&(identical(other.session, session) || other.session == session)&&(identical(other.qcFailCode, qcFailCode) || other.qcFailCode == qcFailCode)&&(identical(other.qcFailPose, qcFailPose) || other.qcFailPose == qcFailPose)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,step,pose,cameraReady,countdown,frontPhoto,sidePhoto,heightCm,unit,heightInvalid,session,qcFailCode,qcFailPose,saving,saved);

@override
String toString() {
  return 'CaptureState(step: $step, pose: $pose, cameraReady: $cameraReady, countdown: $countdown, frontPhoto: $frontPhoto, sidePhoto: $sidePhoto, heightCm: $heightCm, unit: $unit, heightInvalid: $heightInvalid, session: $session, qcFailCode: $qcFailCode, qcFailPose: $qcFailPose, saving: $saving, saved: $saved)';
}


}

/// @nodoc
abstract mixin class $CaptureStateCopyWith<$Res>  {
  factory $CaptureStateCopyWith(CaptureState value, $Res Function(CaptureState) _then) = _$CaptureStateCopyWithImpl;
@useResult
$Res call({
 CaptureStep step, CapturePose pose, bool cameraReady, CountdownCount? countdown, CapturePhoto? frontPhoto, CapturePhoto? sidePhoto, double? heightCm, MeasureUnit unit, bool heightInvalid, MeasurementSession? session, String? qcFailCode, CapturePose? qcFailPose, bool saving, bool saved
});


$CapturePhotoCopyWith<$Res>? get frontPhoto;$CapturePhotoCopyWith<$Res>? get sidePhoto;$MeasurementSessionCopyWith<$Res>? get session;

}
/// @nodoc
class _$CaptureStateCopyWithImpl<$Res>
    implements $CaptureStateCopyWith<$Res> {
  _$CaptureStateCopyWithImpl(this._self, this._then);

  final CaptureState _self;
  final $Res Function(CaptureState) _then;

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? pose = null,Object? cameraReady = null,Object? countdown = freezed,Object? frontPhoto = freezed,Object? sidePhoto = freezed,Object? heightCm = freezed,Object? unit = null,Object? heightInvalid = null,Object? session = freezed,Object? qcFailCode = freezed,Object? qcFailPose = freezed,Object? saving = null,Object? saved = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CaptureStep,pose: null == pose ? _self.pose : pose // ignore: cast_nullable_to_non_nullable
as CapturePose,cameraReady: null == cameraReady ? _self.cameraReady : cameraReady // ignore: cast_nullable_to_non_nullable
as bool,countdown: freezed == countdown ? _self.countdown : countdown // ignore: cast_nullable_to_non_nullable
as CountdownCount?,frontPhoto: freezed == frontPhoto ? _self.frontPhoto : frontPhoto // ignore: cast_nullable_to_non_nullable
as CapturePhoto?,sidePhoto: freezed == sidePhoto ? _self.sidePhoto : sidePhoto // ignore: cast_nullable_to_non_nullable
as CapturePhoto?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasureUnit,heightInvalid: null == heightInvalid ? _self.heightInvalid : heightInvalid // ignore: cast_nullable_to_non_nullable
as bool,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as MeasurementSession?,qcFailCode: freezed == qcFailCode ? _self.qcFailCode : qcFailCode // ignore: cast_nullable_to_non_nullable
as String?,qcFailPose: freezed == qcFailPose ? _self.qcFailPose : qcFailPose // ignore: cast_nullable_to_non_nullable
as CapturePose?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapturePhotoCopyWith<$Res>? get frontPhoto {
    if (_self.frontPhoto == null) {
    return null;
  }

  return $CapturePhotoCopyWith<$Res>(_self.frontPhoto!, (value) {
    return _then(_self.copyWith(frontPhoto: value));
  });
}/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapturePhotoCopyWith<$Res>? get sidePhoto {
    if (_self.sidePhoto == null) {
    return null;
  }

  return $CapturePhotoCopyWith<$Res>(_self.sidePhoto!, (value) {
    return _then(_self.copyWith(sidePhoto: value));
  });
}/// Create a copy of CaptureState
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CaptureStep step,  CapturePose pose,  bool cameraReady,  CountdownCount? countdown,  CapturePhoto? frontPhoto,  CapturePhoto? sidePhoto,  double? heightCm,  MeasureUnit unit,  bool heightInvalid,  MeasurementSession? session,  String? qcFailCode,  CapturePose? qcFailPose,  bool saving,  bool saved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptureState() when $default != null:
return $default(_that.step,_that.pose,_that.cameraReady,_that.countdown,_that.frontPhoto,_that.sidePhoto,_that.heightCm,_that.unit,_that.heightInvalid,_that.session,_that.qcFailCode,_that.qcFailPose,_that.saving,_that.saved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CaptureStep step,  CapturePose pose,  bool cameraReady,  CountdownCount? countdown,  CapturePhoto? frontPhoto,  CapturePhoto? sidePhoto,  double? heightCm,  MeasureUnit unit,  bool heightInvalid,  MeasurementSession? session,  String? qcFailCode,  CapturePose? qcFailPose,  bool saving,  bool saved)  $default,) {final _that = this;
switch (_that) {
case _CaptureState():
return $default(_that.step,_that.pose,_that.cameraReady,_that.countdown,_that.frontPhoto,_that.sidePhoto,_that.heightCm,_that.unit,_that.heightInvalid,_that.session,_that.qcFailCode,_that.qcFailPose,_that.saving,_that.saved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CaptureStep step,  CapturePose pose,  bool cameraReady,  CountdownCount? countdown,  CapturePhoto? frontPhoto,  CapturePhoto? sidePhoto,  double? heightCm,  MeasureUnit unit,  bool heightInvalid,  MeasurementSession? session,  String? qcFailCode,  CapturePose? qcFailPose,  bool saving,  bool saved)?  $default,) {final _that = this;
switch (_that) {
case _CaptureState() when $default != null:
return $default(_that.step,_that.pose,_that.cameraReady,_that.countdown,_that.frontPhoto,_that.sidePhoto,_that.heightCm,_that.unit,_that.heightInvalid,_that.session,_that.qcFailCode,_that.qcFailPose,_that.saving,_that.saved);case _:
  return null;

}
}

}

/// @nodoc


class _CaptureState extends CaptureState {
  const _CaptureState({this.step = CaptureStep.camera, this.pose = CapturePose.front, this.cameraReady = false, this.countdown, this.frontPhoto, this.sidePhoto, this.heightCm, this.unit = MeasureUnit.cm, this.heightInvalid = false, this.session, this.qcFailCode, this.qcFailPose, this.saving = false, this.saved = false}): super._();
  

@override@JsonKey() final  CaptureStep step;
/// The pose the viewfinder is capturing ("Pose 1 of 2"/"Pose 2 of 2"
/// over-media bar title, M-9).
@override@JsonKey() final  CapturePose pose;
/// The camera acquired and previewing.
@override@JsonKey() final  bool cameraReady;
/// Non-null while the 3-2-1 runs (MI-12).
@override final  CountdownCount? countdown;
/// Accepted frames — a pose-2 QC failure keeps [frontPhoto] (M-10:
/// an accepted pose is never discarded; the retake resubmits it
/// with the fresh side frame).
@override final  CapturePhoto? frontPhoto;
@override final  CapturePhoto? sidePhoto;
/// Height is canonical cm; the unit is a display preference (MI-13).
/// Pre-filled from the newest session — when on file, the height
/// step is skipped (flows/vault.md §1).
@override final  double? heightCm;
@override@JsonKey() final  MeasureUnit unit;
@override@JsonKey() final  bool heightInvalid;
/// The `pending_save` result (results step).
@override final  MeasurementSession? session;
/// First-failure-only QC wire code + its failing pose (qc-fail step).
@override final  String? qcFailCode;
@override final  CapturePose? qcFailPose;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptureState&&(identical(other.step, step) || other.step == step)&&(identical(other.pose, pose) || other.pose == pose)&&(identical(other.cameraReady, cameraReady) || other.cameraReady == cameraReady)&&(identical(other.countdown, countdown) || other.countdown == countdown)&&(identical(other.frontPhoto, frontPhoto) || other.frontPhoto == frontPhoto)&&(identical(other.sidePhoto, sidePhoto) || other.sidePhoto == sidePhoto)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.heightInvalid, heightInvalid) || other.heightInvalid == heightInvalid)&&(identical(other.session, session) || other.session == session)&&(identical(other.qcFailCode, qcFailCode) || other.qcFailCode == qcFailCode)&&(identical(other.qcFailPose, qcFailPose) || other.qcFailPose == qcFailPose)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,step,pose,cameraReady,countdown,frontPhoto,sidePhoto,heightCm,unit,heightInvalid,session,qcFailCode,qcFailPose,saving,saved);

@override
String toString() {
  return 'CaptureState(step: $step, pose: $pose, cameraReady: $cameraReady, countdown: $countdown, frontPhoto: $frontPhoto, sidePhoto: $sidePhoto, heightCm: $heightCm, unit: $unit, heightInvalid: $heightInvalid, session: $session, qcFailCode: $qcFailCode, qcFailPose: $qcFailPose, saving: $saving, saved: $saved)';
}


}

/// @nodoc
abstract mixin class _$CaptureStateCopyWith<$Res> implements $CaptureStateCopyWith<$Res> {
  factory _$CaptureStateCopyWith(_CaptureState value, $Res Function(_CaptureState) _then) = __$CaptureStateCopyWithImpl;
@override @useResult
$Res call({
 CaptureStep step, CapturePose pose, bool cameraReady, CountdownCount? countdown, CapturePhoto? frontPhoto, CapturePhoto? sidePhoto, double? heightCm, MeasureUnit unit, bool heightInvalid, MeasurementSession? session, String? qcFailCode, CapturePose? qcFailPose, bool saving, bool saved
});


@override $CapturePhotoCopyWith<$Res>? get frontPhoto;@override $CapturePhotoCopyWith<$Res>? get sidePhoto;@override $MeasurementSessionCopyWith<$Res>? get session;

}
/// @nodoc
class __$CaptureStateCopyWithImpl<$Res>
    implements _$CaptureStateCopyWith<$Res> {
  __$CaptureStateCopyWithImpl(this._self, this._then);

  final _CaptureState _self;
  final $Res Function(_CaptureState) _then;

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? pose = null,Object? cameraReady = null,Object? countdown = freezed,Object? frontPhoto = freezed,Object? sidePhoto = freezed,Object? heightCm = freezed,Object? unit = null,Object? heightInvalid = null,Object? session = freezed,Object? qcFailCode = freezed,Object? qcFailPose = freezed,Object? saving = null,Object? saved = null,}) {
  return _then(_CaptureState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CaptureStep,pose: null == pose ? _self.pose : pose // ignore: cast_nullable_to_non_nullable
as CapturePose,cameraReady: null == cameraReady ? _self.cameraReady : cameraReady // ignore: cast_nullable_to_non_nullable
as bool,countdown: freezed == countdown ? _self.countdown : countdown // ignore: cast_nullable_to_non_nullable
as CountdownCount?,frontPhoto: freezed == frontPhoto ? _self.frontPhoto : frontPhoto // ignore: cast_nullable_to_non_nullable
as CapturePhoto?,sidePhoto: freezed == sidePhoto ? _self.sidePhoto : sidePhoto // ignore: cast_nullable_to_non_nullable
as CapturePhoto?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasureUnit,heightInvalid: null == heightInvalid ? _self.heightInvalid : heightInvalid // ignore: cast_nullable_to_non_nullable
as bool,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as MeasurementSession?,qcFailCode: freezed == qcFailCode ? _self.qcFailCode : qcFailCode // ignore: cast_nullable_to_non_nullable
as String?,qcFailPose: freezed == qcFailPose ? _self.qcFailPose : qcFailPose // ignore: cast_nullable_to_non_nullable
as CapturePose?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapturePhotoCopyWith<$Res>? get frontPhoto {
    if (_self.frontPhoto == null) {
    return null;
  }

  return $CapturePhotoCopyWith<$Res>(_self.frontPhoto!, (value) {
    return _then(_self.copyWith(frontPhoto: value));
  });
}/// Create a copy of CaptureState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapturePhotoCopyWith<$Res>? get sidePhoto {
    if (_self.sidePhoto == null) {
    return null;
  }

  return $CapturePhotoCopyWith<$Res>(_self.sidePhoto!, (value) {
    return _then(_self.copyWith(sidePhoto: value));
  });
}/// Create a copy of CaptureState
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
