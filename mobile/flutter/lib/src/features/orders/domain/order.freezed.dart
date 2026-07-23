// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderParty {

 String get id; String get username; String? get avatarUrl;
/// Create a copy of OrderParty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPartyCopyWith<OrderParty> get copyWith => _$OrderPartyCopyWithImpl<OrderParty>(this as OrderParty, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderParty&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,avatarUrl);

@override
String toString() {
  return 'OrderParty(id: $id, username: $username, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $OrderPartyCopyWith<$Res>  {
  factory $OrderPartyCopyWith(OrderParty value, $Res Function(OrderParty) _then) = _$OrderPartyCopyWithImpl;
@useResult
$Res call({
 String id, String username, String? avatarUrl
});




}
/// @nodoc
class _$OrderPartyCopyWithImpl<$Res>
    implements $OrderPartyCopyWith<$Res> {
  _$OrderPartyCopyWithImpl(this._self, this._then);

  final OrderParty _self;
  final $Res Function(OrderParty) _then;

/// Create a copy of OrderParty
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


/// Adds pattern-matching-related methods to [OrderParty].
extension OrderPartyPatterns on OrderParty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderParty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderParty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderParty value)  $default,){
final _that = this;
switch (_that) {
case _OrderParty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderParty value)?  $default,){
final _that = this;
switch (_that) {
case _OrderParty() when $default != null:
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
case _OrderParty() when $default != null:
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
case _OrderParty():
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
case _OrderParty() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _OrderParty implements OrderParty {
  const _OrderParty({required this.id, required this.username, this.avatarUrl});
  

@override final  String id;
@override final  String username;
@override final  String? avatarUrl;

/// Create a copy of OrderParty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPartyCopyWith<_OrderParty> get copyWith => __$OrderPartyCopyWithImpl<_OrderParty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderParty&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,username,avatarUrl);

@override
String toString() {
  return 'OrderParty(id: $id, username: $username, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$OrderPartyCopyWith<$Res> implements $OrderPartyCopyWith<$Res> {
  factory _$OrderPartyCopyWith(_OrderParty value, $Res Function(_OrderParty) _then) = __$OrderPartyCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String? avatarUrl
});




}
/// @nodoc
class __$OrderPartyCopyWithImpl<$Res>
    implements _$OrderPartyCopyWith<$Res> {
  __$OrderPartyCopyWithImpl(this._self, this._then);

  final _OrderParty _self;
  final $Res Function(_OrderParty) _then;

/// Create a copy of OrderParty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? avatarUrl = freezed,}) {
  return _then(_OrderParty(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$OrderPostSummary {

 String get id; String get caption; String get thumbUrl;
/// Create a copy of OrderPostSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPostSummaryCopyWith<OrderPostSummary> get copyWith => _$OrderPostSummaryCopyWithImpl<OrderPostSummary>(this as OrderPostSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPostSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.thumbUrl, thumbUrl) || other.thumbUrl == thumbUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,caption,thumbUrl);

@override
String toString() {
  return 'OrderPostSummary(id: $id, caption: $caption, thumbUrl: $thumbUrl)';
}


}

/// @nodoc
abstract mixin class $OrderPostSummaryCopyWith<$Res>  {
  factory $OrderPostSummaryCopyWith(OrderPostSummary value, $Res Function(OrderPostSummary) _then) = _$OrderPostSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String caption, String thumbUrl
});




}
/// @nodoc
class _$OrderPostSummaryCopyWithImpl<$Res>
    implements $OrderPostSummaryCopyWith<$Res> {
  _$OrderPostSummaryCopyWithImpl(this._self, this._then);

  final OrderPostSummary _self;
  final $Res Function(OrderPostSummary) _then;

/// Create a copy of OrderPostSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? caption = null,Object? thumbUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,thumbUrl: null == thumbUrl ? _self.thumbUrl : thumbUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderPostSummary].
extension OrderPostSummaryPatterns on OrderPostSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderPostSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderPostSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderPostSummary value)  $default,){
final _that = this;
switch (_that) {
case _OrderPostSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderPostSummary value)?  $default,){
final _that = this;
switch (_that) {
case _OrderPostSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String caption,  String thumbUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderPostSummary() when $default != null:
return $default(_that.id,_that.caption,_that.thumbUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String caption,  String thumbUrl)  $default,) {final _that = this;
switch (_that) {
case _OrderPostSummary():
return $default(_that.id,_that.caption,_that.thumbUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String caption,  String thumbUrl)?  $default,) {final _that = this;
switch (_that) {
case _OrderPostSummary() when $default != null:
return $default(_that.id,_that.caption,_that.thumbUrl);case _:
  return null;

}
}

}

/// @nodoc


class _OrderPostSummary implements OrderPostSummary {
  const _OrderPostSummary({required this.id, required this.caption, required this.thumbUrl});
  

@override final  String id;
@override final  String caption;
@override final  String thumbUrl;

/// Create a copy of OrderPostSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPostSummaryCopyWith<_OrderPostSummary> get copyWith => __$OrderPostSummaryCopyWithImpl<_OrderPostSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderPostSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.thumbUrl, thumbUrl) || other.thumbUrl == thumbUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,caption,thumbUrl);

@override
String toString() {
  return 'OrderPostSummary(id: $id, caption: $caption, thumbUrl: $thumbUrl)';
}


}

/// @nodoc
abstract mixin class _$OrderPostSummaryCopyWith<$Res> implements $OrderPostSummaryCopyWith<$Res> {
  factory _$OrderPostSummaryCopyWith(_OrderPostSummary value, $Res Function(_OrderPostSummary) _then) = __$OrderPostSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String caption, String thumbUrl
});




}
/// @nodoc
class __$OrderPostSummaryCopyWithImpl<$Res>
    implements _$OrderPostSummaryCopyWith<$Res> {
  __$OrderPostSummaryCopyWithImpl(this._self, this._then);

  final _OrderPostSummary _self;
  final $Res Function(_OrderPostSummary) _then;

/// Create a copy of OrderPostSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? caption = null,Object? thumbUrl = null,}) {
  return _then(_OrderPostSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,thumbUrl: null == thumbUrl ? _self.thumbUrl : thumbUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DeliveryAddress {

 String get recipientName; String get phone; String get line1; String get city; String get state; String get country;
/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<DeliveryAddress> get copyWith => _$DeliveryAddressCopyWithImpl<DeliveryAddress>(this as DeliveryAddress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryAddress&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,recipientName,phone,line1,city,state,country);

@override
String toString() {
  return 'DeliveryAddress(recipientName: $recipientName, phone: $phone, line1: $line1, city: $city, state: $state, country: $country)';
}


}

/// @nodoc
abstract mixin class $DeliveryAddressCopyWith<$Res>  {
  factory $DeliveryAddressCopyWith(DeliveryAddress value, $Res Function(DeliveryAddress) _then) = _$DeliveryAddressCopyWithImpl;
@useResult
$Res call({
 String recipientName, String phone, String line1, String city, String state, String country
});




}
/// @nodoc
class _$DeliveryAddressCopyWithImpl<$Res>
    implements $DeliveryAddressCopyWith<$Res> {
  _$DeliveryAddressCopyWithImpl(this._self, this._then);

  final DeliveryAddress _self;
  final $Res Function(DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recipientName = null,Object? phone = null,Object? line1 = null,Object? city = null,Object? state = null,Object? country = null,}) {
  return _then(_self.copyWith(
recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryAddress].
extension DeliveryAddressPatterns on DeliveryAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryAddress value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryAddress value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String recipientName,  String phone,  String line1,  String city,  String state,  String country)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.recipientName,_that.phone,_that.line1,_that.city,_that.state,_that.country);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String recipientName,  String phone,  String line1,  String city,  String state,  String country)  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that.recipientName,_that.phone,_that.line1,_that.city,_that.state,_that.country);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String recipientName,  String phone,  String line1,  String city,  String state,  String country)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.recipientName,_that.phone,_that.line1,_that.city,_that.state,_that.country);case _:
  return null;

}
}

}

/// @nodoc


class _DeliveryAddress implements DeliveryAddress {
  const _DeliveryAddress({required this.recipientName, required this.phone, required this.line1, required this.city, required this.state, required this.country});
  

@override final  String recipientName;
@override final  String phone;
@override final  String line1;
@override final  String city;
@override final  String state;
@override final  String country;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryAddressCopyWith<_DeliveryAddress> get copyWith => __$DeliveryAddressCopyWithImpl<_DeliveryAddress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryAddress&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,recipientName,phone,line1,city,state,country);

@override
String toString() {
  return 'DeliveryAddress(recipientName: $recipientName, phone: $phone, line1: $line1, city: $city, state: $state, country: $country)';
}


}

/// @nodoc
abstract mixin class _$DeliveryAddressCopyWith<$Res> implements $DeliveryAddressCopyWith<$Res> {
  factory _$DeliveryAddressCopyWith(_DeliveryAddress value, $Res Function(_DeliveryAddress) _then) = __$DeliveryAddressCopyWithImpl;
@override @useResult
$Res call({
 String recipientName, String phone, String line1, String city, String state, String country
});




}
/// @nodoc
class __$DeliveryAddressCopyWithImpl<$Res>
    implements _$DeliveryAddressCopyWith<$Res> {
  __$DeliveryAddressCopyWithImpl(this._self, this._then);

  final _DeliveryAddress _self;
  final $Res Function(_DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recipientName = null,Object? phone = null,Object? line1 = null,Object? city = null,Object? state = null,Object? country = null,}) {
  return _then(_DeliveryAddress(
recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SnapshotMeasurement {

 String get name; double get valueCm;
/// Create a copy of SnapshotMeasurement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnapshotMeasurementCopyWith<SnapshotMeasurement> get copyWith => _$SnapshotMeasurementCopyWithImpl<SnapshotMeasurement>(this as SnapshotMeasurement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SnapshotMeasurement&&(identical(other.name, name) || other.name == name)&&(identical(other.valueCm, valueCm) || other.valueCm == valueCm));
}


@override
int get hashCode => Object.hash(runtimeType,name,valueCm);

@override
String toString() {
  return 'SnapshotMeasurement(name: $name, valueCm: $valueCm)';
}


}

/// @nodoc
abstract mixin class $SnapshotMeasurementCopyWith<$Res>  {
  factory $SnapshotMeasurementCopyWith(SnapshotMeasurement value, $Res Function(SnapshotMeasurement) _then) = _$SnapshotMeasurementCopyWithImpl;
@useResult
$Res call({
 String name, double valueCm
});




}
/// @nodoc
class _$SnapshotMeasurementCopyWithImpl<$Res>
    implements $SnapshotMeasurementCopyWith<$Res> {
  _$SnapshotMeasurementCopyWithImpl(this._self, this._then);

  final SnapshotMeasurement _self;
  final $Res Function(SnapshotMeasurement) _then;

/// Create a copy of SnapshotMeasurement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? valueCm = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,valueCm: null == valueCm ? _self.valueCm : valueCm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SnapshotMeasurement].
extension SnapshotMeasurementPatterns on SnapshotMeasurement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SnapshotMeasurement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SnapshotMeasurement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SnapshotMeasurement value)  $default,){
final _that = this;
switch (_that) {
case _SnapshotMeasurement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SnapshotMeasurement value)?  $default,){
final _that = this;
switch (_that) {
case _SnapshotMeasurement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double valueCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SnapshotMeasurement() when $default != null:
return $default(_that.name,_that.valueCm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double valueCm)  $default,) {final _that = this;
switch (_that) {
case _SnapshotMeasurement():
return $default(_that.name,_that.valueCm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double valueCm)?  $default,) {final _that = this;
switch (_that) {
case _SnapshotMeasurement() when $default != null:
return $default(_that.name,_that.valueCm);case _:
  return null;

}
}

}

/// @nodoc


class _SnapshotMeasurement implements SnapshotMeasurement {
  const _SnapshotMeasurement({required this.name, required this.valueCm});
  

@override final  String name;
@override final  double valueCm;

/// Create a copy of SnapshotMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnapshotMeasurementCopyWith<_SnapshotMeasurement> get copyWith => __$SnapshotMeasurementCopyWithImpl<_SnapshotMeasurement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SnapshotMeasurement&&(identical(other.name, name) || other.name == name)&&(identical(other.valueCm, valueCm) || other.valueCm == valueCm));
}


@override
int get hashCode => Object.hash(runtimeType,name,valueCm);

@override
String toString() {
  return 'SnapshotMeasurement(name: $name, valueCm: $valueCm)';
}


}

/// @nodoc
abstract mixin class _$SnapshotMeasurementCopyWith<$Res> implements $SnapshotMeasurementCopyWith<$Res> {
  factory _$SnapshotMeasurementCopyWith(_SnapshotMeasurement value, $Res Function(_SnapshotMeasurement) _then) = __$SnapshotMeasurementCopyWithImpl;
@override @useResult
$Res call({
 String name, double valueCm
});




}
/// @nodoc
class __$SnapshotMeasurementCopyWithImpl<$Res>
    implements _$SnapshotMeasurementCopyWith<$Res> {
  __$SnapshotMeasurementCopyWithImpl(this._self, this._then);

  final _SnapshotMeasurement _self;
  final $Res Function(_SnapshotMeasurement) _then;

/// Create a copy of SnapshotMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? valueCm = null,}) {
  return _then(_SnapshotMeasurement(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,valueCm: null == valueCm ? _self.valueCm : valueCm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$OrderSnapshot {

 String get method; DateTime get measuredAt; List<SnapshotMeasurement> get measurements;
/// Create a copy of OrderSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderSnapshotCopyWith<OrderSnapshot> get copyWith => _$OrderSnapshotCopyWithImpl<OrderSnapshot>(this as OrderSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderSnapshot&&(identical(other.method, method) || other.method == method)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt)&&const DeepCollectionEquality().equals(other.measurements, measurements));
}


@override
int get hashCode => Object.hash(runtimeType,method,measuredAt,const DeepCollectionEquality().hash(measurements));

@override
String toString() {
  return 'OrderSnapshot(method: $method, measuredAt: $measuredAt, measurements: $measurements)';
}


}

/// @nodoc
abstract mixin class $OrderSnapshotCopyWith<$Res>  {
  factory $OrderSnapshotCopyWith(OrderSnapshot value, $Res Function(OrderSnapshot) _then) = _$OrderSnapshotCopyWithImpl;
@useResult
$Res call({
 String method, DateTime measuredAt, List<SnapshotMeasurement> measurements
});




}
/// @nodoc
class _$OrderSnapshotCopyWithImpl<$Res>
    implements $OrderSnapshotCopyWith<$Res> {
  _$OrderSnapshotCopyWithImpl(this._self, this._then);

  final OrderSnapshot _self;
  final $Res Function(OrderSnapshot) _then;

/// Create a copy of OrderSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? measuredAt = null,Object? measurements = null,}) {
  return _then(_self.copyWith(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,measuredAt: null == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as DateTime,measurements: null == measurements ? _self.measurements : measurements // ignore: cast_nullable_to_non_nullable
as List<SnapshotMeasurement>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderSnapshot].
extension OrderSnapshotPatterns on OrderSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _OrderSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _OrderSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String method,  DateTime measuredAt,  List<SnapshotMeasurement> measurements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderSnapshot() when $default != null:
return $default(_that.method,_that.measuredAt,_that.measurements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String method,  DateTime measuredAt,  List<SnapshotMeasurement> measurements)  $default,) {final _that = this;
switch (_that) {
case _OrderSnapshot():
return $default(_that.method,_that.measuredAt,_that.measurements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String method,  DateTime measuredAt,  List<SnapshotMeasurement> measurements)?  $default,) {final _that = this;
switch (_that) {
case _OrderSnapshot() when $default != null:
return $default(_that.method,_that.measuredAt,_that.measurements);case _:
  return null;

}
}

}

/// @nodoc


class _OrderSnapshot implements OrderSnapshot {
  const _OrderSnapshot({required this.method, required this.measuredAt, required final  List<SnapshotMeasurement> measurements}): _measurements = measurements;
  

@override final  String method;
@override final  DateTime measuredAt;
 final  List<SnapshotMeasurement> _measurements;
@override List<SnapshotMeasurement> get measurements {
  if (_measurements is EqualUnmodifiableListView) return _measurements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_measurements);
}


/// Create a copy of OrderSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderSnapshotCopyWith<_OrderSnapshot> get copyWith => __$OrderSnapshotCopyWithImpl<_OrderSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderSnapshot&&(identical(other.method, method) || other.method == method)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt)&&const DeepCollectionEquality().equals(other._measurements, _measurements));
}


@override
int get hashCode => Object.hash(runtimeType,method,measuredAt,const DeepCollectionEquality().hash(_measurements));

@override
String toString() {
  return 'OrderSnapshot(method: $method, measuredAt: $measuredAt, measurements: $measurements)';
}


}

/// @nodoc
abstract mixin class _$OrderSnapshotCopyWith<$Res> implements $OrderSnapshotCopyWith<$Res> {
  factory _$OrderSnapshotCopyWith(_OrderSnapshot value, $Res Function(_OrderSnapshot) _then) = __$OrderSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String method, DateTime measuredAt, List<SnapshotMeasurement> measurements
});




}
/// @nodoc
class __$OrderSnapshotCopyWithImpl<$Res>
    implements _$OrderSnapshotCopyWith<$Res> {
  __$OrderSnapshotCopyWithImpl(this._self, this._then);

  final _OrderSnapshot _self;
  final $Res Function(_OrderSnapshot) _then;

/// Create a copy of OrderSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? measuredAt = null,Object? measurements = null,}) {
  return _then(_OrderSnapshot(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,measuredAt: null == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as DateTime,measurements: null == measurements ? _self._measurements : measurements // ignore: cast_nullable_to_non_nullable
as List<SnapshotMeasurement>,
  ));
}


}

/// @nodoc
mixin _$OrderEvent {

 String get kind; String get actor; DateTime get createdAt;
/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderEventCopyWith<OrderEvent> get copyWith => _$OrderEventCopyWithImpl<OrderEvent>(this as OrderEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,kind,actor,createdAt);

@override
String toString() {
  return 'OrderEvent(kind: $kind, actor: $actor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderEventCopyWith<$Res>  {
  factory $OrderEventCopyWith(OrderEvent value, $Res Function(OrderEvent) _then) = _$OrderEventCopyWithImpl;
@useResult
$Res call({
 String kind, String actor, DateTime createdAt
});




}
/// @nodoc
class _$OrderEventCopyWithImpl<$Res>
    implements $OrderEventCopyWith<$Res> {
  _$OrderEventCopyWithImpl(this._self, this._then);

  final OrderEvent _self;
  final $Res Function(OrderEvent) _then;

/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? actor = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderEvent].
extension OrderEventPatterns on OrderEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderEvent value)  $default,){
final _that = this;
switch (_that) {
case _OrderEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderEvent value)?  $default,){
final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String actor,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
return $default(_that.kind,_that.actor,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String actor,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderEvent():
return $default(_that.kind,_that.actor,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String actor,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
return $default(_that.kind,_that.actor,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _OrderEvent implements OrderEvent {
  const _OrderEvent({required this.kind, required this.actor, required this.createdAt});
  

@override final  String kind;
@override final  String actor;
@override final  DateTime createdAt;

/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderEventCopyWith<_OrderEvent> get copyWith => __$OrderEventCopyWithImpl<_OrderEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,kind,actor,createdAt);

@override
String toString() {
  return 'OrderEvent(kind: $kind, actor: $actor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderEventCopyWith<$Res> implements $OrderEventCopyWith<$Res> {
  factory _$OrderEventCopyWith(_OrderEvent value, $Res Function(_OrderEvent) _then) = __$OrderEventCopyWithImpl;
@override @useResult
$Res call({
 String kind, String actor, DateTime createdAt
});




}
/// @nodoc
class __$OrderEventCopyWithImpl<$Res>
    implements _$OrderEventCopyWith<$Res> {
  __$OrderEventCopyWithImpl(this._self, this._then);

  final _OrderEvent _self;
  final $Res Function(_OrderEvent) _then;

/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? actor = null,Object? createdAt = null,}) {
  return _then(_OrderEvent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$OrderDispute {

 DisputeReason get reason; String? get detail;
/// Create a copy of OrderDispute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDisputeCopyWith<OrderDispute> get copyWith => _$OrderDisputeCopyWithImpl<OrderDispute>(this as OrderDispute, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDispute&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,reason,detail);

@override
String toString() {
  return 'OrderDispute(reason: $reason, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $OrderDisputeCopyWith<$Res>  {
  factory $OrderDisputeCopyWith(OrderDispute value, $Res Function(OrderDispute) _then) = _$OrderDisputeCopyWithImpl;
@useResult
$Res call({
 DisputeReason reason, String? detail
});




}
/// @nodoc
class _$OrderDisputeCopyWithImpl<$Res>
    implements $OrderDisputeCopyWith<$Res> {
  _$OrderDisputeCopyWithImpl(this._self, this._then);

  final OrderDispute _self;
  final $Res Function(OrderDispute) _then;

/// Create a copy of OrderDispute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,Object? detail = freezed,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as DisputeReason,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderDispute].
extension OrderDisputePatterns on OrderDispute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDispute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDispute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDispute value)  $default,){
final _that = this;
switch (_that) {
case _OrderDispute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDispute value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDispute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DisputeReason reason,  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDispute() when $default != null:
return $default(_that.reason,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DisputeReason reason,  String? detail)  $default,) {final _that = this;
switch (_that) {
case _OrderDispute():
return $default(_that.reason,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DisputeReason reason,  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _OrderDispute() when $default != null:
return $default(_that.reason,_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class _OrderDispute implements OrderDispute {
  const _OrderDispute({required this.reason, this.detail});
  

@override final  DisputeReason reason;
@override final  String? detail;

/// Create a copy of OrderDispute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDisputeCopyWith<_OrderDispute> get copyWith => __$OrderDisputeCopyWithImpl<_OrderDispute>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDispute&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,reason,detail);

@override
String toString() {
  return 'OrderDispute(reason: $reason, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$OrderDisputeCopyWith<$Res> implements $OrderDisputeCopyWith<$Res> {
  factory _$OrderDisputeCopyWith(_OrderDispute value, $Res Function(_OrderDispute) _then) = __$OrderDisputeCopyWithImpl;
@override @useResult
$Res call({
 DisputeReason reason, String? detail
});




}
/// @nodoc
class __$OrderDisputeCopyWithImpl<$Res>
    implements _$OrderDisputeCopyWith<$Res> {
  __$OrderDisputeCopyWithImpl(this._self, this._then);

  final _OrderDispute _self;
  final $Res Function(_OrderDispute) _then;

/// Create a copy of OrderDispute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? detail = freezed,}) {
  return _then(_OrderDispute(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as DisputeReason,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$OrderPayment {

 PaymentState get state; int get amountCents; int get platformFeeCents;
/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<OrderPayment> get copyWith => _$OrderPaymentCopyWithImpl<OrderPayment>(this as OrderPayment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPayment&&(identical(other.state, state) || other.state == state)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.platformFeeCents, platformFeeCents) || other.platformFeeCents == platformFeeCents));
}


@override
int get hashCode => Object.hash(runtimeType,state,amountCents,platformFeeCents);

@override
String toString() {
  return 'OrderPayment(state: $state, amountCents: $amountCents, platformFeeCents: $platformFeeCents)';
}


}

/// @nodoc
abstract mixin class $OrderPaymentCopyWith<$Res>  {
  factory $OrderPaymentCopyWith(OrderPayment value, $Res Function(OrderPayment) _then) = _$OrderPaymentCopyWithImpl;
@useResult
$Res call({
 PaymentState state, int amountCents, int platformFeeCents
});




}
/// @nodoc
class _$OrderPaymentCopyWithImpl<$Res>
    implements $OrderPaymentCopyWith<$Res> {
  _$OrderPaymentCopyWithImpl(this._self, this._then);

  final OrderPayment _self;
  final $Res Function(OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? amountCents = null,Object? platformFeeCents = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PaymentState,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,platformFeeCents: null == platformFeeCents ? _self.platformFeeCents : platformFeeCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderPayment].
extension OrderPaymentPatterns on OrderPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderPayment value)  $default,){
final _that = this;
switch (_that) {
case _OrderPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderPayment value)?  $default,){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PaymentState state,  int amountCents,  int platformFeeCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.state,_that.amountCents,_that.platformFeeCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PaymentState state,  int amountCents,  int platformFeeCents)  $default,) {final _that = this;
switch (_that) {
case _OrderPayment():
return $default(_that.state,_that.amountCents,_that.platformFeeCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PaymentState state,  int amountCents,  int platformFeeCents)?  $default,) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.state,_that.amountCents,_that.platformFeeCents);case _:
  return null;

}
}

}

/// @nodoc


class _OrderPayment implements OrderPayment {
  const _OrderPayment({required this.state, required this.amountCents, required this.platformFeeCents});
  

@override final  PaymentState state;
@override final  int amountCents;
@override final  int platformFeeCents;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPaymentCopyWith<_OrderPayment> get copyWith => __$OrderPaymentCopyWithImpl<_OrderPayment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderPayment&&(identical(other.state, state) || other.state == state)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.platformFeeCents, platformFeeCents) || other.platformFeeCents == platformFeeCents));
}


@override
int get hashCode => Object.hash(runtimeType,state,amountCents,platformFeeCents);

@override
String toString() {
  return 'OrderPayment(state: $state, amountCents: $amountCents, platformFeeCents: $platformFeeCents)';
}


}

/// @nodoc
abstract mixin class _$OrderPaymentCopyWith<$Res> implements $OrderPaymentCopyWith<$Res> {
  factory _$OrderPaymentCopyWith(_OrderPayment value, $Res Function(_OrderPayment) _then) = __$OrderPaymentCopyWithImpl;
@override @useResult
$Res call({
 PaymentState state, int amountCents, int platformFeeCents
});




}
/// @nodoc
class __$OrderPaymentCopyWithImpl<$Res>
    implements _$OrderPaymentCopyWith<$Res> {
  __$OrderPaymentCopyWithImpl(this._self, this._then);

  final _OrderPayment _self;
  final $Res Function(_OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? amountCents = null,Object? platformFeeCents = null,}) {
  return _then(_OrderPayment(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PaymentState,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,platformFeeCents: null == platformFeeCents ? _self.platformFeeCents : platformFeeCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Order {

 String get id; String get orderNumber; OrderPostSummary get post; OrderParty get customer; OrderParty get designer; OrderStatus get status; OrderSnapshot get snapshot; List<OrderEvent> get events; DateTime get createdAt;/// The signed-in viewer's side (drives the C8 role tabs + actions).
 OrderRole get viewerRole; String get notes; int? get budgetCents; int? get quoteCents; String get currency; DateTime? get dueAt; String? get tracking; DeclineReason? get declineReason;/// The optional note the designer attached when declining (D04 —
/// pages.md B3 "reason enum + optional note").
 String? get declineNote; OrderDispute? get dispute; DeliveryAddress? get delivery; OrderPayment? get payment;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.post, post) || other.post == post)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.designer, designer) || other.designer == designer)&&(identical(other.status, status) || other.status == status)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.viewerRole, viewerRole) || other.viewerRole == viewerRole)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.budgetCents, budgetCents) || other.budgetCents == budgetCents)&&(identical(other.quoteCents, quoteCents) || other.quoteCents == quoteCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.declineReason, declineReason) || other.declineReason == declineReason)&&(identical(other.declineNote, declineNote) || other.declineNote == declineNote)&&(identical(other.dispute, dispute) || other.dispute == dispute)&&(identical(other.delivery, delivery) || other.delivery == delivery)&&(identical(other.payment, payment) || other.payment == payment));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,orderNumber,post,customer,designer,status,snapshot,const DeepCollectionEquality().hash(events),createdAt,viewerRole,notes,budgetCents,quoteCents,currency,dueAt,tracking,declineReason,declineNote,dispute,delivery,payment]);

@override
String toString() {
  return 'Order(id: $id, orderNumber: $orderNumber, post: $post, customer: $customer, designer: $designer, status: $status, snapshot: $snapshot, events: $events, createdAt: $createdAt, viewerRole: $viewerRole, notes: $notes, budgetCents: $budgetCents, quoteCents: $quoteCents, currency: $currency, dueAt: $dueAt, tracking: $tracking, declineReason: $declineReason, declineNote: $declineNote, dispute: $dispute, delivery: $delivery, payment: $payment)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String orderNumber, OrderPostSummary post, OrderParty customer, OrderParty designer, OrderStatus status, OrderSnapshot snapshot, List<OrderEvent> events, DateTime createdAt, OrderRole viewerRole, String notes, int? budgetCents, int? quoteCents, String currency, DateTime? dueAt, String? tracking, DeclineReason? declineReason, String? declineNote, OrderDispute? dispute, DeliveryAddress? delivery, OrderPayment? payment
});


$OrderPostSummaryCopyWith<$Res> get post;$OrderPartyCopyWith<$Res> get customer;$OrderPartyCopyWith<$Res> get designer;$OrderSnapshotCopyWith<$Res> get snapshot;$OrderDisputeCopyWith<$Res>? get dispute;$DeliveryAddressCopyWith<$Res>? get delivery;$OrderPaymentCopyWith<$Res>? get payment;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderNumber = null,Object? post = null,Object? customer = null,Object? designer = null,Object? status = null,Object? snapshot = null,Object? events = null,Object? createdAt = null,Object? viewerRole = null,Object? notes = null,Object? budgetCents = freezed,Object? quoteCents = freezed,Object? currency = null,Object? dueAt = freezed,Object? tracking = freezed,Object? declineReason = freezed,Object? declineNote = freezed,Object? dispute = freezed,Object? delivery = freezed,Object? payment = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String,post: null == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as OrderPostSummary,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as OrderParty,designer: null == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as OrderParty,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as OrderSnapshot,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<OrderEvent>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,viewerRole: null == viewerRole ? _self.viewerRole : viewerRole // ignore: cast_nullable_to_non_nullable
as OrderRole,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,budgetCents: freezed == budgetCents ? _self.budgetCents : budgetCents // ignore: cast_nullable_to_non_nullable
as int?,quoteCents: freezed == quoteCents ? _self.quoteCents : quoteCents // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tracking: freezed == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as String?,declineReason: freezed == declineReason ? _self.declineReason : declineReason // ignore: cast_nullable_to_non_nullable
as DeclineReason?,declineNote: freezed == declineNote ? _self.declineNote : declineNote // ignore: cast_nullable_to_non_nullable
as String?,dispute: freezed == dispute ? _self.dispute : dispute // ignore: cast_nullable_to_non_nullable
as OrderDispute?,delivery: freezed == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as OrderPayment?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPostSummaryCopyWith<$Res> get post {
  
  return $OrderPostSummaryCopyWith<$Res>(_self.post, (value) {
    return _then(_self.copyWith(post: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPartyCopyWith<$Res> get customer {
  
  return $OrderPartyCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPartyCopyWith<$Res> get designer {
  
  return $OrderPartyCopyWith<$Res>(_self.designer, (value) {
    return _then(_self.copyWith(designer: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderSnapshotCopyWith<$Res> get snapshot {
  
  return $OrderSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderDisputeCopyWith<$Res>? get dispute {
    if (_self.dispute == null) {
    return null;
  }

  return $OrderDisputeCopyWith<$Res>(_self.dispute!, (value) {
    return _then(_self.copyWith(dispute: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get delivery {
    if (_self.delivery == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.delivery!, (value) {
    return _then(_self.copyWith(delivery: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<$Res>? get payment {
    if (_self.payment == null) {
    return null;
  }

  return $OrderPaymentCopyWith<$Res>(_self.payment!, (value) {
    return _then(_self.copyWith(payment: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderNumber,  OrderPostSummary post,  OrderParty customer,  OrderParty designer,  OrderStatus status,  OrderSnapshot snapshot,  List<OrderEvent> events,  DateTime createdAt,  OrderRole viewerRole,  String notes,  int? budgetCents,  int? quoteCents,  String currency,  DateTime? dueAt,  String? tracking,  DeclineReason? declineReason,  String? declineNote,  OrderDispute? dispute,  DeliveryAddress? delivery,  OrderPayment? payment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.orderNumber,_that.post,_that.customer,_that.designer,_that.status,_that.snapshot,_that.events,_that.createdAt,_that.viewerRole,_that.notes,_that.budgetCents,_that.quoteCents,_that.currency,_that.dueAt,_that.tracking,_that.declineReason,_that.declineNote,_that.dispute,_that.delivery,_that.payment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderNumber,  OrderPostSummary post,  OrderParty customer,  OrderParty designer,  OrderStatus status,  OrderSnapshot snapshot,  List<OrderEvent> events,  DateTime createdAt,  OrderRole viewerRole,  String notes,  int? budgetCents,  int? quoteCents,  String currency,  DateTime? dueAt,  String? tracking,  DeclineReason? declineReason,  String? declineNote,  OrderDispute? dispute,  DeliveryAddress? delivery,  OrderPayment? payment)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.orderNumber,_that.post,_that.customer,_that.designer,_that.status,_that.snapshot,_that.events,_that.createdAt,_that.viewerRole,_that.notes,_that.budgetCents,_that.quoteCents,_that.currency,_that.dueAt,_that.tracking,_that.declineReason,_that.declineNote,_that.dispute,_that.delivery,_that.payment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderNumber,  OrderPostSummary post,  OrderParty customer,  OrderParty designer,  OrderStatus status,  OrderSnapshot snapshot,  List<OrderEvent> events,  DateTime createdAt,  OrderRole viewerRole,  String notes,  int? budgetCents,  int? quoteCents,  String currency,  DateTime? dueAt,  String? tracking,  DeclineReason? declineReason,  String? declineNote,  OrderDispute? dispute,  DeliveryAddress? delivery,  OrderPayment? payment)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.orderNumber,_that.post,_that.customer,_that.designer,_that.status,_that.snapshot,_that.events,_that.createdAt,_that.viewerRole,_that.notes,_that.budgetCents,_that.quoteCents,_that.currency,_that.dueAt,_that.tracking,_that.declineReason,_that.declineNote,_that.dispute,_that.delivery,_that.payment);case _:
  return null;

}
}

}

/// @nodoc


class _Order extends Order {
  const _Order({required this.id, required this.orderNumber, required this.post, required this.customer, required this.designer, required this.status, required this.snapshot, required final  List<OrderEvent> events, required this.createdAt, required this.viewerRole, this.notes = '', this.budgetCents, this.quoteCents, this.currency = 'NGN', this.dueAt, this.tracking, this.declineReason, this.declineNote, this.dispute, this.delivery, this.payment}): _events = events,super._();
  

@override final  String id;
@override final  String orderNumber;
@override final  OrderPostSummary post;
@override final  OrderParty customer;
@override final  OrderParty designer;
@override final  OrderStatus status;
@override final  OrderSnapshot snapshot;
 final  List<OrderEvent> _events;
@override List<OrderEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override final  DateTime createdAt;
/// The signed-in viewer's side (drives the C8 role tabs + actions).
@override final  OrderRole viewerRole;
@override@JsonKey() final  String notes;
@override final  int? budgetCents;
@override final  int? quoteCents;
@override@JsonKey() final  String currency;
@override final  DateTime? dueAt;
@override final  String? tracking;
@override final  DeclineReason? declineReason;
/// The optional note the designer attached when declining (D04 —
/// pages.md B3 "reason enum + optional note").
@override final  String? declineNote;
@override final  OrderDispute? dispute;
@override final  DeliveryAddress? delivery;
@override final  OrderPayment? payment;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.post, post) || other.post == post)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.designer, designer) || other.designer == designer)&&(identical(other.status, status) || other.status == status)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.viewerRole, viewerRole) || other.viewerRole == viewerRole)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.budgetCents, budgetCents) || other.budgetCents == budgetCents)&&(identical(other.quoteCents, quoteCents) || other.quoteCents == quoteCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.declineReason, declineReason) || other.declineReason == declineReason)&&(identical(other.declineNote, declineNote) || other.declineNote == declineNote)&&(identical(other.dispute, dispute) || other.dispute == dispute)&&(identical(other.delivery, delivery) || other.delivery == delivery)&&(identical(other.payment, payment) || other.payment == payment));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,orderNumber,post,customer,designer,status,snapshot,const DeepCollectionEquality().hash(_events),createdAt,viewerRole,notes,budgetCents,quoteCents,currency,dueAt,tracking,declineReason,declineNote,dispute,delivery,payment]);

@override
String toString() {
  return 'Order(id: $id, orderNumber: $orderNumber, post: $post, customer: $customer, designer: $designer, status: $status, snapshot: $snapshot, events: $events, createdAt: $createdAt, viewerRole: $viewerRole, notes: $notes, budgetCents: $budgetCents, quoteCents: $quoteCents, currency: $currency, dueAt: $dueAt, tracking: $tracking, declineReason: $declineReason, declineNote: $declineNote, dispute: $dispute, delivery: $delivery, payment: $payment)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderNumber, OrderPostSummary post, OrderParty customer, OrderParty designer, OrderStatus status, OrderSnapshot snapshot, List<OrderEvent> events, DateTime createdAt, OrderRole viewerRole, String notes, int? budgetCents, int? quoteCents, String currency, DateTime? dueAt, String? tracking, DeclineReason? declineReason, String? declineNote, OrderDispute? dispute, DeliveryAddress? delivery, OrderPayment? payment
});


@override $OrderPostSummaryCopyWith<$Res> get post;@override $OrderPartyCopyWith<$Res> get customer;@override $OrderPartyCopyWith<$Res> get designer;@override $OrderSnapshotCopyWith<$Res> get snapshot;@override $OrderDisputeCopyWith<$Res>? get dispute;@override $DeliveryAddressCopyWith<$Res>? get delivery;@override $OrderPaymentCopyWith<$Res>? get payment;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderNumber = null,Object? post = null,Object? customer = null,Object? designer = null,Object? status = null,Object? snapshot = null,Object? events = null,Object? createdAt = null,Object? viewerRole = null,Object? notes = null,Object? budgetCents = freezed,Object? quoteCents = freezed,Object? currency = null,Object? dueAt = freezed,Object? tracking = freezed,Object? declineReason = freezed,Object? declineNote = freezed,Object? dispute = freezed,Object? delivery = freezed,Object? payment = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String,post: null == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as OrderPostSummary,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as OrderParty,designer: null == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as OrderParty,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as OrderSnapshot,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<OrderEvent>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,viewerRole: null == viewerRole ? _self.viewerRole : viewerRole // ignore: cast_nullable_to_non_nullable
as OrderRole,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,budgetCents: freezed == budgetCents ? _self.budgetCents : budgetCents // ignore: cast_nullable_to_non_nullable
as int?,quoteCents: freezed == quoteCents ? _self.quoteCents : quoteCents // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tracking: freezed == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as String?,declineReason: freezed == declineReason ? _self.declineReason : declineReason // ignore: cast_nullable_to_non_nullable
as DeclineReason?,declineNote: freezed == declineNote ? _self.declineNote : declineNote // ignore: cast_nullable_to_non_nullable
as String?,dispute: freezed == dispute ? _self.dispute : dispute // ignore: cast_nullable_to_non_nullable
as OrderDispute?,delivery: freezed == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as OrderPayment?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPostSummaryCopyWith<$Res> get post {
  
  return $OrderPostSummaryCopyWith<$Res>(_self.post, (value) {
    return _then(_self.copyWith(post: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPartyCopyWith<$Res> get customer {
  
  return $OrderPartyCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPartyCopyWith<$Res> get designer {
  
  return $OrderPartyCopyWith<$Res>(_self.designer, (value) {
    return _then(_self.copyWith(designer: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderSnapshotCopyWith<$Res> get snapshot {
  
  return $OrderSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderDisputeCopyWith<$Res>? get dispute {
    if (_self.dispute == null) {
    return null;
  }

  return $OrderDisputeCopyWith<$Res>(_self.dispute!, (value) {
    return _then(_self.copyWith(dispute: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get delivery {
    if (_self.delivery == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.delivery!, (value) {
    return _then(_self.copyWith(delivery: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<$Res>? get payment {
    if (_self.payment == null) {
    return null;
  }

  return $OrderPaymentCopyWith<$Res>(_self.payment!, (value) {
    return _then(_self.copyWith(payment: value));
  });
}
}

// dart format on
