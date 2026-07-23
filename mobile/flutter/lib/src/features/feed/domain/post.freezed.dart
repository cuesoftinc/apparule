// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostDesigner {

 String get id; String get username; String get displayName;/// Seed-relative media URL (`/demo/...`) — resolved to an image
/// provider by `seedMediaImage` (core/utils); `null` renders initials.
 String? get avatarUrl; bool get verified;
/// Create a copy of PostDesigner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDesignerCopyWith<PostDesigner> get copyWith => _$PostDesignerCopyWithImpl<PostDesigner>(this as PostDesigner, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDesigner&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.verified, verified) || other.verified == verified));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl,verified);

@override
String toString() {
  return 'PostDesigner(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, verified: $verified)';
}


}

/// @nodoc
abstract mixin class $PostDesignerCopyWith<$Res>  {
  factory $PostDesignerCopyWith(PostDesigner value, $Res Function(PostDesigner) _then) = _$PostDesignerCopyWithImpl;
@useResult
$Res call({
 String id, String username, String displayName, String? avatarUrl, bool verified
});




}
/// @nodoc
class _$PostDesignerCopyWithImpl<$Res>
    implements $PostDesignerCopyWith<$Res> {
  _$PostDesignerCopyWithImpl(this._self, this._then);

  final PostDesigner _self;
  final $Res Function(PostDesigner) _then;

/// Create a copy of PostDesigner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? avatarUrl = freezed,Object? verified = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PostDesigner].
extension PostDesignerPatterns on PostDesigner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostDesigner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostDesigner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostDesigner value)  $default,){
final _that = this;
switch (_that) {
case _PostDesigner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostDesigner value)?  $default,){
final _that = this;
switch (_that) {
case _PostDesigner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String displayName,  String? avatarUrl,  bool verified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostDesigner() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.verified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String displayName,  String? avatarUrl,  bool verified)  $default,) {final _that = this;
switch (_that) {
case _PostDesigner():
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.verified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String displayName,  String? avatarUrl,  bool verified)?  $default,) {final _that = this;
switch (_that) {
case _PostDesigner() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.avatarUrl,_that.verified);case _:
  return null;

}
}

}

/// @nodoc


class _PostDesigner implements PostDesigner {
  const _PostDesigner({required this.id, required this.username, required this.displayName, this.avatarUrl, this.verified = false});
  

@override final  String id;
@override final  String username;
@override final  String displayName;
/// Seed-relative media URL (`/demo/...`) — resolved to an image
/// provider by `seedMediaImage` (core/utils); `null` renders initials.
@override final  String? avatarUrl;
@override@JsonKey() final  bool verified;

/// Create a copy of PostDesigner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostDesignerCopyWith<_PostDesigner> get copyWith => __$PostDesignerCopyWithImpl<_PostDesigner>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostDesigner&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.verified, verified) || other.verified == verified));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,avatarUrl,verified);

@override
String toString() {
  return 'PostDesigner(id: $id, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, verified: $verified)';
}


}

/// @nodoc
abstract mixin class _$PostDesignerCopyWith<$Res> implements $PostDesignerCopyWith<$Res> {
  factory _$PostDesignerCopyWith(_PostDesigner value, $Res Function(_PostDesigner) _then) = __$PostDesignerCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String displayName, String? avatarUrl, bool verified
});




}
/// @nodoc
class __$PostDesignerCopyWithImpl<$Res>
    implements _$PostDesignerCopyWith<$Res> {
  __$PostDesignerCopyWithImpl(this._self, this._then);

  final _PostDesigner _self;
  final $Res Function(_PostDesigner) _then;

/// Create a copy of PostDesigner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? avatarUrl = freezed,Object? verified = null,}) {
  return _then(_PostDesigner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PostMedia {

 String get url; String get altText;
/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostMediaCopyWith<PostMedia> get copyWith => _$PostMediaCopyWithImpl<PostMedia>(this as PostMedia, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostMedia&&(identical(other.url, url) || other.url == url)&&(identical(other.altText, altText) || other.altText == altText));
}


@override
int get hashCode => Object.hash(runtimeType,url,altText);

@override
String toString() {
  return 'PostMedia(url: $url, altText: $altText)';
}


}

/// @nodoc
abstract mixin class $PostMediaCopyWith<$Res>  {
  factory $PostMediaCopyWith(PostMedia value, $Res Function(PostMedia) _then) = _$PostMediaCopyWithImpl;
@useResult
$Res call({
 String url, String altText
});




}
/// @nodoc
class _$PostMediaCopyWithImpl<$Res>
    implements $PostMediaCopyWith<$Res> {
  _$PostMediaCopyWithImpl(this._self, this._then);

  final PostMedia _self;
  final $Res Function(PostMedia) _then;

/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? altText = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,altText: null == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PostMedia].
extension PostMediaPatterns on PostMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostMedia value)  $default,){
final _that = this;
switch (_that) {
case _PostMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostMedia value)?  $default,){
final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String altText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
return $default(_that.url,_that.altText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String altText)  $default,) {final _that = this;
switch (_that) {
case _PostMedia():
return $default(_that.url,_that.altText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String altText)?  $default,) {final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
return $default(_that.url,_that.altText);case _:
  return null;

}
}

}

/// @nodoc


class _PostMedia implements PostMedia {
  const _PostMedia({required this.url, required this.altText});
  

@override final  String url;
@override final  String altText;

/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostMediaCopyWith<_PostMedia> get copyWith => __$PostMediaCopyWithImpl<_PostMedia>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostMedia&&(identical(other.url, url) || other.url == url)&&(identical(other.altText, altText) || other.altText == altText));
}


@override
int get hashCode => Object.hash(runtimeType,url,altText);

@override
String toString() {
  return 'PostMedia(url: $url, altText: $altText)';
}


}

/// @nodoc
abstract mixin class _$PostMediaCopyWith<$Res> implements $PostMediaCopyWith<$Res> {
  factory _$PostMediaCopyWith(_PostMedia value, $Res Function(_PostMedia) _then) = __$PostMediaCopyWithImpl;
@override @useResult
$Res call({
 String url, String altText
});




}
/// @nodoc
class __$PostMediaCopyWithImpl<$Res>
    implements _$PostMediaCopyWith<$Res> {
  __$PostMediaCopyWithImpl(this._self, this._then);

  final _PostMedia _self;
  final $Res Function(_PostMedia) _then;

/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? altText = null,}) {
  return _then(_PostMedia(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,altText: null == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Post {

 String get id; PostDesigner get designer; String get caption; List<String> get styleTags; List<PostMedia> get media; int get likeCount; int get commentCount; DateTime get createdAt;/// Base price in kobo; `null` = "quote on request".
 int? get basePriceCents; String get currency; int get turnaroundDays;/// Viewer-scoped engagement (web `viewPost` parity).
 bool get liked; bool get saved;/// The measurement-snapshot ref a C15 composer post carries when the
/// attach toggle is ON (M-11: posts carry the fit data this look was
/// tailored for) — the vault session's id at publish time. Seed
/// posts and snapshot-less publishes carry `null`.
 String? get snapshotSessionId;
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCopyWith<Post> get copyWith => _$PostCopyWithImpl<Post>(this as Post, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Post&&(identical(other.id, id) || other.id == id)&&(identical(other.designer, designer) || other.designer == designer)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.styleTags, styleTags)&&const DeepCollectionEquality().equals(other.media, media)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.basePriceCents, basePriceCents) || other.basePriceCents == basePriceCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.turnaroundDays, turnaroundDays) || other.turnaroundDays == turnaroundDays)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.snapshotSessionId, snapshotSessionId) || other.snapshotSessionId == snapshotSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,id,designer,caption,const DeepCollectionEquality().hash(styleTags),const DeepCollectionEquality().hash(media),likeCount,commentCount,createdAt,basePriceCents,currency,turnaroundDays,liked,saved,snapshotSessionId);

@override
String toString() {
  return 'Post(id: $id, designer: $designer, caption: $caption, styleTags: $styleTags, media: $media, likeCount: $likeCount, commentCount: $commentCount, createdAt: $createdAt, basePriceCents: $basePriceCents, currency: $currency, turnaroundDays: $turnaroundDays, liked: $liked, saved: $saved, snapshotSessionId: $snapshotSessionId)';
}


}

/// @nodoc
abstract mixin class $PostCopyWith<$Res>  {
  factory $PostCopyWith(Post value, $Res Function(Post) _then) = _$PostCopyWithImpl;
@useResult
$Res call({
 String id, PostDesigner designer, String caption, List<String> styleTags, List<PostMedia> media, int likeCount, int commentCount, DateTime createdAt, int? basePriceCents, String currency, int turnaroundDays, bool liked, bool saved, String? snapshotSessionId
});


$PostDesignerCopyWith<$Res> get designer;

}
/// @nodoc
class _$PostCopyWithImpl<$Res>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._self, this._then);

  final Post _self;
  final $Res Function(Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? designer = null,Object? caption = null,Object? styleTags = null,Object? media = null,Object? likeCount = null,Object? commentCount = null,Object? createdAt = null,Object? basePriceCents = freezed,Object? currency = null,Object? turnaroundDays = null,Object? liked = null,Object? saved = null,Object? snapshotSessionId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,designer: null == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as PostDesigner,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,styleTags: null == styleTags ? _self.styleTags : styleTags // ignore: cast_nullable_to_non_nullable
as List<String>,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<PostMedia>,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,basePriceCents: freezed == basePriceCents ? _self.basePriceCents : basePriceCents // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,turnaroundDays: null == turnaroundDays ? _self.turnaroundDays : turnaroundDays // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,snapshotSessionId: freezed == snapshotSessionId ? _self.snapshotSessionId : snapshotSessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostDesignerCopyWith<$Res> get designer {
  
  return $PostDesignerCopyWith<$Res>(_self.designer, (value) {
    return _then(_self.copyWith(designer: value));
  });
}
}


/// Adds pattern-matching-related methods to [Post].
extension PostPatterns on Post {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Post value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Post value)  $default,){
final _that = this;
switch (_that) {
case _Post():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Post value)?  $default,){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PostDesigner designer,  String caption,  List<String> styleTags,  List<PostMedia> media,  int likeCount,  int commentCount,  DateTime createdAt,  int? basePriceCents,  String currency,  int turnaroundDays,  bool liked,  bool saved,  String? snapshotSessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.designer,_that.caption,_that.styleTags,_that.media,_that.likeCount,_that.commentCount,_that.createdAt,_that.basePriceCents,_that.currency,_that.turnaroundDays,_that.liked,_that.saved,_that.snapshotSessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PostDesigner designer,  String caption,  List<String> styleTags,  List<PostMedia> media,  int likeCount,  int commentCount,  DateTime createdAt,  int? basePriceCents,  String currency,  int turnaroundDays,  bool liked,  bool saved,  String? snapshotSessionId)  $default,) {final _that = this;
switch (_that) {
case _Post():
return $default(_that.id,_that.designer,_that.caption,_that.styleTags,_that.media,_that.likeCount,_that.commentCount,_that.createdAt,_that.basePriceCents,_that.currency,_that.turnaroundDays,_that.liked,_that.saved,_that.snapshotSessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PostDesigner designer,  String caption,  List<String> styleTags,  List<PostMedia> media,  int likeCount,  int commentCount,  DateTime createdAt,  int? basePriceCents,  String currency,  int turnaroundDays,  bool liked,  bool saved,  String? snapshotSessionId)?  $default,) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.designer,_that.caption,_that.styleTags,_that.media,_that.likeCount,_that.commentCount,_that.createdAt,_that.basePriceCents,_that.currency,_that.turnaroundDays,_that.liked,_that.saved,_that.snapshotSessionId);case _:
  return null;

}
}

}

/// @nodoc


class _Post implements Post {
  const _Post({required this.id, required this.designer, required this.caption, required final  List<String> styleTags, required final  List<PostMedia> media, required this.likeCount, required this.commentCount, required this.createdAt, this.basePriceCents, this.currency = 'NGN', this.turnaroundDays = 0, this.liked = false, this.saved = false, this.snapshotSessionId}): _styleTags = styleTags,_media = media;
  

@override final  String id;
@override final  PostDesigner designer;
@override final  String caption;
 final  List<String> _styleTags;
@override List<String> get styleTags {
  if (_styleTags is EqualUnmodifiableListView) return _styleTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_styleTags);
}

 final  List<PostMedia> _media;
@override List<PostMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override final  int likeCount;
@override final  int commentCount;
@override final  DateTime createdAt;
/// Base price in kobo; `null` = "quote on request".
@override final  int? basePriceCents;
@override@JsonKey() final  String currency;
@override@JsonKey() final  int turnaroundDays;
/// Viewer-scoped engagement (web `viewPost` parity).
@override@JsonKey() final  bool liked;
@override@JsonKey() final  bool saved;
/// The measurement-snapshot ref a C15 composer post carries when the
/// attach toggle is ON (M-11: posts carry the fit data this look was
/// tailored for) — the vault session's id at publish time. Seed
/// posts and snapshot-less publishes carry `null`.
@override final  String? snapshotSessionId;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCopyWith<_Post> get copyWith => __$PostCopyWithImpl<_Post>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Post&&(identical(other.id, id) || other.id == id)&&(identical(other.designer, designer) || other.designer == designer)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._styleTags, _styleTags)&&const DeepCollectionEquality().equals(other._media, _media)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.basePriceCents, basePriceCents) || other.basePriceCents == basePriceCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.turnaroundDays, turnaroundDays) || other.turnaroundDays == turnaroundDays)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.snapshotSessionId, snapshotSessionId) || other.snapshotSessionId == snapshotSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,id,designer,caption,const DeepCollectionEquality().hash(_styleTags),const DeepCollectionEquality().hash(_media),likeCount,commentCount,createdAt,basePriceCents,currency,turnaroundDays,liked,saved,snapshotSessionId);

@override
String toString() {
  return 'Post(id: $id, designer: $designer, caption: $caption, styleTags: $styleTags, media: $media, likeCount: $likeCount, commentCount: $commentCount, createdAt: $createdAt, basePriceCents: $basePriceCents, currency: $currency, turnaroundDays: $turnaroundDays, liked: $liked, saved: $saved, snapshotSessionId: $snapshotSessionId)';
}


}

/// @nodoc
abstract mixin class _$PostCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$PostCopyWith(_Post value, $Res Function(_Post) _then) = __$PostCopyWithImpl;
@override @useResult
$Res call({
 String id, PostDesigner designer, String caption, List<String> styleTags, List<PostMedia> media, int likeCount, int commentCount, DateTime createdAt, int? basePriceCents, String currency, int turnaroundDays, bool liked, bool saved, String? snapshotSessionId
});


@override $PostDesignerCopyWith<$Res> get designer;

}
/// @nodoc
class __$PostCopyWithImpl<$Res>
    implements _$PostCopyWith<$Res> {
  __$PostCopyWithImpl(this._self, this._then);

  final _Post _self;
  final $Res Function(_Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? designer = null,Object? caption = null,Object? styleTags = null,Object? media = null,Object? likeCount = null,Object? commentCount = null,Object? createdAt = null,Object? basePriceCents = freezed,Object? currency = null,Object? turnaroundDays = null,Object? liked = null,Object? saved = null,Object? snapshotSessionId = freezed,}) {
  return _then(_Post(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,designer: null == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as PostDesigner,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,styleTags: null == styleTags ? _self._styleTags : styleTags // ignore: cast_nullable_to_non_nullable
as List<String>,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<PostMedia>,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,basePriceCents: freezed == basePriceCents ? _self.basePriceCents : basePriceCents // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,turnaroundDays: null == turnaroundDays ? _self.turnaroundDays : turnaroundDays // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,snapshotSessionId: freezed == snapshotSessionId ? _self.snapshotSessionId : snapshotSessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostDesignerCopyWith<$Res> get designer {
  
  return $PostDesignerCopyWith<$Res>(_self.designer, (value) {
    return _then(_self.copyWith(designer: value));
  });
}
}

// dart format on
