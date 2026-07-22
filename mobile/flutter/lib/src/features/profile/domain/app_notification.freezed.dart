// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppNotification {

 String get id; NotificationKind get kind;/// The order/post id the row deep-links to.
 String get payloadRef; String get text; String get actorUsername; DateTime get createdAt; String? get actorAvatarUrl; String? get thumbUrl;/// `null` = unread (tinted row + dot).
 DateTime? get readAt;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.payloadRef, payloadRef) || other.payloadRef == payloadRef)&&(identical(other.text, text) || other.text == text)&&(identical(other.actorUsername, actorUsername) || other.actorUsername == actorUsername)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.actorAvatarUrl, actorAvatarUrl) || other.actorAvatarUrl == actorAvatarUrl)&&(identical(other.thumbUrl, thumbUrl) || other.thumbUrl == thumbUrl)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,payloadRef,text,actorUsername,createdAt,actorAvatarUrl,thumbUrl,readAt);

@override
String toString() {
  return 'AppNotification(id: $id, kind: $kind, payloadRef: $payloadRef, text: $text, actorUsername: $actorUsername, createdAt: $createdAt, actorAvatarUrl: $actorAvatarUrl, thumbUrl: $thumbUrl, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
 String id, NotificationKind kind, String payloadRef, String text, String actorUsername, DateTime createdAt, String? actorAvatarUrl, String? thumbUrl, DateTime? readAt
});




}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? payloadRef = null,Object? text = null,Object? actorUsername = null,Object? createdAt = null,Object? actorAvatarUrl = freezed,Object? thumbUrl = freezed,Object? readAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NotificationKind,payloadRef: null == payloadRef ? _self.payloadRef : payloadRef // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,actorUsername: null == actorUsername ? _self.actorUsername : actorUsername // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,actorAvatarUrl: freezed == actorAvatarUrl ? _self.actorAvatarUrl : actorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbUrl: freezed == thumbUrl ? _self.thumbUrl : thumbUrl // ignore: cast_nullable_to_non_nullable
as String?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  NotificationKind kind,  String payloadRef,  String text,  String actorUsername,  DateTime createdAt,  String? actorAvatarUrl,  String? thumbUrl,  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.kind,_that.payloadRef,_that.text,_that.actorUsername,_that.createdAt,_that.actorAvatarUrl,_that.thumbUrl,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  NotificationKind kind,  String payloadRef,  String text,  String actorUsername,  DateTime createdAt,  String? actorAvatarUrl,  String? thumbUrl,  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.id,_that.kind,_that.payloadRef,_that.text,_that.actorUsername,_that.createdAt,_that.actorAvatarUrl,_that.thumbUrl,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  NotificationKind kind,  String payloadRef,  String text,  String actorUsername,  DateTime createdAt,  String? actorAvatarUrl,  String? thumbUrl,  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.kind,_that.payloadRef,_that.text,_that.actorUsername,_that.createdAt,_that.actorAvatarUrl,_that.thumbUrl,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc


class _AppNotification extends AppNotification {
  const _AppNotification({required this.id, required this.kind, required this.payloadRef, required this.text, required this.actorUsername, required this.createdAt, this.actorAvatarUrl, this.thumbUrl, this.readAt}): super._();
  

@override final  String id;
@override final  NotificationKind kind;
/// The order/post id the row deep-links to.
@override final  String payloadRef;
@override final  String text;
@override final  String actorUsername;
@override final  DateTime createdAt;
@override final  String? actorAvatarUrl;
@override final  String? thumbUrl;
/// `null` = unread (tinted row + dot).
@override final  DateTime? readAt;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.payloadRef, payloadRef) || other.payloadRef == payloadRef)&&(identical(other.text, text) || other.text == text)&&(identical(other.actorUsername, actorUsername) || other.actorUsername == actorUsername)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.actorAvatarUrl, actorAvatarUrl) || other.actorAvatarUrl == actorAvatarUrl)&&(identical(other.thumbUrl, thumbUrl) || other.thumbUrl == thumbUrl)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,payloadRef,text,actorUsername,createdAt,actorAvatarUrl,thumbUrl,readAt);

@override
String toString() {
  return 'AppNotification(id: $id, kind: $kind, payloadRef: $payloadRef, text: $text, actorUsername: $actorUsername, createdAt: $createdAt, actorAvatarUrl: $actorAvatarUrl, thumbUrl: $thumbUrl, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, NotificationKind kind, String payloadRef, String text, String actorUsername, DateTime createdAt, String? actorAvatarUrl, String? thumbUrl, DateTime? readAt
});




}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? payloadRef = null,Object? text = null,Object? actorUsername = null,Object? createdAt = null,Object? actorAvatarUrl = freezed,Object? thumbUrl = freezed,Object? readAt = freezed,}) {
  return _then(_AppNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NotificationKind,payloadRef: null == payloadRef ? _self.payloadRef : payloadRef // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,actorUsername: null == actorUsername ? _self.actorUsername : actorUsername // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,actorAvatarUrl: freezed == actorAvatarUrl ? _self.actorAvatarUrl : actorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbUrl: freezed == thumbUrl ? _self.thumbUrl : thumbUrl // ignore: cast_nullable_to_non_nullable
as String?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
