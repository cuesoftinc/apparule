// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composer_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C15's orchestration point — the one place the composer meets the
/// measurement and profile repositories (ViewModels orchestrate;
/// repositories never reference each other, mobile-implementation.md §3).
/// Post mutations themselves route through the `EngagementActions`
/// façade (CLASS 1), never from here.

@ProviderFor(composerContext)
final composerContextProvider = ComposerContextProvider._();

/// C15's orchestration point — the one place the composer meets the
/// measurement and profile repositories (ViewModels orchestrate;
/// repositories never reference each other, mobile-implementation.md §3).
/// Post mutations themselves route through the `EngagementActions`
/// façade (CLASS 1), never from here.

final class ComposerContextProvider
    extends
        $FunctionalProvider<
          AsyncValue<ComposerContext>,
          ComposerContext,
          FutureOr<ComposerContext>
        >
    with $FutureModifier<ComposerContext>, $FutureProvider<ComposerContext> {
  /// C15's orchestration point — the one place the composer meets the
  /// measurement and profile repositories (ViewModels orchestrate;
  /// repositories never reference each other, mobile-implementation.md §3).
  /// Post mutations themselves route through the `EngagementActions`
  /// façade (CLASS 1), never from here.
  ComposerContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'composerContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$composerContextHash();

  @$internal
  @override
  $FutureProviderElement<ComposerContext> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ComposerContext> create(Ref ref) {
    return composerContext(ref);
  }
}

String _$composerContextHash() => r'1900b9ea144f9de92f96c25169f6ccae648f81ea';
