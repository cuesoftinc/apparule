// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_results.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExploreResults {

 List<Post> get posts;/// Non-empty only for query searches (the Designers section).
 List<DesignerSummary> get designers;
/// Create a copy of ExploreResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreResultsCopyWith<ExploreResults> get copyWith => _$ExploreResultsCopyWithImpl<ExploreResults>(this as ExploreResults, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreResults&&const DeepCollectionEquality().equals(other.posts, posts)&&const DeepCollectionEquality().equals(other.designers, designers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(posts),const DeepCollectionEquality().hash(designers));

@override
String toString() {
  return 'ExploreResults(posts: $posts, designers: $designers)';
}


}

/// @nodoc
abstract mixin class $ExploreResultsCopyWith<$Res>  {
  factory $ExploreResultsCopyWith(ExploreResults value, $Res Function(ExploreResults) _then) = _$ExploreResultsCopyWithImpl;
@useResult
$Res call({
 List<Post> posts, List<DesignerSummary> designers
});




}
/// @nodoc
class _$ExploreResultsCopyWithImpl<$Res>
    implements $ExploreResultsCopyWith<$Res> {
  _$ExploreResultsCopyWithImpl(this._self, this._then);

  final ExploreResults _self;
  final $Res Function(ExploreResults) _then;

/// Create a copy of ExploreResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? posts = null,Object? designers = null,}) {
  return _then(_self.copyWith(
posts: null == posts ? _self.posts : posts // ignore: cast_nullable_to_non_nullable
as List<Post>,designers: null == designers ? _self.designers : designers // ignore: cast_nullable_to_non_nullable
as List<DesignerSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExploreResults].
extension ExploreResultsPatterns on ExploreResults {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreResults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreResults() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreResults value)  $default,){
final _that = this;
switch (_that) {
case _ExploreResults():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreResults value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreResults() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Post> posts,  List<DesignerSummary> designers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreResults() when $default != null:
return $default(_that.posts,_that.designers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Post> posts,  List<DesignerSummary> designers)  $default,) {final _that = this;
switch (_that) {
case _ExploreResults():
return $default(_that.posts,_that.designers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Post> posts,  List<DesignerSummary> designers)?  $default,) {final _that = this;
switch (_that) {
case _ExploreResults() when $default != null:
return $default(_that.posts,_that.designers);case _:
  return null;

}
}

}

/// @nodoc


class _ExploreResults implements ExploreResults {
  const _ExploreResults({required final  List<Post> posts, final  List<DesignerSummary> designers = const <DesignerSummary>[]}): _posts = posts,_designers = designers;
  

 final  List<Post> _posts;
@override List<Post> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}

/// Non-empty only for query searches (the Designers section).
 final  List<DesignerSummary> _designers;
/// Non-empty only for query searches (the Designers section).
@override@JsonKey() List<DesignerSummary> get designers {
  if (_designers is EqualUnmodifiableListView) return _designers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designers);
}


/// Create a copy of ExploreResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreResultsCopyWith<_ExploreResults> get copyWith => __$ExploreResultsCopyWithImpl<_ExploreResults>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreResults&&const DeepCollectionEquality().equals(other._posts, _posts)&&const DeepCollectionEquality().equals(other._designers, _designers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts),const DeepCollectionEquality().hash(_designers));

@override
String toString() {
  return 'ExploreResults(posts: $posts, designers: $designers)';
}


}

/// @nodoc
abstract mixin class _$ExploreResultsCopyWith<$Res> implements $ExploreResultsCopyWith<$Res> {
  factory _$ExploreResultsCopyWith(_ExploreResults value, $Res Function(_ExploreResults) _then) = __$ExploreResultsCopyWithImpl;
@override @useResult
$Res call({
 List<Post> posts, List<DesignerSummary> designers
});




}
/// @nodoc
class __$ExploreResultsCopyWithImpl<$Res>
    implements _$ExploreResultsCopyWith<$Res> {
  __$ExploreResultsCopyWithImpl(this._self, this._then);

  final _ExploreResults _self;
  final $Res Function(_ExploreResults) _then;

/// Create a copy of ExploreResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? posts = null,Object? designers = null,}) {
  return _then(_ExploreResults(
posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<Post>,designers: null == designers ? _self._designers : designers // ignore: cast_nullable_to_non_nullable
as List<DesignerSummary>,
  ));
}


}

// dart format on
