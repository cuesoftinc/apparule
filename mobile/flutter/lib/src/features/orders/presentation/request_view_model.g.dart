// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C5's ViewModel — the one place three repositories meet (ViewModels
/// orchestrate; repositories never reference each other,
/// mobile-implementation.md §3). Submission freezes the picked vault
/// session's values into the order snapshot (order-lifecycle.md §1).

@ProviderFor(RequestViewModel)
final requestViewModelProvider = RequestViewModelFamily._();

/// C5's ViewModel — the one place three repositories meet (ViewModels
/// orchestrate; repositories never reference each other,
/// mobile-implementation.md §3). Submission freezes the picked vault
/// session's values into the order snapshot (order-lifecycle.md §1).
final class RequestViewModelProvider
    extends $AsyncNotifierProvider<RequestViewModel, RequestContext> {
  /// C5's ViewModel — the one place three repositories meet (ViewModels
  /// orchestrate; repositories never reference each other,
  /// mobile-implementation.md §3). Submission freezes the picked vault
  /// session's values into the order snapshot (order-lifecycle.md §1).
  RequestViewModelProvider._({
    required RequestViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'requestViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$requestViewModelHash();

  @override
  String toString() {
    return r'requestViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RequestViewModel create() => RequestViewModel();

  @override
  bool operator ==(Object other) {
    return other is RequestViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$requestViewModelHash() => r'29d8b5e023976c0f9f0b2169ddb009d95cc76138';

/// C5's ViewModel — the one place three repositories meet (ViewModels
/// orchestrate; repositories never reference each other,
/// mobile-implementation.md §3). Submission freezes the picked vault
/// session's values into the order snapshot (order-lifecycle.md §1).

final class RequestViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          RequestViewModel,
          AsyncValue<RequestContext>,
          RequestContext,
          FutureOr<RequestContext>,
          String
        > {
  RequestViewModelFamily._()
    : super(
        retry: null,
        name: r'requestViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C5's ViewModel — the one place three repositories meet (ViewModels
  /// orchestrate; repositories never reference each other,
  /// mobile-implementation.md §3). Submission freezes the picked vault
  /// session's values into the order snapshot (order-lifecycle.md §1).

  RequestViewModelProvider call(String postId) =>
      RequestViewModelProvider._(argument: postId, from: this);

  @override
  String toString() => r'requestViewModelProvider';
}

/// C5's ViewModel — the one place three repositories meet (ViewModels
/// orchestrate; repositories never reference each other,
/// mobile-implementation.md §3). Submission freezes the picked vault
/// session's values into the order snapshot (order-lifecycle.md §1).

abstract class _$RequestViewModel extends $AsyncNotifier<RequestContext> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<RequestContext> build(String postId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RequestContext>, RequestContext>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RequestContext>, RequestContext>,
              AsyncValue<RequestContext>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
