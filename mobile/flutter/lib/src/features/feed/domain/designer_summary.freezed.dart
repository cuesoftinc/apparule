// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'designer_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignerSummary {

 String get username; String get displayName;/// "City, State" meta line (canvas: "Amara Okafor · Lagos Island"
/// composes display name · locality).
 String get locality; String? get avatarUrl; bool get verified;/// MI-7 Follow/Following morph state for the signed-in viewer.
 bool get viewerFollows;
/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignerSummaryCopyWith<DesignerSummary> get copyWith => _$DesignerSummaryCopyWithImpl<DesignerSummary>(this as DesignerSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignerSummary&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.viewerFollows, viewerFollows) || other.viewerFollows == viewerFollows));
}


@override
int get hashCode => Object.hash(runtimeType,username,displayName,locality,avatarUrl,verified,viewerFollows);

@override
String toString() {
  return 'DesignerSummary(username: $username, displayName: $displayName, locality: $locality, avatarUrl: $avatarUrl, verified: $verified, viewerFollows: $viewerFollows)';
}


}

/// @nodoc
abstract mixin class $DesignerSummaryCopyWith<$Res>  {
  factory $DesignerSummaryCopyWith(DesignerSummary value, $Res Function(DesignerSummary) _then) = _$DesignerSummaryCopyWithImpl;
@useResult
$Res call({
 String username, String displayName, String locality, String? avatarUrl, bool verified, bool viewerFollows
});




}
/// @nodoc
class _$DesignerSummaryCopyWithImpl<$Res>
    implements $DesignerSummaryCopyWith<$Res> {
  _$DesignerSummaryCopyWithImpl(this._self, this._then);

  final DesignerSummary _self;
  final $Res Function(DesignerSummary) _then;

/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? displayName = null,Object? locality = null,Object? avatarUrl = freezed,Object? verified = null,Object? viewerFollows = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,locality: null == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,viewerFollows: null == viewerFollows ? _self.viewerFollows : viewerFollows // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignerSummary].
extension DesignerSummaryPatterns on DesignerSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignerSummary value)  $default,){
final _that = this;
switch (_that) {
case _DesignerSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String displayName,  String locality,  String? avatarUrl,  bool verified,  bool viewerFollows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
return $default(_that.username,_that.displayName,_that.locality,_that.avatarUrl,_that.verified,_that.viewerFollows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String displayName,  String locality,  String? avatarUrl,  bool verified,  bool viewerFollows)  $default,) {final _that = this;
switch (_that) {
case _DesignerSummary():
return $default(_that.username,_that.displayName,_that.locality,_that.avatarUrl,_that.verified,_that.viewerFollows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String displayName,  String locality,  String? avatarUrl,  bool verified,  bool viewerFollows)?  $default,) {final _that = this;
switch (_that) {
case _DesignerSummary() when $default != null:
return $default(_that.username,_that.displayName,_that.locality,_that.avatarUrl,_that.verified,_that.viewerFollows);case _:
  return null;

}
}

}

/// @nodoc


class _DesignerSummary implements DesignerSummary {
  const _DesignerSummary({required this.username, required this.displayName, required this.locality, this.avatarUrl, this.verified = false, this.viewerFollows = false});
  

@override final  String username;
@override final  String displayName;
/// "City, State" meta line (canvas: "Amara Okafor · Lagos Island"
/// composes display name · locality).
@override final  String locality;
@override final  String? avatarUrl;
@override@JsonKey() final  bool verified;
/// MI-7 Follow/Following morph state for the signed-in viewer.
@override@JsonKey() final  bool viewerFollows;

/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignerSummaryCopyWith<_DesignerSummary> get copyWith => __$DesignerSummaryCopyWithImpl<_DesignerSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignerSummary&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.viewerFollows, viewerFollows) || other.viewerFollows == viewerFollows));
}


@override
int get hashCode => Object.hash(runtimeType,username,displayName,locality,avatarUrl,verified,viewerFollows);

@override
String toString() {
  return 'DesignerSummary(username: $username, displayName: $displayName, locality: $locality, avatarUrl: $avatarUrl, verified: $verified, viewerFollows: $viewerFollows)';
}


}

/// @nodoc
abstract mixin class _$DesignerSummaryCopyWith<$Res> implements $DesignerSummaryCopyWith<$Res> {
  factory _$DesignerSummaryCopyWith(_DesignerSummary value, $Res Function(_DesignerSummary) _then) = __$DesignerSummaryCopyWithImpl;
@override @useResult
$Res call({
 String username, String displayName, String locality, String? avatarUrl, bool verified, bool viewerFollows
});




}
/// @nodoc
class __$DesignerSummaryCopyWithImpl<$Res>
    implements _$DesignerSummaryCopyWith<$Res> {
  __$DesignerSummaryCopyWithImpl(this._self, this._then);

  final _DesignerSummary _self;
  final $Res Function(_DesignerSummary) _then;

/// Create a copy of DesignerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? displayName = null,Object? locality = null,Object? avatarUrl = freezed,Object? verified = null,Object? viewerFollows = null,}) {
  return _then(_DesignerSummary(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,locality: null == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,viewerFollows: null == viewerFollows ? _self.viewerFollows : viewerFollows // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
