// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileLocation {

 String get city; String get state; String get country;
/// Create a copy of ProfileLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileLocationCopyWith<ProfileLocation> get copyWith => _$ProfileLocationCopyWithImpl<ProfileLocation>(this as ProfileLocation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileLocation&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,city,state,country);

@override
String toString() {
  return 'ProfileLocation(city: $city, state: $state, country: $country)';
}


}

/// @nodoc
abstract mixin class $ProfileLocationCopyWith<$Res>  {
  factory $ProfileLocationCopyWith(ProfileLocation value, $Res Function(ProfileLocation) _then) = _$ProfileLocationCopyWithImpl;
@useResult
$Res call({
 String city, String state, String country
});




}
/// @nodoc
class _$ProfileLocationCopyWithImpl<$Res>
    implements $ProfileLocationCopyWith<$Res> {
  _$ProfileLocationCopyWithImpl(this._self, this._then);

  final ProfileLocation _self;
  final $Res Function(ProfileLocation) _then;

/// Create a copy of ProfileLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? state = null,Object? country = null,}) {
  return _then(_self.copyWith(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileLocation].
extension ProfileLocationPatterns on ProfileLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileLocation value)  $default,){
final _that = this;
switch (_that) {
case _ProfileLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileLocation value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  String state,  String country)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileLocation() when $default != null:
return $default(_that.city,_that.state,_that.country);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  String state,  String country)  $default,) {final _that = this;
switch (_that) {
case _ProfileLocation():
return $default(_that.city,_that.state,_that.country);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  String state,  String country)?  $default,) {final _that = this;
switch (_that) {
case _ProfileLocation() when $default != null:
return $default(_that.city,_that.state,_that.country);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileLocation implements ProfileLocation {
  const _ProfileLocation({required this.city, required this.state, required this.country});
  

@override final  String city;
@override final  String state;
@override final  String country;

/// Create a copy of ProfileLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileLocationCopyWith<_ProfileLocation> get copyWith => __$ProfileLocationCopyWithImpl<_ProfileLocation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileLocation&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,city,state,country);

@override
String toString() {
  return 'ProfileLocation(city: $city, state: $state, country: $country)';
}


}

/// @nodoc
abstract mixin class _$ProfileLocationCopyWith<$Res> implements $ProfileLocationCopyWith<$Res> {
  factory _$ProfileLocationCopyWith(_ProfileLocation value, $Res Function(_ProfileLocation) _then) = __$ProfileLocationCopyWithImpl;
@override @useResult
$Res call({
 String city, String state, String country
});




}
/// @nodoc
class __$ProfileLocationCopyWithImpl<$Res>
    implements _$ProfileLocationCopyWith<$Res> {
  __$ProfileLocationCopyWithImpl(this._self, this._then);

  final _ProfileLocation _self;
  final $Res Function(_ProfileLocation) _then;

/// Create a copy of ProfileLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? state = null,Object? country = null,}) {
  return _then(_ProfileLocation(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ConsentRecord {

 String get document; String get version; DateTime get acceptedAt;
/// Create a copy of ConsentRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentRecordCopyWith<ConsentRecord> get copyWith => _$ConsentRecordCopyWithImpl<ConsentRecord>(this as ConsentRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentRecord&&(identical(other.document, document) || other.document == document)&&(identical(other.version, version) || other.version == version)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt));
}


@override
int get hashCode => Object.hash(runtimeType,document,version,acceptedAt);

@override
String toString() {
  return 'ConsentRecord(document: $document, version: $version, acceptedAt: $acceptedAt)';
}


}

/// @nodoc
abstract mixin class $ConsentRecordCopyWith<$Res>  {
  factory $ConsentRecordCopyWith(ConsentRecord value, $Res Function(ConsentRecord) _then) = _$ConsentRecordCopyWithImpl;
@useResult
$Res call({
 String document, String version, DateTime acceptedAt
});




}
/// @nodoc
class _$ConsentRecordCopyWithImpl<$Res>
    implements $ConsentRecordCopyWith<$Res> {
  _$ConsentRecordCopyWithImpl(this._self, this._then);

  final ConsentRecord _self;
  final $Res Function(ConsentRecord) _then;

/// Create a copy of ConsentRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = null,Object? version = null,Object? acceptedAt = null,}) {
  return _then(_self.copyWith(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: null == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsentRecord].
extension ConsentRecordPatterns on ConsentRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsentRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsentRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsentRecord value)  $default,){
final _that = this;
switch (_that) {
case _ConsentRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsentRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ConsentRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String document,  String version,  DateTime acceptedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsentRecord() when $default != null:
return $default(_that.document,_that.version,_that.acceptedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String document,  String version,  DateTime acceptedAt)  $default,) {final _that = this;
switch (_that) {
case _ConsentRecord():
return $default(_that.document,_that.version,_that.acceptedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String document,  String version,  DateTime acceptedAt)?  $default,) {final _that = this;
switch (_that) {
case _ConsentRecord() when $default != null:
return $default(_that.document,_that.version,_that.acceptedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ConsentRecord implements ConsentRecord {
  const _ConsentRecord({required this.document, required this.version, required this.acceptedAt});
  

@override final  String document;
@override final  String version;
@override final  DateTime acceptedAt;

/// Create a copy of ConsentRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentRecordCopyWith<_ConsentRecord> get copyWith => __$ConsentRecordCopyWithImpl<_ConsentRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsentRecord&&(identical(other.document, document) || other.document == document)&&(identical(other.version, version) || other.version == version)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt));
}


@override
int get hashCode => Object.hash(runtimeType,document,version,acceptedAt);

@override
String toString() {
  return 'ConsentRecord(document: $document, version: $version, acceptedAt: $acceptedAt)';
}


}

/// @nodoc
abstract mixin class _$ConsentRecordCopyWith<$Res> implements $ConsentRecordCopyWith<$Res> {
  factory _$ConsentRecordCopyWith(_ConsentRecord value, $Res Function(_ConsentRecord) _then) = __$ConsentRecordCopyWithImpl;
@override @useResult
$Res call({
 String document, String version, DateTime acceptedAt
});




}
/// @nodoc
class __$ConsentRecordCopyWithImpl<$Res>
    implements _$ConsentRecordCopyWith<$Res> {
  __$ConsentRecordCopyWithImpl(this._self, this._then);

  final _ConsentRecord _self;
  final $Res Function(_ConsentRecord) _then;

/// Create a copy of ConsentRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = null,Object? version = null,Object? acceptedAt = null,}) {
  return _then(_ConsentRecord(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: null == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$NotificationPrefs {

 bool get quotesOrderStatus; bool get newRequests; bool get likesComments; bool get newFollowers; bool get freshOutfits; bool get freshnessReminders; bool get emailDigest;
/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPrefsCopyWith<NotificationPrefs> get copyWith => _$NotificationPrefsCopyWithImpl<NotificationPrefs>(this as NotificationPrefs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPrefs&&(identical(other.quotesOrderStatus, quotesOrderStatus) || other.quotesOrderStatus == quotesOrderStatus)&&(identical(other.newRequests, newRequests) || other.newRequests == newRequests)&&(identical(other.likesComments, likesComments) || other.likesComments == likesComments)&&(identical(other.newFollowers, newFollowers) || other.newFollowers == newFollowers)&&(identical(other.freshOutfits, freshOutfits) || other.freshOutfits == freshOutfits)&&(identical(other.freshnessReminders, freshnessReminders) || other.freshnessReminders == freshnessReminders)&&(identical(other.emailDigest, emailDigest) || other.emailDigest == emailDigest));
}


@override
int get hashCode => Object.hash(runtimeType,quotesOrderStatus,newRequests,likesComments,newFollowers,freshOutfits,freshnessReminders,emailDigest);

@override
String toString() {
  return 'NotificationPrefs(quotesOrderStatus: $quotesOrderStatus, newRequests: $newRequests, likesComments: $likesComments, newFollowers: $newFollowers, freshOutfits: $freshOutfits, freshnessReminders: $freshnessReminders, emailDigest: $emailDigest)';
}


}

/// @nodoc
abstract mixin class $NotificationPrefsCopyWith<$Res>  {
  factory $NotificationPrefsCopyWith(NotificationPrefs value, $Res Function(NotificationPrefs) _then) = _$NotificationPrefsCopyWithImpl;
@useResult
$Res call({
 bool quotesOrderStatus, bool newRequests, bool likesComments, bool newFollowers, bool freshOutfits, bool freshnessReminders, bool emailDigest
});




}
/// @nodoc
class _$NotificationPrefsCopyWithImpl<$Res>
    implements $NotificationPrefsCopyWith<$Res> {
  _$NotificationPrefsCopyWithImpl(this._self, this._then);

  final NotificationPrefs _self;
  final $Res Function(NotificationPrefs) _then;

/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quotesOrderStatus = null,Object? newRequests = null,Object? likesComments = null,Object? newFollowers = null,Object? freshOutfits = null,Object? freshnessReminders = null,Object? emailDigest = null,}) {
  return _then(_self.copyWith(
quotesOrderStatus: null == quotesOrderStatus ? _self.quotesOrderStatus : quotesOrderStatus // ignore: cast_nullable_to_non_nullable
as bool,newRequests: null == newRequests ? _self.newRequests : newRequests // ignore: cast_nullable_to_non_nullable
as bool,likesComments: null == likesComments ? _self.likesComments : likesComments // ignore: cast_nullable_to_non_nullable
as bool,newFollowers: null == newFollowers ? _self.newFollowers : newFollowers // ignore: cast_nullable_to_non_nullable
as bool,freshOutfits: null == freshOutfits ? _self.freshOutfits : freshOutfits // ignore: cast_nullable_to_non_nullable
as bool,freshnessReminders: null == freshnessReminders ? _self.freshnessReminders : freshnessReminders // ignore: cast_nullable_to_non_nullable
as bool,emailDigest: null == emailDigest ? _self.emailDigest : emailDigest // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPrefs].
extension NotificationPrefsPatterns on NotificationPrefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPrefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPrefs value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPrefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPrefs value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool quotesOrderStatus,  bool newRequests,  bool likesComments,  bool newFollowers,  bool freshOutfits,  bool freshnessReminders,  bool emailDigest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
return $default(_that.quotesOrderStatus,_that.newRequests,_that.likesComments,_that.newFollowers,_that.freshOutfits,_that.freshnessReminders,_that.emailDigest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool quotesOrderStatus,  bool newRequests,  bool likesComments,  bool newFollowers,  bool freshOutfits,  bool freshnessReminders,  bool emailDigest)  $default,) {final _that = this;
switch (_that) {
case _NotificationPrefs():
return $default(_that.quotesOrderStatus,_that.newRequests,_that.likesComments,_that.newFollowers,_that.freshOutfits,_that.freshnessReminders,_that.emailDigest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool quotesOrderStatus,  bool newRequests,  bool likesComments,  bool newFollowers,  bool freshOutfits,  bool freshnessReminders,  bool emailDigest)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
return $default(_that.quotesOrderStatus,_that.newRequests,_that.likesComments,_that.newFollowers,_that.freshOutfits,_that.freshnessReminders,_that.emailDigest);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationPrefs implements NotificationPrefs {
  const _NotificationPrefs({this.quotesOrderStatus = true, this.newRequests = true, this.likesComments = true, this.newFollowers = false, this.freshOutfits = true, this.freshnessReminders = true, this.emailDigest = false});
  

@override@JsonKey() final  bool quotesOrderStatus;
@override@JsonKey() final  bool newRequests;
@override@JsonKey() final  bool likesComments;
@override@JsonKey() final  bool newFollowers;
@override@JsonKey() final  bool freshOutfits;
@override@JsonKey() final  bool freshnessReminders;
@override@JsonKey() final  bool emailDigest;

/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPrefsCopyWith<_NotificationPrefs> get copyWith => __$NotificationPrefsCopyWithImpl<_NotificationPrefs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPrefs&&(identical(other.quotesOrderStatus, quotesOrderStatus) || other.quotesOrderStatus == quotesOrderStatus)&&(identical(other.newRequests, newRequests) || other.newRequests == newRequests)&&(identical(other.likesComments, likesComments) || other.likesComments == likesComments)&&(identical(other.newFollowers, newFollowers) || other.newFollowers == newFollowers)&&(identical(other.freshOutfits, freshOutfits) || other.freshOutfits == freshOutfits)&&(identical(other.freshnessReminders, freshnessReminders) || other.freshnessReminders == freshnessReminders)&&(identical(other.emailDigest, emailDigest) || other.emailDigest == emailDigest));
}


@override
int get hashCode => Object.hash(runtimeType,quotesOrderStatus,newRequests,likesComments,newFollowers,freshOutfits,freshnessReminders,emailDigest);

@override
String toString() {
  return 'NotificationPrefs(quotesOrderStatus: $quotesOrderStatus, newRequests: $newRequests, likesComments: $likesComments, newFollowers: $newFollowers, freshOutfits: $freshOutfits, freshnessReminders: $freshnessReminders, emailDigest: $emailDigest)';
}


}

/// @nodoc
abstract mixin class _$NotificationPrefsCopyWith<$Res> implements $NotificationPrefsCopyWith<$Res> {
  factory _$NotificationPrefsCopyWith(_NotificationPrefs value, $Res Function(_NotificationPrefs) _then) = __$NotificationPrefsCopyWithImpl;
@override @useResult
$Res call({
 bool quotesOrderStatus, bool newRequests, bool likesComments, bool newFollowers, bool freshOutfits, bool freshnessReminders, bool emailDigest
});




}
/// @nodoc
class __$NotificationPrefsCopyWithImpl<$Res>
    implements _$NotificationPrefsCopyWith<$Res> {
  __$NotificationPrefsCopyWithImpl(this._self, this._then);

  final _NotificationPrefs _self;
  final $Res Function(_NotificationPrefs) _then;

/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quotesOrderStatus = null,Object? newRequests = null,Object? likesComments = null,Object? newFollowers = null,Object? freshOutfits = null,Object? freshnessReminders = null,Object? emailDigest = null,}) {
  return _then(_NotificationPrefs(
quotesOrderStatus: null == quotesOrderStatus ? _self.quotesOrderStatus : quotesOrderStatus // ignore: cast_nullable_to_non_nullable
as bool,newRequests: null == newRequests ? _self.newRequests : newRequests // ignore: cast_nullable_to_non_nullable
as bool,likesComments: null == likesComments ? _self.likesComments : likesComments // ignore: cast_nullable_to_non_nullable
as bool,newFollowers: null == newFollowers ? _self.newFollowers : newFollowers // ignore: cast_nullable_to_non_nullable
as bool,freshOutfits: null == freshOutfits ? _self.freshOutfits : freshOutfits // ignore: cast_nullable_to_non_nullable
as bool,freshnessReminders: null == freshnessReminders ? _self.freshnessReminders : freshnessReminders // ignore: cast_nullable_to_non_nullable
as bool,emailDigest: null == emailDigest ? _self.emailDigest : emailDigest // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PrivacyPrefs {

 bool get aiProcessing; bool get nearbyRecommendations;
/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyPrefsCopyWith<PrivacyPrefs> get copyWith => _$PrivacyPrefsCopyWithImpl<PrivacyPrefs>(this as PrivacyPrefs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyPrefs&&(identical(other.aiProcessing, aiProcessing) || other.aiProcessing == aiProcessing)&&(identical(other.nearbyRecommendations, nearbyRecommendations) || other.nearbyRecommendations == nearbyRecommendations));
}


@override
int get hashCode => Object.hash(runtimeType,aiProcessing,nearbyRecommendations);

@override
String toString() {
  return 'PrivacyPrefs(aiProcessing: $aiProcessing, nearbyRecommendations: $nearbyRecommendations)';
}


}

/// @nodoc
abstract mixin class $PrivacyPrefsCopyWith<$Res>  {
  factory $PrivacyPrefsCopyWith(PrivacyPrefs value, $Res Function(PrivacyPrefs) _then) = _$PrivacyPrefsCopyWithImpl;
@useResult
$Res call({
 bool aiProcessing, bool nearbyRecommendations
});




}
/// @nodoc
class _$PrivacyPrefsCopyWithImpl<$Res>
    implements $PrivacyPrefsCopyWith<$Res> {
  _$PrivacyPrefsCopyWithImpl(this._self, this._then);

  final PrivacyPrefs _self;
  final $Res Function(PrivacyPrefs) _then;

/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aiProcessing = null,Object? nearbyRecommendations = null,}) {
  return _then(_self.copyWith(
aiProcessing: null == aiProcessing ? _self.aiProcessing : aiProcessing // ignore: cast_nullable_to_non_nullable
as bool,nearbyRecommendations: null == nearbyRecommendations ? _self.nearbyRecommendations : nearbyRecommendations // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivacyPrefs].
extension PrivacyPrefsPatterns on PrivacyPrefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivacyPrefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivacyPrefs value)  $default,){
final _that = this;
switch (_that) {
case _PrivacyPrefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivacyPrefs value)?  $default,){
final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool aiProcessing,  bool nearbyRecommendations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
return $default(_that.aiProcessing,_that.nearbyRecommendations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool aiProcessing,  bool nearbyRecommendations)  $default,) {final _that = this;
switch (_that) {
case _PrivacyPrefs():
return $default(_that.aiProcessing,_that.nearbyRecommendations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool aiProcessing,  bool nearbyRecommendations)?  $default,) {final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
return $default(_that.aiProcessing,_that.nearbyRecommendations);case _:
  return null;

}
}

}

/// @nodoc


class _PrivacyPrefs implements PrivacyPrefs {
  const _PrivacyPrefs({this.aiProcessing = true, this.nearbyRecommendations = true});
  

@override@JsonKey() final  bool aiProcessing;
@override@JsonKey() final  bool nearbyRecommendations;

/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivacyPrefsCopyWith<_PrivacyPrefs> get copyWith => __$PrivacyPrefsCopyWithImpl<_PrivacyPrefs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivacyPrefs&&(identical(other.aiProcessing, aiProcessing) || other.aiProcessing == aiProcessing)&&(identical(other.nearbyRecommendations, nearbyRecommendations) || other.nearbyRecommendations == nearbyRecommendations));
}


@override
int get hashCode => Object.hash(runtimeType,aiProcessing,nearbyRecommendations);

@override
String toString() {
  return 'PrivacyPrefs(aiProcessing: $aiProcessing, nearbyRecommendations: $nearbyRecommendations)';
}


}

/// @nodoc
abstract mixin class _$PrivacyPrefsCopyWith<$Res> implements $PrivacyPrefsCopyWith<$Res> {
  factory _$PrivacyPrefsCopyWith(_PrivacyPrefs value, $Res Function(_PrivacyPrefs) _then) = __$PrivacyPrefsCopyWithImpl;
@override @useResult
$Res call({
 bool aiProcessing, bool nearbyRecommendations
});




}
/// @nodoc
class __$PrivacyPrefsCopyWithImpl<$Res>
    implements _$PrivacyPrefsCopyWith<$Res> {
  __$PrivacyPrefsCopyWithImpl(this._self, this._then);

  final _PrivacyPrefs _self;
  final $Res Function(_PrivacyPrefs) _then;

/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aiProcessing = null,Object? nearbyRecommendations = null,}) {
  return _then(_PrivacyPrefs(
aiProcessing: null == aiProcessing ? _self.aiProcessing : aiProcessing // ignore: cast_nullable_to_non_nullable
as bool,nearbyRecommendations: null == nearbyRecommendations ? _self.nearbyRecommendations : nearbyRecommendations // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Profile {

 String get id; String get username; String get displayName; String get email; String? get bio; String? get avatarUrl; ProfileLocation? get location; NotificationPrefs get notificationPrefs; PrivacyPrefs get privacyPrefs; List<ConsentRecord> get consent; bool get deletionPending;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.notificationPrefs, notificationPrefs) || other.notificationPrefs == notificationPrefs)&&(identical(other.privacyPrefs, privacyPrefs) || other.privacyPrefs == privacyPrefs)&&const DeepCollectionEquality().equals(other.consent, consent)&&(identical(other.deletionPending, deletionPending) || other.deletionPending == deletionPending));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,email,bio,avatarUrl,location,notificationPrefs,privacyPrefs,const DeepCollectionEquality().hash(consent),deletionPending);

@override
String toString() {
  return 'Profile(id: $id, username: $username, displayName: $displayName, email: $email, bio: $bio, avatarUrl: $avatarUrl, location: $location, notificationPrefs: $notificationPrefs, privacyPrefs: $privacyPrefs, consent: $consent, deletionPending: $deletionPending)';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String username, String displayName, String email, String? bio, String? avatarUrl, ProfileLocation? location, NotificationPrefs notificationPrefs, PrivacyPrefs privacyPrefs, List<ConsentRecord> consent, bool deletionPending
});


$ProfileLocationCopyWith<$Res>? get location;$NotificationPrefsCopyWith<$Res> get notificationPrefs;$PrivacyPrefsCopyWith<$Res> get privacyPrefs;

}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? email = null,Object? bio = freezed,Object? avatarUrl = freezed,Object? location = freezed,Object? notificationPrefs = null,Object? privacyPrefs = null,Object? consent = null,Object? deletionPending = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as ProfileLocation?,notificationPrefs: null == notificationPrefs ? _self.notificationPrefs : notificationPrefs // ignore: cast_nullable_to_non_nullable
as NotificationPrefs,privacyPrefs: null == privacyPrefs ? _self.privacyPrefs : privacyPrefs // ignore: cast_nullable_to_non_nullable
as PrivacyPrefs,consent: null == consent ? _self.consent : consent // ignore: cast_nullable_to_non_nullable
as List<ConsentRecord>,deletionPending: null == deletionPending ? _self.deletionPending : deletionPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileLocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $ProfileLocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPrefsCopyWith<$Res> get notificationPrefs {
  
  return $NotificationPrefsCopyWith<$Res>(_self.notificationPrefs, (value) {
    return _then(_self.copyWith(notificationPrefs: value));
  });
}/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyPrefsCopyWith<$Res> get privacyPrefs {
  
  return $PrivacyPrefsCopyWith<$Res>(_self.privacyPrefs, (value) {
    return _then(_self.copyWith(privacyPrefs: value));
  });
}
}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String displayName,  String email,  String? bio,  String? avatarUrl,  ProfileLocation? location,  NotificationPrefs notificationPrefs,  PrivacyPrefs privacyPrefs,  List<ConsentRecord> consent,  bool deletionPending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.email,_that.bio,_that.avatarUrl,_that.location,_that.notificationPrefs,_that.privacyPrefs,_that.consent,_that.deletionPending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String displayName,  String email,  String? bio,  String? avatarUrl,  ProfileLocation? location,  NotificationPrefs notificationPrefs,  PrivacyPrefs privacyPrefs,  List<ConsentRecord> consent,  bool deletionPending)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.username,_that.displayName,_that.email,_that.bio,_that.avatarUrl,_that.location,_that.notificationPrefs,_that.privacyPrefs,_that.consent,_that.deletionPending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String displayName,  String email,  String? bio,  String? avatarUrl,  ProfileLocation? location,  NotificationPrefs notificationPrefs,  PrivacyPrefs privacyPrefs,  List<ConsentRecord> consent,  bool deletionPending)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.email,_that.bio,_that.avatarUrl,_that.location,_that.notificationPrefs,_that.privacyPrefs,_that.consent,_that.deletionPending);case _:
  return null;

}
}

}

/// @nodoc


class _Profile implements Profile {
  const _Profile({required this.id, required this.username, required this.displayName, required this.email, this.bio, this.avatarUrl, this.location, this.notificationPrefs = const NotificationPrefs(), this.privacyPrefs = const PrivacyPrefs(), final  List<ConsentRecord> consent = const <ConsentRecord>[], this.deletionPending = false}): _consent = consent;
  

@override final  String id;
@override final  String username;
@override final  String displayName;
@override final  String email;
@override final  String? bio;
@override final  String? avatarUrl;
@override final  ProfileLocation? location;
@override@JsonKey() final  NotificationPrefs notificationPrefs;
@override@JsonKey() final  PrivacyPrefs privacyPrefs;
 final  List<ConsentRecord> _consent;
@override@JsonKey() List<ConsentRecord> get consent {
  if (_consent is EqualUnmodifiableListView) return _consent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_consent);
}

@override@JsonKey() final  bool deletionPending;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.notificationPrefs, notificationPrefs) || other.notificationPrefs == notificationPrefs)&&(identical(other.privacyPrefs, privacyPrefs) || other.privacyPrefs == privacyPrefs)&&const DeepCollectionEquality().equals(other._consent, _consent)&&(identical(other.deletionPending, deletionPending) || other.deletionPending == deletionPending));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,email,bio,avatarUrl,location,notificationPrefs,privacyPrefs,const DeepCollectionEquality().hash(_consent),deletionPending);

@override
String toString() {
  return 'Profile(id: $id, username: $username, displayName: $displayName, email: $email, bio: $bio, avatarUrl: $avatarUrl, location: $location, notificationPrefs: $notificationPrefs, privacyPrefs: $privacyPrefs, consent: $consent, deletionPending: $deletionPending)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String displayName, String email, String? bio, String? avatarUrl, ProfileLocation? location, NotificationPrefs notificationPrefs, PrivacyPrefs privacyPrefs, List<ConsentRecord> consent, bool deletionPending
});


@override $ProfileLocationCopyWith<$Res>? get location;@override $NotificationPrefsCopyWith<$Res> get notificationPrefs;@override $PrivacyPrefsCopyWith<$Res> get privacyPrefs;

}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? email = null,Object? bio = freezed,Object? avatarUrl = freezed,Object? location = freezed,Object? notificationPrefs = null,Object? privacyPrefs = null,Object? consent = null,Object? deletionPending = null,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as ProfileLocation?,notificationPrefs: null == notificationPrefs ? _self.notificationPrefs : notificationPrefs // ignore: cast_nullable_to_non_nullable
as NotificationPrefs,privacyPrefs: null == privacyPrefs ? _self.privacyPrefs : privacyPrefs // ignore: cast_nullable_to_non_nullable
as PrivacyPrefs,consent: null == consent ? _self._consent : consent // ignore: cast_nullable_to_non_nullable
as List<ConsentRecord>,deletionPending: null == deletionPending ? _self.deletionPending : deletionPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileLocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $ProfileLocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPrefsCopyWith<$Res> get notificationPrefs {
  
  return $NotificationPrefsCopyWith<$Res>(_self.notificationPrefs, (value) {
    return _then(_self.copyWith(notificationPrefs: value));
  });
}/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyPrefsCopyWith<$Res> get privacyPrefs {
  
  return $PrivacyPrefsCopyWith<$Res>(_self.privacyPrefs, (value) {
    return _then(_self.copyWith(privacyPrefs: value));
  });
}
}

// dart format on
