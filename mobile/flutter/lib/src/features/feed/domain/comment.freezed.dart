// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentAuthor {

 String get id; String get username; String? get avatarUrl;
/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentAuthorCopyWith<CommentAuthor> get copyWith => _$CommentAuthorCopyWithImpl<CommentAuthor>(this as CommentAuthor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,avatarUrl);

@override
String toString() {
  return 'CommentAuthor(id: $id, username: $username, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $CommentAuthorCopyWith<$Res>  {
  factory $CommentAuthorCopyWith(CommentAuthor value, $Res Function(CommentAuthor) _then) = _$CommentAuthorCopyWithImpl;
@useResult
$Res call({
 String id, String username, String? avatarUrl
});




}
/// @nodoc
class _$CommentAuthorCopyWithImpl<$Res>
    implements $CommentAuthorCopyWith<$Res> {
  _$CommentAuthorCopyWithImpl(this._self, this._then);

  final CommentAuthor _self;
  final $Res Function(CommentAuthor) _then;

/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentAuthor].
extension CommentAuthorPatterns on CommentAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentAuthor value)  $default,){
final _that = this;
switch (_that) {
case _CommentAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _CommentAuthor():
return $default(_that.id,_that.username,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _CommentAuthor implements CommentAuthor {
  const _CommentAuthor({required this.id, required this.username, this.avatarUrl});
  

@override final  String id;
@override final  String username;
@override final  String? avatarUrl;

/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentAuthorCopyWith<_CommentAuthor> get copyWith => __$CommentAuthorCopyWithImpl<_CommentAuthor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,avatarUrl);

@override
String toString() {
  return 'CommentAuthor(id: $id, username: $username, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$CommentAuthorCopyWith<$Res> implements $CommentAuthorCopyWith<$Res> {
  factory _$CommentAuthorCopyWith(_CommentAuthor value, $Res Function(_CommentAuthor) _then) = __$CommentAuthorCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String? avatarUrl
});




}
/// @nodoc
class __$CommentAuthorCopyWithImpl<$Res>
    implements _$CommentAuthorCopyWith<$Res> {
  __$CommentAuthorCopyWithImpl(this._self, this._then);

  final _CommentAuthor _self;
  final $Res Function(_CommentAuthor) _then;

/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? avatarUrl = freezed,}) {
  return _then(_CommentAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PostComment {

 String get id; String get postId; CommentAuthor get author; String get body; DateTime get createdAt; int get likeCount;/// Viewer-scoped comment like (C11 heart).
 bool get liked;/// Non-null on replies — the parent comment this row indents under
/// (C11 reply-indent, design.md CommentRow spec).
 String? get parentId;
/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCommentCopyWith<PostComment> get copyWith => _$PostCommentCopyWithImpl<PostComment>(this as PostComment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostComment&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.author, author) || other.author == author)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}


@override
int get hashCode => Object.hash(runtimeType,id,postId,author,body,createdAt,likeCount,liked,parentId);

@override
String toString() {
  return 'PostComment(id: $id, postId: $postId, author: $author, body: $body, createdAt: $createdAt, likeCount: $likeCount, liked: $liked, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class $PostCommentCopyWith<$Res>  {
  factory $PostCommentCopyWith(PostComment value, $Res Function(PostComment) _then) = _$PostCommentCopyWithImpl;
@useResult
$Res call({
 String id, String postId, CommentAuthor author, String body, DateTime createdAt, int likeCount, bool liked, String? parentId
});


$CommentAuthorCopyWith<$Res> get author;

}
/// @nodoc
class _$PostCommentCopyWithImpl<$Res>
    implements $PostCommentCopyWith<$Res> {
  _$PostCommentCopyWithImpl(this._self, this._then);

  final PostComment _self;
  final $Res Function(PostComment) _then;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? postId = null,Object? author = null,Object? body = null,Object? createdAt = null,Object? likeCount = null,Object? liked = null,Object? parentId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as CommentAuthor,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentAuthorCopyWith<$Res> get author {
  
  return $CommentAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [PostComment].
extension PostCommentPatterns on PostComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostComment value)  $default,){
final _that = this;
switch (_that) {
case _PostComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostComment value)?  $default,){
final _that = this;
switch (_that) {
case _PostComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String postId,  CommentAuthor author,  String body,  DateTime createdAt,  int likeCount,  bool liked,  String? parentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostComment() when $default != null:
return $default(_that.id,_that.postId,_that.author,_that.body,_that.createdAt,_that.likeCount,_that.liked,_that.parentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String postId,  CommentAuthor author,  String body,  DateTime createdAt,  int likeCount,  bool liked,  String? parentId)  $default,) {final _that = this;
switch (_that) {
case _PostComment():
return $default(_that.id,_that.postId,_that.author,_that.body,_that.createdAt,_that.likeCount,_that.liked,_that.parentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String postId,  CommentAuthor author,  String body,  DateTime createdAt,  int likeCount,  bool liked,  String? parentId)?  $default,) {final _that = this;
switch (_that) {
case _PostComment() when $default != null:
return $default(_that.id,_that.postId,_that.author,_that.body,_that.createdAt,_that.likeCount,_that.liked,_that.parentId);case _:
  return null;

}
}

}

/// @nodoc


class _PostComment implements PostComment {
  const _PostComment({required this.id, required this.postId, required this.author, required this.body, required this.createdAt, this.likeCount = 0, this.liked = false, this.parentId});
  

@override final  String id;
@override final  String postId;
@override final  CommentAuthor author;
@override final  String body;
@override final  DateTime createdAt;
@override@JsonKey() final  int likeCount;
/// Viewer-scoped comment like (C11 heart).
@override@JsonKey() final  bool liked;
/// Non-null on replies — the parent comment this row indents under
/// (C11 reply-indent, design.md CommentRow spec).
@override final  String? parentId;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCommentCopyWith<_PostComment> get copyWith => __$PostCommentCopyWithImpl<_PostComment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostComment&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.author, author) || other.author == author)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}


@override
int get hashCode => Object.hash(runtimeType,id,postId,author,body,createdAt,likeCount,liked,parentId);

@override
String toString() {
  return 'PostComment(id: $id, postId: $postId, author: $author, body: $body, createdAt: $createdAt, likeCount: $likeCount, liked: $liked, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class _$PostCommentCopyWith<$Res> implements $PostCommentCopyWith<$Res> {
  factory _$PostCommentCopyWith(_PostComment value, $Res Function(_PostComment) _then) = __$PostCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String postId, CommentAuthor author, String body, DateTime createdAt, int likeCount, bool liked, String? parentId
});


@override $CommentAuthorCopyWith<$Res> get author;

}
/// @nodoc
class __$PostCommentCopyWithImpl<$Res>
    implements _$PostCommentCopyWith<$Res> {
  __$PostCommentCopyWithImpl(this._self, this._then);

  final _PostComment _self;
  final $Res Function(_PostComment) _then;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? postId = null,Object? author = null,Object? body = null,Object? createdAt = null,Object? likeCount = null,Object? liked = null,Object? parentId = freezed,}) {
  return _then(_PostComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as CommentAuthor,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentAuthorCopyWith<$Res> get author {
  
  return $CommentAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on
