// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manual_entry_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ManualEntryState {

/// Entered values, canonical cm (MI-13: unit is display-only,
/// inches by default — A-9).
 Map<String, double> get valuesCm; MeasureUnit get unit; bool get saving;/// Save landed — the screen routes to the vault (C7).
 bool get saved;
/// Create a copy of ManualEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManualEntryStateCopyWith<ManualEntryState> get copyWith => _$ManualEntryStateCopyWithImpl<ManualEntryState>(this as ManualEntryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualEntryState&&const DeepCollectionEquality().equals(other.valuesCm, valuesCm)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(valuesCm),unit,saving,saved);

@override
String toString() {
  return 'ManualEntryState(valuesCm: $valuesCm, unit: $unit, saving: $saving, saved: $saved)';
}


}

/// @nodoc
abstract mixin class $ManualEntryStateCopyWith<$Res>  {
  factory $ManualEntryStateCopyWith(ManualEntryState value, $Res Function(ManualEntryState) _then) = _$ManualEntryStateCopyWithImpl;
@useResult
$Res call({
 Map<String, double> valuesCm, MeasureUnit unit, bool saving, bool saved
});




}
/// @nodoc
class _$ManualEntryStateCopyWithImpl<$Res>
    implements $ManualEntryStateCopyWith<$Res> {
  _$ManualEntryStateCopyWithImpl(this._self, this._then);

  final ManualEntryState _self;
  final $Res Function(ManualEntryState) _then;

/// Create a copy of ManualEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? valuesCm = null,Object? unit = null,Object? saving = null,Object? saved = null,}) {
  return _then(_self.copyWith(
valuesCm: null == valuesCm ? _self.valuesCm : valuesCm // ignore: cast_nullable_to_non_nullable
as Map<String, double>,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasureUnit,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ManualEntryState].
extension ManualEntryStatePatterns on ManualEntryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManualEntryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManualEntryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManualEntryState value)  $default,){
final _that = this;
switch (_that) {
case _ManualEntryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManualEntryState value)?  $default,){
final _that = this;
switch (_that) {
case _ManualEntryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, double> valuesCm,  MeasureUnit unit,  bool saving,  bool saved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManualEntryState() when $default != null:
return $default(_that.valuesCm,_that.unit,_that.saving,_that.saved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, double> valuesCm,  MeasureUnit unit,  bool saving,  bool saved)  $default,) {final _that = this;
switch (_that) {
case _ManualEntryState():
return $default(_that.valuesCm,_that.unit,_that.saving,_that.saved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, double> valuesCm,  MeasureUnit unit,  bool saving,  bool saved)?  $default,) {final _that = this;
switch (_that) {
case _ManualEntryState() when $default != null:
return $default(_that.valuesCm,_that.unit,_that.saving,_that.saved);case _:
  return null;

}
}

}

/// @nodoc


class _ManualEntryState implements ManualEntryState {
  const _ManualEntryState({final  Map<String, double> valuesCm = const <String, double>{}, this.unit = MeasureUnit.inch, this.saving = false, this.saved = false}): _valuesCm = valuesCm;
  

/// Entered values, canonical cm (MI-13: unit is display-only,
/// inches by default — A-9).
 final  Map<String, double> _valuesCm;
/// Entered values, canonical cm (MI-13: unit is display-only,
/// inches by default — A-9).
@override@JsonKey() Map<String, double> get valuesCm {
  if (_valuesCm is EqualUnmodifiableMapView) return _valuesCm;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_valuesCm);
}

@override@JsonKey() final  MeasureUnit unit;
@override@JsonKey() final  bool saving;
/// Save landed — the screen routes to the vault (C7).
@override@JsonKey() final  bool saved;

/// Create a copy of ManualEntryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManualEntryStateCopyWith<_ManualEntryState> get copyWith => __$ManualEntryStateCopyWithImpl<_ManualEntryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManualEntryState&&const DeepCollectionEquality().equals(other._valuesCm, _valuesCm)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_valuesCm),unit,saving,saved);

@override
String toString() {
  return 'ManualEntryState(valuesCm: $valuesCm, unit: $unit, saving: $saving, saved: $saved)';
}


}

/// @nodoc
abstract mixin class _$ManualEntryStateCopyWith<$Res> implements $ManualEntryStateCopyWith<$Res> {
  factory _$ManualEntryStateCopyWith(_ManualEntryState value, $Res Function(_ManualEntryState) _then) = __$ManualEntryStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, double> valuesCm, MeasureUnit unit, bool saving, bool saved
});




}
/// @nodoc
class __$ManualEntryStateCopyWithImpl<$Res>
    implements _$ManualEntryStateCopyWith<$Res> {
  __$ManualEntryStateCopyWithImpl(this._self, this._then);

  final _ManualEntryState _self;
  final $Res Function(_ManualEntryState) _then;

/// Create a copy of ManualEntryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? valuesCm = null,Object? unit = null,Object? saving = null,Object? saved = null,}) {
  return _then(_ManualEntryState(
valuesCm: null == valuesCm ? _self._valuesCm : valuesCm // ignore: cast_nullable_to_non_nullable
as Map<String, double>,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasureUnit,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
