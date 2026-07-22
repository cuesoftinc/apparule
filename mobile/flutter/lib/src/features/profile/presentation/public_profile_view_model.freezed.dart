// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_profile_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PublicProfileState {

 PublicProfile get profile; List<Post> get posts;
/// Create a copy of PublicProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicProfileStateCopyWith<PublicProfileState> get copyWith => _$PublicProfileStateCopyWithImpl<PublicProfileState>(this as PublicProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicProfileState&&(identical(other.profile, profile) || other.profile == profile)&&const DeepCollectionEquality().equals(other.posts, posts));
}


@override
int get hashCode => Object.hash(runtimeType,profile,const DeepCollectionEquality().hash(posts));

@override
String toString() {
  return 'PublicProfileState(profile: $profile, posts: $posts)';
}


}

/// @nodoc
abstract mixin class $PublicProfileStateCopyWith<$Res>  {
  factory $PublicProfileStateCopyWith(PublicProfileState value, $Res Function(PublicProfileState) _then) = _$PublicProfileStateCopyWithImpl;
@useResult
$Res call({
 PublicProfile profile, List<Post> posts
});


$PublicProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$PublicProfileStateCopyWithImpl<$Res>
    implements $PublicProfileStateCopyWith<$Res> {
  _$PublicProfileStateCopyWithImpl(this._self, this._then);

  final PublicProfileState _self;
  final $Res Function(PublicProfileState) _then;

/// Create a copy of PublicProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profile = null,Object? posts = null,}) {
  return _then(_self.copyWith(
profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as PublicProfile,posts: null == posts ? _self.posts : posts // ignore: cast_nullable_to_non_nullable
as List<Post>,
  ));
}
/// Create a copy of PublicProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PublicProfileCopyWith<$Res> get profile {
  
  return $PublicProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [PublicProfileState].
extension PublicProfileStatePatterns on PublicProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicProfileState value)  $default,){
final _that = this;
switch (_that) {
case _PublicProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _PublicProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PublicProfile profile,  List<Post> posts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicProfileState() when $default != null:
return $default(_that.profile,_that.posts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PublicProfile profile,  List<Post> posts)  $default,) {final _that = this;
switch (_that) {
case _PublicProfileState():
return $default(_that.profile,_that.posts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PublicProfile profile,  List<Post> posts)?  $default,) {final _that = this;
switch (_that) {
case _PublicProfileState() when $default != null:
return $default(_that.profile,_that.posts);case _:
  return null;

}
}

}

/// @nodoc


class _PublicProfileState implements PublicProfileState {
  const _PublicProfileState({required this.profile, final  List<Post> posts = const <Post>[]}): _posts = posts;
  

@override final  PublicProfile profile;
 final  List<Post> _posts;
@override@JsonKey() List<Post> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}


/// Create a copy of PublicProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicProfileStateCopyWith<_PublicProfileState> get copyWith => __$PublicProfileStateCopyWithImpl<_PublicProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicProfileState&&(identical(other.profile, profile) || other.profile == profile)&&const DeepCollectionEquality().equals(other._posts, _posts));
}


@override
int get hashCode => Object.hash(runtimeType,profile,const DeepCollectionEquality().hash(_posts));

@override
String toString() {
  return 'PublicProfileState(profile: $profile, posts: $posts)';
}


}

/// @nodoc
abstract mixin class _$PublicProfileStateCopyWith<$Res> implements $PublicProfileStateCopyWith<$Res> {
  factory _$PublicProfileStateCopyWith(_PublicProfileState value, $Res Function(_PublicProfileState) _then) = __$PublicProfileStateCopyWithImpl;
@override @useResult
$Res call({
 PublicProfile profile, List<Post> posts
});


@override $PublicProfileCopyWith<$Res> get profile;

}
/// @nodoc
class __$PublicProfileStateCopyWithImpl<$Res>
    implements _$PublicProfileStateCopyWith<$Res> {
  __$PublicProfileStateCopyWithImpl(this._self, this._then);

  final _PublicProfileState _self;
  final $Res Function(_PublicProfileState) _then;

/// Create a copy of PublicProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profile = null,Object? posts = null,}) {
  return _then(_PublicProfileState(
profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as PublicProfile,posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<Post>,
  ));
}

/// Create a copy of PublicProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PublicProfileCopyWith<$Res> get profile {
  
  return $PublicProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
