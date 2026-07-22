// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'designer_onboarding_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingPrefill {

 String get username; String get displayName;
/// Create a copy of OnboardingPrefill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingPrefillCopyWith<OnboardingPrefill> get copyWith => _$OnboardingPrefillCopyWithImpl<OnboardingPrefill>(this as OnboardingPrefill, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingPrefill&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,username,displayName);

@override
String toString() {
  return 'OnboardingPrefill(username: $username, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $OnboardingPrefillCopyWith<$Res>  {
  factory $OnboardingPrefillCopyWith(OnboardingPrefill value, $Res Function(OnboardingPrefill) _then) = _$OnboardingPrefillCopyWithImpl;
@useResult
$Res call({
 String username, String displayName
});




}
/// @nodoc
class _$OnboardingPrefillCopyWithImpl<$Res>
    implements $OnboardingPrefillCopyWith<$Res> {
  _$OnboardingPrefillCopyWithImpl(this._self, this._then);

  final OnboardingPrefill _self;
  final $Res Function(OnboardingPrefill) _then;

/// Create a copy of OnboardingPrefill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingPrefill].
extension OnboardingPrefillPatterns on OnboardingPrefill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingPrefill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingPrefill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingPrefill value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingPrefill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingPrefill value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingPrefill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingPrefill() when $default != null:
return $default(_that.username,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _OnboardingPrefill():
return $default(_that.username,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingPrefill() when $default != null:
return $default(_that.username,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingPrefill implements OnboardingPrefill {
  const _OnboardingPrefill({required this.username, required this.displayName});
  

@override final  String username;
@override final  String displayName;

/// Create a copy of OnboardingPrefill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingPrefillCopyWith<_OnboardingPrefill> get copyWith => __$OnboardingPrefillCopyWithImpl<_OnboardingPrefill>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingPrefill&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,username,displayName);

@override
String toString() {
  return 'OnboardingPrefill(username: $username, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$OnboardingPrefillCopyWith<$Res> implements $OnboardingPrefillCopyWith<$Res> {
  factory _$OnboardingPrefillCopyWith(_OnboardingPrefill value, $Res Function(_OnboardingPrefill) _then) = __$OnboardingPrefillCopyWithImpl;
@override @useResult
$Res call({
 String username, String displayName
});




}
/// @nodoc
class __$OnboardingPrefillCopyWithImpl<$Res>
    implements _$OnboardingPrefillCopyWith<$Res> {
  __$OnboardingPrefillCopyWithImpl(this._self, this._then);

  final _OnboardingPrefill _self;
  final $Res Function(_OnboardingPrefill) _then;

/// Create a copy of OnboardingPrefill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? displayName = null,}) {
  return _then(_OnboardingPrefill(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
