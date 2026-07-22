// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earnings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EarningsEntry {

 String get id; EarningsEntryKind get kind; int get amountCents; DateTime get createdAt; String get currency; String? get label; String? get orderNumber; String? get providerRef; bool get held;
/// Create a copy of EarningsEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsEntryCopyWith<EarningsEntry> get copyWith => _$EarningsEntryCopyWithImpl<EarningsEntry>(this as EarningsEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningsEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.label, label) || other.label == label)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.providerRef, providerRef) || other.providerRef == providerRef)&&(identical(other.held, held) || other.held == held));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,amountCents,createdAt,currency,label,orderNumber,providerRef,held);

@override
String toString() {
  return 'EarningsEntry(id: $id, kind: $kind, amountCents: $amountCents, createdAt: $createdAt, currency: $currency, label: $label, orderNumber: $orderNumber, providerRef: $providerRef, held: $held)';
}


}

/// @nodoc
abstract mixin class $EarningsEntryCopyWith<$Res>  {
  factory $EarningsEntryCopyWith(EarningsEntry value, $Res Function(EarningsEntry) _then) = _$EarningsEntryCopyWithImpl;
@useResult
$Res call({
 String id, EarningsEntryKind kind, int amountCents, DateTime createdAt, String currency, String? label, String? orderNumber, String? providerRef, bool held
});




}
/// @nodoc
class _$EarningsEntryCopyWithImpl<$Res>
    implements $EarningsEntryCopyWith<$Res> {
  _$EarningsEntryCopyWithImpl(this._self, this._then);

  final EarningsEntry _self;
  final $Res Function(EarningsEntry) _then;

/// Create a copy of EarningsEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? amountCents = null,Object? createdAt = null,Object? currency = null,Object? label = freezed,Object? orderNumber = freezed,Object? providerRef = freezed,Object? held = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EarningsEntryKind,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,orderNumber: freezed == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String?,providerRef: freezed == providerRef ? _self.providerRef : providerRef // ignore: cast_nullable_to_non_nullable
as String?,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EarningsEntry].
extension EarningsEntryPatterns on EarningsEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarningsEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarningsEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarningsEntry value)  $default,){
final _that = this;
switch (_that) {
case _EarningsEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarningsEntry value)?  $default,){
final _that = this;
switch (_that) {
case _EarningsEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EarningsEntryKind kind,  int amountCents,  DateTime createdAt,  String currency,  String? label,  String? orderNumber,  String? providerRef,  bool held)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningsEntry() when $default != null:
return $default(_that.id,_that.kind,_that.amountCents,_that.createdAt,_that.currency,_that.label,_that.orderNumber,_that.providerRef,_that.held);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EarningsEntryKind kind,  int amountCents,  DateTime createdAt,  String currency,  String? label,  String? orderNumber,  String? providerRef,  bool held)  $default,) {final _that = this;
switch (_that) {
case _EarningsEntry():
return $default(_that.id,_that.kind,_that.amountCents,_that.createdAt,_that.currency,_that.label,_that.orderNumber,_that.providerRef,_that.held);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EarningsEntryKind kind,  int amountCents,  DateTime createdAt,  String currency,  String? label,  String? orderNumber,  String? providerRef,  bool held)?  $default,) {final _that = this;
switch (_that) {
case _EarningsEntry() when $default != null:
return $default(_that.id,_that.kind,_that.amountCents,_that.createdAt,_that.currency,_that.label,_that.orderNumber,_that.providerRef,_that.held);case _:
  return null;

}
}

}

/// @nodoc


class _EarningsEntry implements EarningsEntry {
  const _EarningsEntry({required this.id, required this.kind, required this.amountCents, required this.createdAt, this.currency = 'NGN', this.label, this.orderNumber, this.providerRef, this.held = false});
  

@override final  String id;
@override final  EarningsEntryKind kind;
@override final  int amountCents;
@override final  DateTime createdAt;
@override@JsonKey() final  String currency;
@override final  String? label;
@override final  String? orderNumber;
@override final  String? providerRef;
@override@JsonKey() final  bool held;

/// Create a copy of EarningsEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsEntryCopyWith<_EarningsEntry> get copyWith => __$EarningsEntryCopyWithImpl<_EarningsEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningsEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.label, label) || other.label == label)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.providerRef, providerRef) || other.providerRef == providerRef)&&(identical(other.held, held) || other.held == held));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,amountCents,createdAt,currency,label,orderNumber,providerRef,held);

@override
String toString() {
  return 'EarningsEntry(id: $id, kind: $kind, amountCents: $amountCents, createdAt: $createdAt, currency: $currency, label: $label, orderNumber: $orderNumber, providerRef: $providerRef, held: $held)';
}


}

/// @nodoc
abstract mixin class _$EarningsEntryCopyWith<$Res> implements $EarningsEntryCopyWith<$Res> {
  factory _$EarningsEntryCopyWith(_EarningsEntry value, $Res Function(_EarningsEntry) _then) = __$EarningsEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, EarningsEntryKind kind, int amountCents, DateTime createdAt, String currency, String? label, String? orderNumber, String? providerRef, bool held
});




}
/// @nodoc
class __$EarningsEntryCopyWithImpl<$Res>
    implements _$EarningsEntryCopyWith<$Res> {
  __$EarningsEntryCopyWithImpl(this._self, this._then);

  final _EarningsEntry _self;
  final $Res Function(_EarningsEntry) _then;

/// Create a copy of EarningsEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? amountCents = null,Object? createdAt = null,Object? currency = null,Object? label = freezed,Object? orderNumber = freezed,Object? providerRef = freezed,Object? held = null,}) {
  return _then(_EarningsEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EarningsEntryKind,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,orderNumber: freezed == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String?,providerRef: freezed == providerRef ? _self.providerRef : providerRef // ignore: cast_nullable_to_non_nullable
as String?,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Earnings {

 int get availableCents; int get pendingCents; String get currency; List<EarningsEntry> get transactions;
/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsCopyWith<Earnings> get copyWith => _$EarningsCopyWithImpl<Earnings>(this as Earnings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Earnings&&(identical(other.availableCents, availableCents) || other.availableCents == availableCents)&&(identical(other.pendingCents, pendingCents) || other.pendingCents == pendingCents)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.transactions, transactions));
}


@override
int get hashCode => Object.hash(runtimeType,availableCents,pendingCents,currency,const DeepCollectionEquality().hash(transactions));

@override
String toString() {
  return 'Earnings(availableCents: $availableCents, pendingCents: $pendingCents, currency: $currency, transactions: $transactions)';
}


}

/// @nodoc
abstract mixin class $EarningsCopyWith<$Res>  {
  factory $EarningsCopyWith(Earnings value, $Res Function(Earnings) _then) = _$EarningsCopyWithImpl;
@useResult
$Res call({
 int availableCents, int pendingCents, String currency, List<EarningsEntry> transactions
});




}
/// @nodoc
class _$EarningsCopyWithImpl<$Res>
    implements $EarningsCopyWith<$Res> {
  _$EarningsCopyWithImpl(this._self, this._then);

  final Earnings _self;
  final $Res Function(Earnings) _then;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? availableCents = null,Object? pendingCents = null,Object? currency = null,Object? transactions = null,}) {
  return _then(_self.copyWith(
availableCents: null == availableCents ? _self.availableCents : availableCents // ignore: cast_nullable_to_non_nullable
as int,pendingCents: null == pendingCents ? _self.pendingCents : pendingCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<EarningsEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [Earnings].
extension EarningsPatterns on Earnings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Earnings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Earnings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Earnings value)  $default,){
final _that = this;
switch (_that) {
case _Earnings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Earnings value)?  $default,){
final _that = this;
switch (_that) {
case _Earnings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int availableCents,  int pendingCents,  String currency,  List<EarningsEntry> transactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that.availableCents,_that.pendingCents,_that.currency,_that.transactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int availableCents,  int pendingCents,  String currency,  List<EarningsEntry> transactions)  $default,) {final _that = this;
switch (_that) {
case _Earnings():
return $default(_that.availableCents,_that.pendingCents,_that.currency,_that.transactions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int availableCents,  int pendingCents,  String currency,  List<EarningsEntry> transactions)?  $default,) {final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that.availableCents,_that.pendingCents,_that.currency,_that.transactions);case _:
  return null;

}
}

}

/// @nodoc


class _Earnings implements Earnings {
  const _Earnings({required this.availableCents, required this.pendingCents, this.currency = 'NGN', final  List<EarningsEntry> transactions = const <EarningsEntry>[]}): _transactions = transactions;
  

@override final  int availableCents;
@override final  int pendingCents;
@override@JsonKey() final  String currency;
 final  List<EarningsEntry> _transactions;
@override@JsonKey() List<EarningsEntry> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}


/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsCopyWith<_Earnings> get copyWith => __$EarningsCopyWithImpl<_Earnings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Earnings&&(identical(other.availableCents, availableCents) || other.availableCents == availableCents)&&(identical(other.pendingCents, pendingCents) || other.pendingCents == pendingCents)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._transactions, _transactions));
}


@override
int get hashCode => Object.hash(runtimeType,availableCents,pendingCents,currency,const DeepCollectionEquality().hash(_transactions));

@override
String toString() {
  return 'Earnings(availableCents: $availableCents, pendingCents: $pendingCents, currency: $currency, transactions: $transactions)';
}


}

/// @nodoc
abstract mixin class _$EarningsCopyWith<$Res> implements $EarningsCopyWith<$Res> {
  factory _$EarningsCopyWith(_Earnings value, $Res Function(_Earnings) _then) = __$EarningsCopyWithImpl;
@override @useResult
$Res call({
 int availableCents, int pendingCents, String currency, List<EarningsEntry> transactions
});




}
/// @nodoc
class __$EarningsCopyWithImpl<$Res>
    implements _$EarningsCopyWith<$Res> {
  __$EarningsCopyWithImpl(this._self, this._then);

  final _Earnings _self;
  final $Res Function(_Earnings) _then;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? availableCents = null,Object? pendingCents = null,Object? currency = null,Object? transactions = null,}) {
  return _then(_Earnings(
availableCents: null == availableCents ? _self.availableCents : availableCents // ignore: cast_nullable_to_non_nullable
as int,pendingCents: null == pendingCents ? _self.pendingCents : pendingCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<EarningsEntry>,
  ));
}


}

// dart format on
