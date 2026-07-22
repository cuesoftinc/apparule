// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_rail_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryRailEntry {

 String get username; String get newestPostId;/// Gradient ring: fresh (<48h) content the viewer hasn't seen yet.
 bool get unseen; String? get avatarUrl;
/// Create a copy of StoryRailEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryRailEntryCopyWith<StoryRailEntry> get copyWith => _$StoryRailEntryCopyWithImpl<StoryRailEntry>(this as StoryRailEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryRailEntry&&(identical(other.username, username) || other.username == username)&&(identical(other.newestPostId, newestPostId) || other.newestPostId == newestPostId)&&(identical(other.unseen, unseen) || other.unseen == unseen)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,username,newestPostId,unseen,avatarUrl);

@override
String toString() {
  return 'StoryRailEntry(username: $username, newestPostId: $newestPostId, unseen: $unseen, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $StoryRailEntryCopyWith<$Res>  {
  factory $StoryRailEntryCopyWith(StoryRailEntry value, $Res Function(StoryRailEntry) _then) = _$StoryRailEntryCopyWithImpl;
@useResult
$Res call({
 String username, String newestPostId, bool unseen, String? avatarUrl
});




}
/// @nodoc
class _$StoryRailEntryCopyWithImpl<$Res>
    implements $StoryRailEntryCopyWith<$Res> {
  _$StoryRailEntryCopyWithImpl(this._self, this._then);

  final StoryRailEntry _self;
  final $Res Function(StoryRailEntry) _then;

/// Create a copy of StoryRailEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? newestPostId = null,Object? unseen = null,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,newestPostId: null == newestPostId ? _self.newestPostId : newestPostId // ignore: cast_nullable_to_non_nullable
as String,unseen: null == unseen ? _self.unseen : unseen // ignore: cast_nullable_to_non_nullable
as bool,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryRailEntry].
extension StoryRailEntryPatterns on StoryRailEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryRailEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryRailEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryRailEntry value)  $default,){
final _that = this;
switch (_that) {
case _StoryRailEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryRailEntry value)?  $default,){
final _that = this;
switch (_that) {
case _StoryRailEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String newestPostId,  bool unseen,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryRailEntry() when $default != null:
return $default(_that.username,_that.newestPostId,_that.unseen,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String newestPostId,  bool unseen,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _StoryRailEntry():
return $default(_that.username,_that.newestPostId,_that.unseen,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String newestPostId,  bool unseen,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _StoryRailEntry() when $default != null:
return $default(_that.username,_that.newestPostId,_that.unseen,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _StoryRailEntry implements StoryRailEntry {
  const _StoryRailEntry({required this.username, required this.newestPostId, required this.unseen, this.avatarUrl});
  

@override final  String username;
@override final  String newestPostId;
/// Gradient ring: fresh (<48h) content the viewer hasn't seen yet.
@override final  bool unseen;
@override final  String? avatarUrl;

/// Create a copy of StoryRailEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryRailEntryCopyWith<_StoryRailEntry> get copyWith => __$StoryRailEntryCopyWithImpl<_StoryRailEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryRailEntry&&(identical(other.username, username) || other.username == username)&&(identical(other.newestPostId, newestPostId) || other.newestPostId == newestPostId)&&(identical(other.unseen, unseen) || other.unseen == unseen)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,username,newestPostId,unseen,avatarUrl);

@override
String toString() {
  return 'StoryRailEntry(username: $username, newestPostId: $newestPostId, unseen: $unseen, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$StoryRailEntryCopyWith<$Res> implements $StoryRailEntryCopyWith<$Res> {
  factory _$StoryRailEntryCopyWith(_StoryRailEntry value, $Res Function(_StoryRailEntry) _then) = __$StoryRailEntryCopyWithImpl;
@override @useResult
$Res call({
 String username, String newestPostId, bool unseen, String? avatarUrl
});




}
/// @nodoc
class __$StoryRailEntryCopyWithImpl<$Res>
    implements _$StoryRailEntryCopyWith<$Res> {
  __$StoryRailEntryCopyWithImpl(this._self, this._then);

  final _StoryRailEntry _self;
  final $Res Function(_StoryRailEntry) _then;

/// Create a copy of StoryRailEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? newestPostId = null,Object? unseen = null,Object? avatarUrl = freezed,}) {
  return _then(_StoryRailEntry(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,newestPostId: null == newestPostId ? _self.newestPostId : newestPostId // ignore: cast_nullable_to_non_nullable
as String,unseen: null == unseen ? _self.unseen : unseen // ignore: cast_nullable_to_non_nullable
as bool,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
