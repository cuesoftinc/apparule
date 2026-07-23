// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OwnProfileState {

 Profile get profile; int get followersCount; int get followingCount; int get postsCount; bool get designerEnabled;/// MI-11 ladder value (`fresh`/`aging`/`stale`), or null with an
/// empty vault — the ring is the C7 entry affordance either way.
 String? get vaultFreshness;/// Days since the newest vault session — the MI-11 tooltip's
/// "Measured N days ago — retake?" value (null with an empty vault).
 int? get vaultMeasuredDaysAgo;/// First grid tab: the designer side's published posts; a regular
/// user's liked grid (pages.md C9 "grid of liked/saved").
 List<Post> get gridPosts;/// Second tab: saved looks — viewer-private by construction.
 List<Post> get savedPosts;
/// Create a copy of OwnProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnProfileStateCopyWith<OwnProfileState> get copyWith => _$OwnProfileStateCopyWithImpl<OwnProfileState>(this as OwnProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnProfileState&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.designerEnabled, designerEnabled) || other.designerEnabled == designerEnabled)&&(identical(other.vaultFreshness, vaultFreshness) || other.vaultFreshness == vaultFreshness)&&(identical(other.vaultMeasuredDaysAgo, vaultMeasuredDaysAgo) || other.vaultMeasuredDaysAgo == vaultMeasuredDaysAgo)&&const DeepCollectionEquality().equals(other.gridPosts, gridPosts)&&const DeepCollectionEquality().equals(other.savedPosts, savedPosts));
}


@override
int get hashCode => Object.hash(runtimeType,profile,followersCount,followingCount,postsCount,designerEnabled,vaultFreshness,vaultMeasuredDaysAgo,const DeepCollectionEquality().hash(gridPosts),const DeepCollectionEquality().hash(savedPosts));

@override
String toString() {
  return 'OwnProfileState(profile: $profile, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, designerEnabled: $designerEnabled, vaultFreshness: $vaultFreshness, vaultMeasuredDaysAgo: $vaultMeasuredDaysAgo, gridPosts: $gridPosts, savedPosts: $savedPosts)';
}


}

/// @nodoc
abstract mixin class $OwnProfileStateCopyWith<$Res>  {
  factory $OwnProfileStateCopyWith(OwnProfileState value, $Res Function(OwnProfileState) _then) = _$OwnProfileStateCopyWithImpl;
@useResult
$Res call({
 Profile profile, int followersCount, int followingCount, int postsCount, bool designerEnabled, String? vaultFreshness, int? vaultMeasuredDaysAgo, List<Post> gridPosts, List<Post> savedPosts
});


$ProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$OwnProfileStateCopyWithImpl<$Res>
    implements $OwnProfileStateCopyWith<$Res> {
  _$OwnProfileStateCopyWithImpl(this._self, this._then);

  final OwnProfileState _self;
  final $Res Function(OwnProfileState) _then;

/// Create a copy of OwnProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profile = null,Object? followersCount = null,Object? followingCount = null,Object? postsCount = null,Object? designerEnabled = null,Object? vaultFreshness = freezed,Object? vaultMeasuredDaysAgo = freezed,Object? gridPosts = null,Object? savedPosts = null,}) {
  return _then(_self.copyWith(
profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Profile,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,designerEnabled: null == designerEnabled ? _self.designerEnabled : designerEnabled // ignore: cast_nullable_to_non_nullable
as bool,vaultFreshness: freezed == vaultFreshness ? _self.vaultFreshness : vaultFreshness // ignore: cast_nullable_to_non_nullable
as String?,vaultMeasuredDaysAgo: freezed == vaultMeasuredDaysAgo ? _self.vaultMeasuredDaysAgo : vaultMeasuredDaysAgo // ignore: cast_nullable_to_non_nullable
as int?,gridPosts: null == gridPosts ? _self.gridPosts : gridPosts // ignore: cast_nullable_to_non_nullable
as List<Post>,savedPosts: null == savedPosts ? _self.savedPosts : savedPosts // ignore: cast_nullable_to_non_nullable
as List<Post>,
  ));
}
/// Create a copy of OwnProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res> get profile {
  
  return $ProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [OwnProfileState].
extension OwnProfileStatePatterns on OwnProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnProfileState value)  $default,){
final _that = this;
switch (_that) {
case _OwnProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _OwnProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Profile profile,  int followersCount,  int followingCount,  int postsCount,  bool designerEnabled,  String? vaultFreshness,  int? vaultMeasuredDaysAgo,  List<Post> gridPosts,  List<Post> savedPosts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnProfileState() when $default != null:
return $default(_that.profile,_that.followersCount,_that.followingCount,_that.postsCount,_that.designerEnabled,_that.vaultFreshness,_that.vaultMeasuredDaysAgo,_that.gridPosts,_that.savedPosts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Profile profile,  int followersCount,  int followingCount,  int postsCount,  bool designerEnabled,  String? vaultFreshness,  int? vaultMeasuredDaysAgo,  List<Post> gridPosts,  List<Post> savedPosts)  $default,) {final _that = this;
switch (_that) {
case _OwnProfileState():
return $default(_that.profile,_that.followersCount,_that.followingCount,_that.postsCount,_that.designerEnabled,_that.vaultFreshness,_that.vaultMeasuredDaysAgo,_that.gridPosts,_that.savedPosts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Profile profile,  int followersCount,  int followingCount,  int postsCount,  bool designerEnabled,  String? vaultFreshness,  int? vaultMeasuredDaysAgo,  List<Post> gridPosts,  List<Post> savedPosts)?  $default,) {final _that = this;
switch (_that) {
case _OwnProfileState() when $default != null:
return $default(_that.profile,_that.followersCount,_that.followingCount,_that.postsCount,_that.designerEnabled,_that.vaultFreshness,_that.vaultMeasuredDaysAgo,_that.gridPosts,_that.savedPosts);case _:
  return null;

}
}

}

/// @nodoc


class _OwnProfileState implements OwnProfileState {
  const _OwnProfileState({required this.profile, this.followersCount = 0, this.followingCount = 0, this.postsCount = 0, this.designerEnabled = false, this.vaultFreshness, this.vaultMeasuredDaysAgo, final  List<Post> gridPosts = const <Post>[], final  List<Post> savedPosts = const <Post>[]}): _gridPosts = gridPosts,_savedPosts = savedPosts;
  

@override final  Profile profile;
@override@JsonKey() final  int followersCount;
@override@JsonKey() final  int followingCount;
@override@JsonKey() final  int postsCount;
@override@JsonKey() final  bool designerEnabled;
/// MI-11 ladder value (`fresh`/`aging`/`stale`), or null with an
/// empty vault — the ring is the C7 entry affordance either way.
@override final  String? vaultFreshness;
/// Days since the newest vault session — the MI-11 tooltip's
/// "Measured N days ago — retake?" value (null with an empty vault).
@override final  int? vaultMeasuredDaysAgo;
/// First grid tab: the designer side's published posts; a regular
/// user's liked grid (pages.md C9 "grid of liked/saved").
 final  List<Post> _gridPosts;
/// First grid tab: the designer side's published posts; a regular
/// user's liked grid (pages.md C9 "grid of liked/saved").
@override@JsonKey() List<Post> get gridPosts {
  if (_gridPosts is EqualUnmodifiableListView) return _gridPosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gridPosts);
}

/// Second tab: saved looks — viewer-private by construction.
 final  List<Post> _savedPosts;
/// Second tab: saved looks — viewer-private by construction.
@override@JsonKey() List<Post> get savedPosts {
  if (_savedPosts is EqualUnmodifiableListView) return _savedPosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedPosts);
}


/// Create a copy of OwnProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnProfileStateCopyWith<_OwnProfileState> get copyWith => __$OwnProfileStateCopyWithImpl<_OwnProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnProfileState&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.designerEnabled, designerEnabled) || other.designerEnabled == designerEnabled)&&(identical(other.vaultFreshness, vaultFreshness) || other.vaultFreshness == vaultFreshness)&&(identical(other.vaultMeasuredDaysAgo, vaultMeasuredDaysAgo) || other.vaultMeasuredDaysAgo == vaultMeasuredDaysAgo)&&const DeepCollectionEquality().equals(other._gridPosts, _gridPosts)&&const DeepCollectionEquality().equals(other._savedPosts, _savedPosts));
}


@override
int get hashCode => Object.hash(runtimeType,profile,followersCount,followingCount,postsCount,designerEnabled,vaultFreshness,vaultMeasuredDaysAgo,const DeepCollectionEquality().hash(_gridPosts),const DeepCollectionEquality().hash(_savedPosts));

@override
String toString() {
  return 'OwnProfileState(profile: $profile, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, designerEnabled: $designerEnabled, vaultFreshness: $vaultFreshness, vaultMeasuredDaysAgo: $vaultMeasuredDaysAgo, gridPosts: $gridPosts, savedPosts: $savedPosts)';
}


}

/// @nodoc
abstract mixin class _$OwnProfileStateCopyWith<$Res> implements $OwnProfileStateCopyWith<$Res> {
  factory _$OwnProfileStateCopyWith(_OwnProfileState value, $Res Function(_OwnProfileState) _then) = __$OwnProfileStateCopyWithImpl;
@override @useResult
$Res call({
 Profile profile, int followersCount, int followingCount, int postsCount, bool designerEnabled, String? vaultFreshness, int? vaultMeasuredDaysAgo, List<Post> gridPosts, List<Post> savedPosts
});


@override $ProfileCopyWith<$Res> get profile;

}
/// @nodoc
class __$OwnProfileStateCopyWithImpl<$Res>
    implements _$OwnProfileStateCopyWith<$Res> {
  __$OwnProfileStateCopyWithImpl(this._self, this._then);

  final _OwnProfileState _self;
  final $Res Function(_OwnProfileState) _then;

/// Create a copy of OwnProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profile = null,Object? followersCount = null,Object? followingCount = null,Object? postsCount = null,Object? designerEnabled = null,Object? vaultFreshness = freezed,Object? vaultMeasuredDaysAgo = freezed,Object? gridPosts = null,Object? savedPosts = null,}) {
  return _then(_OwnProfileState(
profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Profile,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,designerEnabled: null == designerEnabled ? _self.designerEnabled : designerEnabled // ignore: cast_nullable_to_non_nullable
as bool,vaultFreshness: freezed == vaultFreshness ? _self.vaultFreshness : vaultFreshness // ignore: cast_nullable_to_non_nullable
as String?,vaultMeasuredDaysAgo: freezed == vaultMeasuredDaysAgo ? _self.vaultMeasuredDaysAgo : vaultMeasuredDaysAgo // ignore: cast_nullable_to_non_nullable
as int?,gridPosts: null == gridPosts ? _self._gridPosts : gridPosts // ignore: cast_nullable_to_non_nullable
as List<Post>,savedPosts: null == savedPosts ? _self._savedPosts : savedPosts // ignore: cast_nullable_to_non_nullable
as List<Post>,
  ));
}

/// Create a copy of OwnProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res> get profile {
  
  return $ProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
