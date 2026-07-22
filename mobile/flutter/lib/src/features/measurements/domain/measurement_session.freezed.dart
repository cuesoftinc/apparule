// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Measurement {

 String get id; String get name; double get valueCm;/// Per-measurement confidence (capture-qc.md §4) — `< 0.7` renders
/// the low-confidence chip; manual entries carry `null` (human truth
/// isn't scored).
 double? get confidence;/// Wire provenance (`pipeline` / `manual_correction`, api.md §2) —
/// carried for shape parity; the UI's scan/manual axis derives from
/// the session method.
 String get source;
/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeasurementCopyWith<Measurement> get copyWith => _$MeasurementCopyWithImpl<Measurement>(this as Measurement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Measurement&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.valueCm, valueCm) || other.valueCm == valueCm)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,valueCm,confidence,source);

@override
String toString() {
  return 'Measurement(id: $id, name: $name, valueCm: $valueCm, confidence: $confidence, source: $source)';
}


}

/// @nodoc
abstract mixin class $MeasurementCopyWith<$Res>  {
  factory $MeasurementCopyWith(Measurement value, $Res Function(Measurement) _then) = _$MeasurementCopyWithImpl;
@useResult
$Res call({
 String id, String name, double valueCm, double? confidence, String source
});




}
/// @nodoc
class _$MeasurementCopyWithImpl<$Res>
    implements $MeasurementCopyWith<$Res> {
  _$MeasurementCopyWithImpl(this._self, this._then);

  final Measurement _self;
  final $Res Function(Measurement) _then;

/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? valueCm = null,Object? confidence = freezed,Object? source = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,valueCm: null == valueCm ? _self.valueCm : valueCm // ignore: cast_nullable_to_non_nullable
as double,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Measurement].
extension MeasurementPatterns on Measurement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Measurement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Measurement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Measurement value)  $default,){
final _that = this;
switch (_that) {
case _Measurement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Measurement value)?  $default,){
final _that = this;
switch (_that) {
case _Measurement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double valueCm,  double? confidence,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Measurement() when $default != null:
return $default(_that.id,_that.name,_that.valueCm,_that.confidence,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double valueCm,  double? confidence,  String source)  $default,) {final _that = this;
switch (_that) {
case _Measurement():
return $default(_that.id,_that.name,_that.valueCm,_that.confidence,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double valueCm,  double? confidence,  String source)?  $default,) {final _that = this;
switch (_that) {
case _Measurement() when $default != null:
return $default(_that.id,_that.name,_that.valueCm,_that.confidence,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _Measurement implements Measurement {
  const _Measurement({required this.id, required this.name, required this.valueCm, this.confidence, this.source = 'pipeline'});
  

@override final  String id;
@override final  String name;
@override final  double valueCm;
/// Per-measurement confidence (capture-qc.md §4) — `< 0.7` renders
/// the low-confidence chip; manual entries carry `null` (human truth
/// isn't scored).
@override final  double? confidence;
/// Wire provenance (`pipeline` / `manual_correction`, api.md §2) —
/// carried for shape parity; the UI's scan/manual axis derives from
/// the session method.
@override@JsonKey() final  String source;

/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeasurementCopyWith<_Measurement> get copyWith => __$MeasurementCopyWithImpl<_Measurement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Measurement&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.valueCm, valueCm) || other.valueCm == valueCm)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,valueCm,confidence,source);

@override
String toString() {
  return 'Measurement(id: $id, name: $name, valueCm: $valueCm, confidence: $confidence, source: $source)';
}


}

/// @nodoc
abstract mixin class _$MeasurementCopyWith<$Res> implements $MeasurementCopyWith<$Res> {
  factory _$MeasurementCopyWith(_Measurement value, $Res Function(_Measurement) _then) = __$MeasurementCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double valueCm, double? confidence, String source
});




}
/// @nodoc
class __$MeasurementCopyWithImpl<$Res>
    implements _$MeasurementCopyWith<$Res> {
  __$MeasurementCopyWithImpl(this._self, this._then);

  final _Measurement _self;
  final $Res Function(_Measurement) _then;

/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? valueCm = null,Object? confidence = freezed,Object? source = null,}) {
  return _then(_Measurement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,valueCm: null == valueCm ? _self.valueCm : valueCm // ignore: cast_nullable_to_non_nullable
as double,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MeasurementSession {

 String get id;/// Wire method identifier: `mediapipe_2d_v2` (current pipeline,
/// capture-qc.md §3), `manual`, or historical `mediapipe_2d` — kept
/// as the wire string because the set is additive by design (§10:
/// the SMPL method joins without rework).
 String get method; SessionStatus get status; List<Measurement> get measurements; DateTime get createdAt;/// The height the session froze (`user_height_cm`, api.md
/// `POST /measure`); changing your height never retro-scales old
/// sessions (flows/vault.md §1). Manual sessions may omit it.
 double? get inputHeightCm;
/// Create a copy of MeasurementSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeasurementSessionCopyWith<MeasurementSession> get copyWith => _$MeasurementSessionCopyWithImpl<MeasurementSession>(this as MeasurementSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeasurementSession&&(identical(other.id, id) || other.id == id)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.measurements, measurements)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.inputHeightCm, inputHeightCm) || other.inputHeightCm == inputHeightCm));
}


@override
int get hashCode => Object.hash(runtimeType,id,method,status,const DeepCollectionEquality().hash(measurements),createdAt,inputHeightCm);

@override
String toString() {
  return 'MeasurementSession(id: $id, method: $method, status: $status, measurements: $measurements, createdAt: $createdAt, inputHeightCm: $inputHeightCm)';
}


}

/// @nodoc
abstract mixin class $MeasurementSessionCopyWith<$Res>  {
  factory $MeasurementSessionCopyWith(MeasurementSession value, $Res Function(MeasurementSession) _then) = _$MeasurementSessionCopyWithImpl;
@useResult
$Res call({
 String id, String method, SessionStatus status, List<Measurement> measurements, DateTime createdAt, double? inputHeightCm
});




}
/// @nodoc
class _$MeasurementSessionCopyWithImpl<$Res>
    implements $MeasurementSessionCopyWith<$Res> {
  _$MeasurementSessionCopyWithImpl(this._self, this._then);

  final MeasurementSession _self;
  final $Res Function(MeasurementSession) _then;

/// Create a copy of MeasurementSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? method = null,Object? status = null,Object? measurements = null,Object? createdAt = null,Object? inputHeightCm = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,measurements: null == measurements ? _self.measurements : measurements // ignore: cast_nullable_to_non_nullable
as List<Measurement>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,inputHeightCm: freezed == inputHeightCm ? _self.inputHeightCm : inputHeightCm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeasurementSession].
extension MeasurementSessionPatterns on MeasurementSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeasurementSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeasurementSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeasurementSession value)  $default,){
final _that = this;
switch (_that) {
case _MeasurementSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeasurementSession value)?  $default,){
final _that = this;
switch (_that) {
case _MeasurementSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String method,  SessionStatus status,  List<Measurement> measurements,  DateTime createdAt,  double? inputHeightCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeasurementSession() when $default != null:
return $default(_that.id,_that.method,_that.status,_that.measurements,_that.createdAt,_that.inputHeightCm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String method,  SessionStatus status,  List<Measurement> measurements,  DateTime createdAt,  double? inputHeightCm)  $default,) {final _that = this;
switch (_that) {
case _MeasurementSession():
return $default(_that.id,_that.method,_that.status,_that.measurements,_that.createdAt,_that.inputHeightCm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String method,  SessionStatus status,  List<Measurement> measurements,  DateTime createdAt,  double? inputHeightCm)?  $default,) {final _that = this;
switch (_that) {
case _MeasurementSession() when $default != null:
return $default(_that.id,_that.method,_that.status,_that.measurements,_that.createdAt,_that.inputHeightCm);case _:
  return null;

}
}

}

/// @nodoc


class _MeasurementSession extends MeasurementSession {
  const _MeasurementSession({required this.id, required this.method, required this.status, required final  List<Measurement> measurements, required this.createdAt, this.inputHeightCm}): _measurements = measurements,super._();
  

@override final  String id;
/// Wire method identifier: `mediapipe_2d_v2` (current pipeline,
/// capture-qc.md §3), `manual`, or historical `mediapipe_2d` — kept
/// as the wire string because the set is additive by design (§10:
/// the SMPL method joins without rework).
@override final  String method;
@override final  SessionStatus status;
 final  List<Measurement> _measurements;
@override List<Measurement> get measurements {
  if (_measurements is EqualUnmodifiableListView) return _measurements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_measurements);
}

@override final  DateTime createdAt;
/// The height the session froze (`user_height_cm`, api.md
/// `POST /measure`); changing your height never retro-scales old
/// sessions (flows/vault.md §1). Manual sessions may omit it.
@override final  double? inputHeightCm;

/// Create a copy of MeasurementSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeasurementSessionCopyWith<_MeasurementSession> get copyWith => __$MeasurementSessionCopyWithImpl<_MeasurementSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeasurementSession&&(identical(other.id, id) || other.id == id)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._measurements, _measurements)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.inputHeightCm, inputHeightCm) || other.inputHeightCm == inputHeightCm));
}


@override
int get hashCode => Object.hash(runtimeType,id,method,status,const DeepCollectionEquality().hash(_measurements),createdAt,inputHeightCm);

@override
String toString() {
  return 'MeasurementSession(id: $id, method: $method, status: $status, measurements: $measurements, createdAt: $createdAt, inputHeightCm: $inputHeightCm)';
}


}

/// @nodoc
abstract mixin class _$MeasurementSessionCopyWith<$Res> implements $MeasurementSessionCopyWith<$Res> {
  factory _$MeasurementSessionCopyWith(_MeasurementSession value, $Res Function(_MeasurementSession) _then) = __$MeasurementSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String method, SessionStatus status, List<Measurement> measurements, DateTime createdAt, double? inputHeightCm
});




}
/// @nodoc
class __$MeasurementSessionCopyWithImpl<$Res>
    implements _$MeasurementSessionCopyWith<$Res> {
  __$MeasurementSessionCopyWithImpl(this._self, this._then);

  final _MeasurementSession _self;
  final $Res Function(_MeasurementSession) _then;

/// Create a copy of MeasurementSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? method = null,Object? status = null,Object? measurements = null,Object? createdAt = null,Object? inputHeightCm = freezed,}) {
  return _then(_MeasurementSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,measurements: null == measurements ? _self._measurements : measurements // ignore: cast_nullable_to_non_nullable
as List<Measurement>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,inputHeightCm: freezed == inputHeightCm ? _self.inputHeightCm : inputHeightCm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
