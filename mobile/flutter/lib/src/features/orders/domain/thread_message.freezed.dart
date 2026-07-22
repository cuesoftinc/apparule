// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'thread_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ThreadMessage {

 String get id; String get orderId; String get authorId; String get body; DateTime get createdAt;/// Whether the signed-in viewer authored it (drives bubble side).
 bool get own; String? get imageUrl;
/// Create a copy of ThreadMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThreadMessageCopyWith<ThreadMessage> get copyWith => _$ThreadMessageCopyWithImpl<ThreadMessage>(this as ThreadMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThreadMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.own, own) || other.own == own)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,orderId,authorId,body,createdAt,own,imageUrl);

@override
String toString() {
  return 'ThreadMessage(id: $id, orderId: $orderId, authorId: $authorId, body: $body, createdAt: $createdAt, own: $own, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $ThreadMessageCopyWith<$Res>  {
  factory $ThreadMessageCopyWith(ThreadMessage value, $Res Function(ThreadMessage) _then) = _$ThreadMessageCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String authorId, String body, DateTime createdAt, bool own, String? imageUrl
});




}
/// @nodoc
class _$ThreadMessageCopyWithImpl<$Res>
    implements $ThreadMessageCopyWith<$Res> {
  _$ThreadMessageCopyWithImpl(this._self, this._then);

  final ThreadMessage _self;
  final $Res Function(ThreadMessage) _then;

/// Create a copy of ThreadMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? authorId = null,Object? body = null,Object? createdAt = null,Object? own = null,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,own: null == own ? _self.own : own // ignore: cast_nullable_to_non_nullable
as bool,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ThreadMessage].
extension ThreadMessagePatterns on ThreadMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThreadMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThreadMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThreadMessage value)  $default,){
final _that = this;
switch (_that) {
case _ThreadMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThreadMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ThreadMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String authorId,  String body,  DateTime createdAt,  bool own,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThreadMessage() when $default != null:
return $default(_that.id,_that.orderId,_that.authorId,_that.body,_that.createdAt,_that.own,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String authorId,  String body,  DateTime createdAt,  bool own,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _ThreadMessage():
return $default(_that.id,_that.orderId,_that.authorId,_that.body,_that.createdAt,_that.own,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String authorId,  String body,  DateTime createdAt,  bool own,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _ThreadMessage() when $default != null:
return $default(_that.id,_that.orderId,_that.authorId,_that.body,_that.createdAt,_that.own,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ThreadMessage implements ThreadMessage {
  const _ThreadMessage({required this.id, required this.orderId, required this.authorId, required this.body, required this.createdAt, required this.own, this.imageUrl});
  

@override final  String id;
@override final  String orderId;
@override final  String authorId;
@override final  String body;
@override final  DateTime createdAt;
/// Whether the signed-in viewer authored it (drives bubble side).
@override final  bool own;
@override final  String? imageUrl;

/// Create a copy of ThreadMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThreadMessageCopyWith<_ThreadMessage> get copyWith => __$ThreadMessageCopyWithImpl<_ThreadMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThreadMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.own, own) || other.own == own)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,orderId,authorId,body,createdAt,own,imageUrl);

@override
String toString() {
  return 'ThreadMessage(id: $id, orderId: $orderId, authorId: $authorId, body: $body, createdAt: $createdAt, own: $own, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$ThreadMessageCopyWith<$Res> implements $ThreadMessageCopyWith<$Res> {
  factory _$ThreadMessageCopyWith(_ThreadMessage value, $Res Function(_ThreadMessage) _then) = __$ThreadMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String authorId, String body, DateTime createdAt, bool own, String? imageUrl
});




}
/// @nodoc
class __$ThreadMessageCopyWithImpl<$Res>
    implements _$ThreadMessageCopyWith<$Res> {
  __$ThreadMessageCopyWithImpl(this._self, this._then);

  final _ThreadMessage _self;
  final $Res Function(_ThreadMessage) _then;

/// Create a copy of ThreadMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? authorId = null,Object? body = null,Object? createdAt = null,Object? own = null,Object? imageUrl = freezed,}) {
  return _then(_ThreadMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,own: null == own ? _self.own : own // ignore: cast_nullable_to_non_nullable
as bool,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
