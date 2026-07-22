// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PayoutAccount {

 String get providerRef; String get bankCode; String get bankName; String get accountLast4; String get accountName; KycState get kycState;
/// Create a copy of PayoutAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutAccountCopyWith<PayoutAccount> get copyWith => _$PayoutAccountCopyWithImpl<PayoutAccount>(this as PayoutAccount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayoutAccount&&(identical(other.providerRef, providerRef) || other.providerRef == providerRef)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.kycState, kycState) || other.kycState == kycState));
}


@override
int get hashCode => Object.hash(runtimeType,providerRef,bankCode,bankName,accountLast4,accountName,kycState);

@override
String toString() {
  return 'PayoutAccount(providerRef: $providerRef, bankCode: $bankCode, bankName: $bankName, accountLast4: $accountLast4, accountName: $accountName, kycState: $kycState)';
}


}

/// @nodoc
abstract mixin class $PayoutAccountCopyWith<$Res>  {
  factory $PayoutAccountCopyWith(PayoutAccount value, $Res Function(PayoutAccount) _then) = _$PayoutAccountCopyWithImpl;
@useResult
$Res call({
 String providerRef, String bankCode, String bankName, String accountLast4, String accountName, KycState kycState
});




}
/// @nodoc
class _$PayoutAccountCopyWithImpl<$Res>
    implements $PayoutAccountCopyWith<$Res> {
  _$PayoutAccountCopyWithImpl(this._self, this._then);

  final PayoutAccount _self;
  final $Res Function(PayoutAccount) _then;

/// Create a copy of PayoutAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerRef = null,Object? bankCode = null,Object? bankName = null,Object? accountLast4 = null,Object? accountName = null,Object? kycState = null,}) {
  return _then(_self.copyWith(
providerRef: null == providerRef ? _self.providerRef : providerRef // ignore: cast_nullable_to_non_nullable
as String,bankCode: null == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountLast4: null == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,kycState: null == kycState ? _self.kycState : kycState // ignore: cast_nullable_to_non_nullable
as KycState,
  ));
}

}


/// Adds pattern-matching-related methods to [PayoutAccount].
extension PayoutAccountPatterns on PayoutAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayoutAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayoutAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayoutAccount value)  $default,){
final _that = this;
switch (_that) {
case _PayoutAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayoutAccount value)?  $default,){
final _that = this;
switch (_that) {
case _PayoutAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerRef,  String bankCode,  String bankName,  String accountLast4,  String accountName,  KycState kycState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayoutAccount() when $default != null:
return $default(_that.providerRef,_that.bankCode,_that.bankName,_that.accountLast4,_that.accountName,_that.kycState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerRef,  String bankCode,  String bankName,  String accountLast4,  String accountName,  KycState kycState)  $default,) {final _that = this;
switch (_that) {
case _PayoutAccount():
return $default(_that.providerRef,_that.bankCode,_that.bankName,_that.accountLast4,_that.accountName,_that.kycState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerRef,  String bankCode,  String bankName,  String accountLast4,  String accountName,  KycState kycState)?  $default,) {final _that = this;
switch (_that) {
case _PayoutAccount() when $default != null:
return $default(_that.providerRef,_that.bankCode,_that.bankName,_that.accountLast4,_that.accountName,_that.kycState);case _:
  return null;

}
}

}

/// @nodoc


class _PayoutAccount implements PayoutAccount {
  const _PayoutAccount({required this.providerRef, required this.bankCode, required this.bankName, required this.accountLast4, required this.accountName, required this.kycState});
  

@override final  String providerRef;
@override final  String bankCode;
@override final  String bankName;
@override final  String accountLast4;
@override final  String accountName;
@override final  KycState kycState;

/// Create a copy of PayoutAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutAccountCopyWith<_PayoutAccount> get copyWith => __$PayoutAccountCopyWithImpl<_PayoutAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayoutAccount&&(identical(other.providerRef, providerRef) || other.providerRef == providerRef)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.kycState, kycState) || other.kycState == kycState));
}


@override
int get hashCode => Object.hash(runtimeType,providerRef,bankCode,bankName,accountLast4,accountName,kycState);

@override
String toString() {
  return 'PayoutAccount(providerRef: $providerRef, bankCode: $bankCode, bankName: $bankName, accountLast4: $accountLast4, accountName: $accountName, kycState: $kycState)';
}


}

/// @nodoc
abstract mixin class _$PayoutAccountCopyWith<$Res> implements $PayoutAccountCopyWith<$Res> {
  factory _$PayoutAccountCopyWith(_PayoutAccount value, $Res Function(_PayoutAccount) _then) = __$PayoutAccountCopyWithImpl;
@override @useResult
$Res call({
 String providerRef, String bankCode, String bankName, String accountLast4, String accountName, KycState kycState
});




}
/// @nodoc
class __$PayoutAccountCopyWithImpl<$Res>
    implements _$PayoutAccountCopyWith<$Res> {
  __$PayoutAccountCopyWithImpl(this._self, this._then);

  final _PayoutAccount _self;
  final $Res Function(_PayoutAccount) _then;

/// Create a copy of PayoutAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerRef = null,Object? bankCode = null,Object? bankName = null,Object? accountLast4 = null,Object? accountName = null,Object? kycState = null,}) {
  return _then(_PayoutAccount(
providerRef: null == providerRef ? _self.providerRef : providerRef // ignore: cast_nullable_to_non_nullable
as String,bankCode: null == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountLast4: null == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,kycState: null == kycState ? _self.kycState : kycState // ignore: cast_nullable_to_non_nullable
as KycState,
  ));
}


}

/// @nodoc
mixin _$DesignerStatus {

 bool get enabled; String? get username; String? get displayName; String? get bio; PayoutAccount? get payoutAccount;
/// Create a copy of DesignerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignerStatusCopyWith<DesignerStatus> get copyWith => _$DesignerStatusCopyWithImpl<DesignerStatus>(this as DesignerStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignerStatus&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.payoutAccount, payoutAccount) || other.payoutAccount == payoutAccount));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,username,displayName,bio,payoutAccount);

@override
String toString() {
  return 'DesignerStatus(enabled: $enabled, username: $username, displayName: $displayName, bio: $bio, payoutAccount: $payoutAccount)';
}


}

/// @nodoc
abstract mixin class $DesignerStatusCopyWith<$Res>  {
  factory $DesignerStatusCopyWith(DesignerStatus value, $Res Function(DesignerStatus) _then) = _$DesignerStatusCopyWithImpl;
@useResult
$Res call({
 bool enabled, String? username, String? displayName, String? bio, PayoutAccount? payoutAccount
});


$PayoutAccountCopyWith<$Res>? get payoutAccount;

}
/// @nodoc
class _$DesignerStatusCopyWithImpl<$Res>
    implements $DesignerStatusCopyWith<$Res> {
  _$DesignerStatusCopyWithImpl(this._self, this._then);

  final DesignerStatus _self;
  final $Res Function(DesignerStatus) _then;

/// Create a copy of DesignerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? username = freezed,Object? displayName = freezed,Object? bio = freezed,Object? payoutAccount = freezed,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,payoutAccount: freezed == payoutAccount ? _self.payoutAccount : payoutAccount // ignore: cast_nullable_to_non_nullable
as PayoutAccount?,
  ));
}
/// Create a copy of DesignerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayoutAccountCopyWith<$Res>? get payoutAccount {
    if (_self.payoutAccount == null) {
    return null;
  }

  return $PayoutAccountCopyWith<$Res>(_self.payoutAccount!, (value) {
    return _then(_self.copyWith(payoutAccount: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignerStatus].
extension DesignerStatusPatterns on DesignerStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignerStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignerStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignerStatus value)  $default,){
final _that = this;
switch (_that) {
case _DesignerStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignerStatus value)?  $default,){
final _that = this;
switch (_that) {
case _DesignerStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String? username,  String? displayName,  String? bio,  PayoutAccount? payoutAccount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignerStatus() when $default != null:
return $default(_that.enabled,_that.username,_that.displayName,_that.bio,_that.payoutAccount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String? username,  String? displayName,  String? bio,  PayoutAccount? payoutAccount)  $default,) {final _that = this;
switch (_that) {
case _DesignerStatus():
return $default(_that.enabled,_that.username,_that.displayName,_that.bio,_that.payoutAccount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String? username,  String? displayName,  String? bio,  PayoutAccount? payoutAccount)?  $default,) {final _that = this;
switch (_that) {
case _DesignerStatus() when $default != null:
return $default(_that.enabled,_that.username,_that.displayName,_that.bio,_that.payoutAccount);case _:
  return null;

}
}

}

/// @nodoc


class _DesignerStatus implements DesignerStatus {
  const _DesignerStatus({this.enabled = false, this.username, this.displayName, this.bio, this.payoutAccount});
  

@override@JsonKey() final  bool enabled;
@override final  String? username;
@override final  String? displayName;
@override final  String? bio;
@override final  PayoutAccount? payoutAccount;

/// Create a copy of DesignerStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignerStatusCopyWith<_DesignerStatus> get copyWith => __$DesignerStatusCopyWithImpl<_DesignerStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignerStatus&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.payoutAccount, payoutAccount) || other.payoutAccount == payoutAccount));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,username,displayName,bio,payoutAccount);

@override
String toString() {
  return 'DesignerStatus(enabled: $enabled, username: $username, displayName: $displayName, bio: $bio, payoutAccount: $payoutAccount)';
}


}

/// @nodoc
abstract mixin class _$DesignerStatusCopyWith<$Res> implements $DesignerStatusCopyWith<$Res> {
  factory _$DesignerStatusCopyWith(_DesignerStatus value, $Res Function(_DesignerStatus) _then) = __$DesignerStatusCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String? username, String? displayName, String? bio, PayoutAccount? payoutAccount
});


@override $PayoutAccountCopyWith<$Res>? get payoutAccount;

}
/// @nodoc
class __$DesignerStatusCopyWithImpl<$Res>
    implements _$DesignerStatusCopyWith<$Res> {
  __$DesignerStatusCopyWithImpl(this._self, this._then);

  final _DesignerStatus _self;
  final $Res Function(_DesignerStatus) _then;

/// Create a copy of DesignerStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? username = freezed,Object? displayName = freezed,Object? bio = freezed,Object? payoutAccount = freezed,}) {
  return _then(_DesignerStatus(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,payoutAccount: freezed == payoutAccount ? _self.payoutAccount : payoutAccount // ignore: cast_nullable_to_non_nullable
as PayoutAccount?,
  ));
}

/// Create a copy of DesignerStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayoutAccountCopyWith<$Res>? get payoutAccount {
    if (_self.payoutAccount == null) {
    return null;
  }

  return $PayoutAccountCopyWith<$Res>(_self.payoutAccount!, (value) {
    return _then(_self.copyWith(payoutAccount: value));
  });
}
}

/// @nodoc
mixin _$BankResolution {

 String get accountName; String get bankCode; String get accountNumber;
/// Create a copy of BankResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankResolutionCopyWith<BankResolution> get copyWith => _$BankResolutionCopyWithImpl<BankResolution>(this as BankResolution, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankResolution&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber));
}


@override
int get hashCode => Object.hash(runtimeType,accountName,bankCode,accountNumber);

@override
String toString() {
  return 'BankResolution(accountName: $accountName, bankCode: $bankCode, accountNumber: $accountNumber)';
}


}

/// @nodoc
abstract mixin class $BankResolutionCopyWith<$Res>  {
  factory $BankResolutionCopyWith(BankResolution value, $Res Function(BankResolution) _then) = _$BankResolutionCopyWithImpl;
@useResult
$Res call({
 String accountName, String bankCode, String accountNumber
});




}
/// @nodoc
class _$BankResolutionCopyWithImpl<$Res>
    implements $BankResolutionCopyWith<$Res> {
  _$BankResolutionCopyWithImpl(this._self, this._then);

  final BankResolution _self;
  final $Res Function(BankResolution) _then;

/// Create a copy of BankResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountName = null,Object? bankCode = null,Object? accountNumber = null,}) {
  return _then(_self.copyWith(
accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,bankCode: null == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BankResolution].
extension BankResolutionPatterns on BankResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankResolution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankResolution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankResolution value)  $default,){
final _that = this;
switch (_that) {
case _BankResolution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankResolution value)?  $default,){
final _that = this;
switch (_that) {
case _BankResolution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountName,  String bankCode,  String accountNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankResolution() when $default != null:
return $default(_that.accountName,_that.bankCode,_that.accountNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountName,  String bankCode,  String accountNumber)  $default,) {final _that = this;
switch (_that) {
case _BankResolution():
return $default(_that.accountName,_that.bankCode,_that.accountNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountName,  String bankCode,  String accountNumber)?  $default,) {final _that = this;
switch (_that) {
case _BankResolution() when $default != null:
return $default(_that.accountName,_that.bankCode,_that.accountNumber);case _:
  return null;

}
}

}

/// @nodoc


class _BankResolution implements BankResolution {
  const _BankResolution({required this.accountName, required this.bankCode, required this.accountNumber});
  

@override final  String accountName;
@override final  String bankCode;
@override final  String accountNumber;

/// Create a copy of BankResolution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankResolutionCopyWith<_BankResolution> get copyWith => __$BankResolutionCopyWithImpl<_BankResolution>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankResolution&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber));
}


@override
int get hashCode => Object.hash(runtimeType,accountName,bankCode,accountNumber);

@override
String toString() {
  return 'BankResolution(accountName: $accountName, bankCode: $bankCode, accountNumber: $accountNumber)';
}


}

/// @nodoc
abstract mixin class _$BankResolutionCopyWith<$Res> implements $BankResolutionCopyWith<$Res> {
  factory _$BankResolutionCopyWith(_BankResolution value, $Res Function(_BankResolution) _then) = __$BankResolutionCopyWithImpl;
@override @useResult
$Res call({
 String accountName, String bankCode, String accountNumber
});




}
/// @nodoc
class __$BankResolutionCopyWithImpl<$Res>
    implements _$BankResolutionCopyWith<$Res> {
  __$BankResolutionCopyWithImpl(this._self, this._then);

  final _BankResolution _self;
  final $Res Function(_BankResolution) _then;

/// Create a copy of BankResolution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountName = null,Object? bankCode = null,Object? accountNumber = null,}) {
  return _then(_BankResolution(
accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,bankCode: null == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BankOption {

 String get code; String get name;
/// Create a copy of BankOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankOptionCopyWith<BankOption> get copyWith => _$BankOptionCopyWithImpl<BankOption>(this as BankOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankOption&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'BankOption(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $BankOptionCopyWith<$Res>  {
  factory $BankOptionCopyWith(BankOption value, $Res Function(BankOption) _then) = _$BankOptionCopyWithImpl;
@useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class _$BankOptionCopyWithImpl<$Res>
    implements $BankOptionCopyWith<$Res> {
  _$BankOptionCopyWithImpl(this._self, this._then);

  final BankOption _self;
  final $Res Function(BankOption) _then;

/// Create a copy of BankOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BankOption].
extension BankOptionPatterns on BankOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankOption value)  $default,){
final _that = this;
switch (_that) {
case _BankOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankOption value)?  $default,){
final _that = this;
switch (_that) {
case _BankOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankOption() when $default != null:
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _BankOption():
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _BankOption() when $default != null:
return $default(_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _BankOption implements BankOption {
  const _BankOption({required this.code, required this.name});
  

@override final  String code;
@override final  String name;

/// Create a copy of BankOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankOptionCopyWith<_BankOption> get copyWith => __$BankOptionCopyWithImpl<_BankOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankOption&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'BankOption(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$BankOptionCopyWith<$Res> implements $BankOptionCopyWith<$Res> {
  factory _$BankOptionCopyWith(_BankOption value, $Res Function(_BankOption) _then) = __$BankOptionCopyWithImpl;
@override @useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class __$BankOptionCopyWithImpl<$Res>
    implements _$BankOptionCopyWith<$Res> {
  __$BankOptionCopyWithImpl(this._self, this._then);

  final _BankOption _self;
  final $Res Function(_BankOption) _then;

/// Create a copy of BankOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = null,}) {
  return _then(_BankOption(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
