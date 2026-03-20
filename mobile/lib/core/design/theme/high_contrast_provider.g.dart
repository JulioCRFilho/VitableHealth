// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'high_contrast_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HighContrast)
final highContrastProvider = HighContrastProvider._();

final class HighContrastProvider extends $NotifierProvider<HighContrast, bool> {
  HighContrastProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'highContrastProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$highContrastHash();

  @$internal
  @override
  HighContrast create() => HighContrast();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$highContrastHash() => r'1ad5fc5056ceae50b1b64aa4a71107a4f6356016';

abstract class _$HighContrast extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
