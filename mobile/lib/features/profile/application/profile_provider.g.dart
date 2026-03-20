// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          IProfileRepository,
          IProfileRepository,
          IProfileRepository
        >
    with $Provider<IProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<IProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'579f8869050e329fcc1db2579cb635edb221a2d9';

@ProviderFor(ProfileNotifier)
final profileProvider = ProfileNotifierProvider._();

final class ProfileNotifierProvider
    extends $AsyncNotifierProvider<ProfileNotifier, UserProfile> {
  ProfileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileNotifierHash();

  @$internal
  @override
  ProfileNotifier create() => ProfileNotifier();
}

String _$profileNotifierHash() => r'13890a4985adb40d61b18f6f915be81687bccb72';

abstract class _$ProfileNotifier extends $AsyncNotifier<UserProfile> {
  FutureOr<UserProfile> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserProfile>, UserProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserProfile>, UserProfile>,
              AsyncValue<UserProfile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
