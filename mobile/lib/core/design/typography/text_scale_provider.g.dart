// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_scale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TextScale)
final textScaleProvider = TextScaleProvider._();

final class TextScaleProvider extends $NotifierProvider<TextScale, double> {
  TextScaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textScaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textScaleHash();

  @$internal
  @override
  TextScale create() => TextScale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$textScaleHash() => r'd51c564ce218c6be6a15d78b4f1ac423f875a4be';

abstract class _$TextScale extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
