// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payout_account_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PayoutFormState {

 List<BankOption> get banks; BankOption? get bank; String get accountNumber; PayoutFormPhase get phase; BankResolution? get resolution; int get failCount; bool get saving;
/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutFormStateCopyWith<PayoutFormState> get copyWith => _$PayoutFormStateCopyWithImpl<PayoutFormState>(this as PayoutFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayoutFormState&&const DeepCollectionEquality().equals(other.banks, banks)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.failCount, failCount) || other.failCount == failCount)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(banks),bank,accountNumber,phase,resolution,failCount,saving);

@override
String toString() {
  return 'PayoutFormState(banks: $banks, bank: $bank, accountNumber: $accountNumber, phase: $phase, resolution: $resolution, failCount: $failCount, saving: $saving)';
}


}

/// @nodoc
abstract mixin class $PayoutFormStateCopyWith<$Res>  {
  factory $PayoutFormStateCopyWith(PayoutFormState value, $Res Function(PayoutFormState) _then) = _$PayoutFormStateCopyWithImpl;
@useResult
$Res call({
 List<BankOption> banks, BankOption? bank, String accountNumber, PayoutFormPhase phase, BankResolution? resolution, int failCount, bool saving
});


$BankOptionCopyWith<$Res>? get bank;$BankResolutionCopyWith<$Res>? get resolution;

}
/// @nodoc
class _$PayoutFormStateCopyWithImpl<$Res>
    implements $PayoutFormStateCopyWith<$Res> {
  _$PayoutFormStateCopyWithImpl(this._self, this._then);

  final PayoutFormState _self;
  final $Res Function(PayoutFormState) _then;

/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? banks = null,Object? bank = freezed,Object? accountNumber = null,Object? phase = null,Object? resolution = freezed,Object? failCount = null,Object? saving = null,}) {
  return _then(_self.copyWith(
banks: null == banks ? _self.banks : banks // ignore: cast_nullable_to_non_nullable
as List<BankOption>,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as BankOption?,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PayoutFormPhase,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as BankResolution?,failCount: null == failCount ? _self.failCount : failCount // ignore: cast_nullable_to_non_nullable
as int,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BankOptionCopyWith<$Res>? get bank {
    if (_self.bank == null) {
    return null;
  }

  return $BankOptionCopyWith<$Res>(_self.bank!, (value) {
    return _then(_self.copyWith(bank: value));
  });
}/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BankResolutionCopyWith<$Res>? get resolution {
    if (_self.resolution == null) {
    return null;
  }

  return $BankResolutionCopyWith<$Res>(_self.resolution!, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}
}


/// Adds pattern-matching-related methods to [PayoutFormState].
extension PayoutFormStatePatterns on PayoutFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayoutFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayoutFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayoutFormState value)  $default,){
final _that = this;
switch (_that) {
case _PayoutFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayoutFormState value)?  $default,){
final _that = this;
switch (_that) {
case _PayoutFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BankOption> banks,  BankOption? bank,  String accountNumber,  PayoutFormPhase phase,  BankResolution? resolution,  int failCount,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayoutFormState() when $default != null:
return $default(_that.banks,_that.bank,_that.accountNumber,_that.phase,_that.resolution,_that.failCount,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BankOption> banks,  BankOption? bank,  String accountNumber,  PayoutFormPhase phase,  BankResolution? resolution,  int failCount,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _PayoutFormState():
return $default(_that.banks,_that.bank,_that.accountNumber,_that.phase,_that.resolution,_that.failCount,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BankOption> banks,  BankOption? bank,  String accountNumber,  PayoutFormPhase phase,  BankResolution? resolution,  int failCount,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _PayoutFormState() when $default != null:
return $default(_that.banks,_that.bank,_that.accountNumber,_that.phase,_that.resolution,_that.failCount,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _PayoutFormState implements PayoutFormState {
  const _PayoutFormState({final  List<BankOption> banks = const <BankOption>[], this.bank, this.accountNumber = '', this.phase = PayoutFormPhase.idle, this.resolution, this.failCount = 0, this.saving = false}): _banks = banks;
  

 final  List<BankOption> _banks;
@override@JsonKey() List<BankOption> get banks {
  if (_banks is EqualUnmodifiableListView) return _banks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_banks);
}

@override final  BankOption? bank;
@override@JsonKey() final  String accountNumber;
@override@JsonKey() final  PayoutFormPhase phase;
@override final  BankResolution? resolution;
@override@JsonKey() final  int failCount;
@override@JsonKey() final  bool saving;

/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutFormStateCopyWith<_PayoutFormState> get copyWith => __$PayoutFormStateCopyWithImpl<_PayoutFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayoutFormState&&const DeepCollectionEquality().equals(other._banks, _banks)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.failCount, failCount) || other.failCount == failCount)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_banks),bank,accountNumber,phase,resolution,failCount,saving);

@override
String toString() {
  return 'PayoutFormState(banks: $banks, bank: $bank, accountNumber: $accountNumber, phase: $phase, resolution: $resolution, failCount: $failCount, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$PayoutFormStateCopyWith<$Res> implements $PayoutFormStateCopyWith<$Res> {
  factory _$PayoutFormStateCopyWith(_PayoutFormState value, $Res Function(_PayoutFormState) _then) = __$PayoutFormStateCopyWithImpl;
@override @useResult
$Res call({
 List<BankOption> banks, BankOption? bank, String accountNumber, PayoutFormPhase phase, BankResolution? resolution, int failCount, bool saving
});


@override $BankOptionCopyWith<$Res>? get bank;@override $BankResolutionCopyWith<$Res>? get resolution;

}
/// @nodoc
class __$PayoutFormStateCopyWithImpl<$Res>
    implements _$PayoutFormStateCopyWith<$Res> {
  __$PayoutFormStateCopyWithImpl(this._self, this._then);

  final _PayoutFormState _self;
  final $Res Function(_PayoutFormState) _then;

/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? banks = null,Object? bank = freezed,Object? accountNumber = null,Object? phase = null,Object? resolution = freezed,Object? failCount = null,Object? saving = null,}) {
  return _then(_PayoutFormState(
banks: null == banks ? _self._banks : banks // ignore: cast_nullable_to_non_nullable
as List<BankOption>,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as BankOption?,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PayoutFormPhase,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as BankResolution?,failCount: null == failCount ? _self.failCount : failCount // ignore: cast_nullable_to_non_nullable
as int,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BankOptionCopyWith<$Res>? get bank {
    if (_self.bank == null) {
    return null;
  }

  return $BankOptionCopyWith<$Res>(_self.bank!, (value) {
    return _then(_self.copyWith(bank: value));
  });
}/// Create a copy of PayoutFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BankResolutionCopyWith<$Res>? get resolution {
    if (_self.resolution == null) {
    return null;
  }

  return $BankResolutionCopyWith<$Res>(_self.resolution!, (value) {
    return _then(_self.copyWith(resolution: value));
  });
}
}

// dart format on
