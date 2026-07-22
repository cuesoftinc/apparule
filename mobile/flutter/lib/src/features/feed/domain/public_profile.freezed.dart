// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PublicProfile {

 String get username; String get displayName; String? get avatarUrl; String? get bio; String? get locality; bool get isDesigner; bool get verified; int get postsCount; int get followersCount; int get followingCount; bool get viewerFollows; bool get viewerIsSelf;
/// Create a copy of PublicProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicProfileCopyWith<PublicProfile> get copyWith => _$PublicProfileCopyWithImpl<PublicProfile>(this as PublicProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicProfile&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.isDesigner, isDesigner) || other.isDesigner == isDesigner)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.viewerFollows, viewerFollows) || other.viewerFollows == viewerFollows)&&(identical(other.viewerIsSelf, viewerIsSelf) || other.viewerIsSelf == viewerIsSelf));
}


@override
int get hashCode => Object.hash(runtimeType,username,displayName,avatarUrl,bio,locality,isDesigner,verified,postsCount,followersCount,followingCount,viewerFollows,viewerIsSelf);

@override
String toString() {
  return 'PublicProfile(username: $username, displayName: $displayName, avatarUrl: $avatarUrl, bio: $bio, locality: $locality, isDesigner: $isDesigner, verified: $verified, postsCount: $postsCount, followersCount: $followersCount, followingCount: $followingCount, viewerFollows: $viewerFollows, viewerIsSelf: $viewerIsSelf)';
}


}

/// @nodoc
abstract mixin class $PublicProfileCopyWith<$Res>  {
  factory $PublicProfileCopyWith(PublicProfile value, $Res Function(PublicProfile) _then) = _$PublicProfileCopyWithImpl;
@useResult
$Res call({
 String username, String displayName, String? avatarUrl, String? bio, String? locality, bool isDesigner, bool verified, int postsCount, int followersCount, int followingCount, bool viewerFollows, bool viewerIsSelf
});




}
/// @nodoc
class _$PublicProfileCopyWithImpl<$Res>
    implements $PublicProfileCopyWith<$Res> {
  _$PublicProfileCopyWithImpl(this._self, this._then);

  final PublicProfile _self;
  final $Res Function(PublicProfile) _then;

/// Create a copy of PublicProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? displayName = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? locality = freezed,Object? isDesigner = null,Object? verified = null,Object? postsCount = null,Object? followersCount = null,Object? followingCount = null,Object? viewerFollows = null,Object? viewerIsSelf = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,isDesigner: null == isDesigner ? _self.isDesigner : isDesigner // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,viewerFollows: null == viewerFollows ? _self.viewerFollows : viewerFollows // ignore: cast_nullable_to_non_nullable
as bool,viewerIsSelf: null == viewerIsSelf ? _self.viewerIsSelf : viewerIsSelf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicProfile].
extension PublicProfilePatterns on PublicProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicProfile value)  $default,){
final _that = this;
switch (_that) {
case _PublicProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicProfile value)?  $default,){
final _that = this;
switch (_that) {
case _PublicProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String displayName,  String? avatarUrl,  String? bio,  String? locality,  bool isDesigner,  bool verified,  int postsCount,  int followersCount,  int followingCount,  bool viewerFollows,  bool viewerIsSelf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicProfile() when $default != null:
return $default(_that.username,_that.displayName,_that.avatarUrl,_that.bio,_that.locality,_that.isDesigner,_that.verified,_that.postsCount,_that.followersCount,_that.followingCount,_that.viewerFollows,_that.viewerIsSelf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String displayName,  String? avatarUrl,  String? bio,  String? locality,  bool isDesigner,  bool verified,  int postsCount,  int followersCount,  int followingCount,  bool viewerFollows,  bool viewerIsSelf)  $default,) {final _that = this;
switch (_that) {
case _PublicProfile():
return $default(_that.username,_that.displayName,_that.avatarUrl,_that.bio,_that.locality,_that.isDesigner,_that.verified,_that.postsCount,_that.followersCount,_that.followingCount,_that.viewerFollows,_that.viewerIsSelf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String displayName,  String? avatarUrl,  String? bio,  String? locality,  bool isDesigner,  bool verified,  int postsCount,  int followersCount,  int followingCount,  bool viewerFollows,  bool viewerIsSelf)?  $default,) {final _that = this;
switch (_that) {
case _PublicProfile() when $default != null:
return $default(_that.username,_that.displayName,_that.avatarUrl,_that.bio,_that.locality,_that.isDesigner,_that.verified,_that.postsCount,_that.followersCount,_that.followingCount,_that.viewerFollows,_that.viewerIsSelf);case _:
  return null;

}
}

}

/// @nodoc


class _PublicProfile implements PublicProfile {
  const _PublicProfile({required this.username, required this.displayName, this.avatarUrl, this.bio, this.locality, this.isDesigner = false, this.verified = false, this.postsCount = 0, this.followersCount = 0, this.followingCount = 0, this.viewerFollows = false, this.viewerIsSelf = false});
  

@override final  String username;
@override final  String displayName;
@override final  String? avatarUrl;
@override final  String? bio;
@override final  String? locality;
@override@JsonKey() final  bool isDesigner;
@override@JsonKey() final  bool verified;
@override@JsonKey() final  int postsCount;
@override@JsonKey() final  int followersCount;
@override@JsonKey() final  int followingCount;
@override@JsonKey() final  bool viewerFollows;
@override@JsonKey() final  bool viewerIsSelf;

/// Create a copy of PublicProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicProfileCopyWith<_PublicProfile> get copyWith => __$PublicProfileCopyWithImpl<_PublicProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicProfile&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.isDesigner, isDesigner) || other.isDesigner == isDesigner)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.viewerFollows, viewerFollows) || other.viewerFollows == viewerFollows)&&(identical(other.viewerIsSelf, viewerIsSelf) || other.viewerIsSelf == viewerIsSelf));
}


@override
int get hashCode => Object.hash(runtimeType,username,displayName,avatarUrl,bio,locality,isDesigner,verified,postsCount,followersCount,followingCount,viewerFollows,viewerIsSelf);

@override
String toString() {
  return 'PublicProfile(username: $username, displayName: $displayName, avatarUrl: $avatarUrl, bio: $bio, locality: $locality, isDesigner: $isDesigner, verified: $verified, postsCount: $postsCount, followersCount: $followersCount, followingCount: $followingCount, viewerFollows: $viewerFollows, viewerIsSelf: $viewerIsSelf)';
}


}

/// @nodoc
abstract mixin class _$PublicProfileCopyWith<$Res> implements $PublicProfileCopyWith<$Res> {
  factory _$PublicProfileCopyWith(_PublicProfile value, $Res Function(_PublicProfile) _then) = __$PublicProfileCopyWithImpl;
@override @useResult
$Res call({
 String username, String displayName, String? avatarUrl, String? bio, String? locality, bool isDesigner, bool verified, int postsCount, int followersCount, int followingCount, bool viewerFollows, bool viewerIsSelf
});




}
/// @nodoc
class __$PublicProfileCopyWithImpl<$Res>
    implements _$PublicProfileCopyWith<$Res> {
  __$PublicProfileCopyWithImpl(this._self, this._then);

  final _PublicProfile _self;
  final $Res Function(_PublicProfile) _then;

/// Create a copy of PublicProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? displayName = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? locality = freezed,Object? isDesigner = null,Object? verified = null,Object? postsCount = null,Object? followersCount = null,Object? followingCount = null,Object? viewerFollows = null,Object? viewerIsSelf = null,}) {
  return _then(_PublicProfile(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,isDesigner: null == isDesigner ? _self.isDesigner : isDesigner // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,viewerFollows: null == viewerFollows ? _self.viewerFollows : viewerFollows // ignore: cast_nullable_to_non_nullable
as bool,viewerIsSelf: null == viewerIsSelf ? _self.viewerIsSelf : viewerIsSelf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
