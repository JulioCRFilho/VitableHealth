// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appointmentRepository)
final appointmentRepositoryProvider = AppointmentRepositoryProvider._();

final class AppointmentRepositoryProvider
    extends
        $FunctionalProvider<
          AppointmentRepository,
          AppointmentRepository,
          AppointmentRepository
        >
    with $Provider<AppointmentRepository> {
  AppointmentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appointmentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appointmentRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppointmentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppointmentRepository create(Ref ref) {
    return appointmentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppointmentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppointmentRepository>(value),
    );
  }
}

String _$appointmentRepositoryHash() =>
    r'c3656c2ad53dd6c7cbb07c5b47d56cb6e95f0d9a';

@ProviderFor(availableDoctors)
final availableDoctorsProvider = AvailableDoctorsProvider._();

final class AvailableDoctorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Doctor>>,
          List<Doctor>,
          FutureOr<List<Doctor>>
        >
    with $FutureModifier<List<Doctor>>, $FutureProvider<List<Doctor>> {
  AvailableDoctorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableDoctorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableDoctorsHash();

  @$internal
  @override
  $FutureProviderElement<List<Doctor>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Doctor>> create(Ref ref) {
    return availableDoctors(ref);
  }
}

String _$availableDoctorsHash() => r'5fad1d608e3d452dac1f6606ab9a1a114bf4a4d4';

@ProviderFor(AvailableSlotsNotifier)
final availableSlotsProvider = AvailableSlotsNotifierFamily._();

final class AvailableSlotsNotifierProvider
    extends $AsyncNotifierProvider<AvailableSlotsNotifier, List<String>> {
  AvailableSlotsNotifierProvider._({
    required AvailableSlotsNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'availableSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availableSlotsNotifierHash();

  @override
  String toString() {
    return r'availableSlotsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AvailableSlotsNotifier create() => AvailableSlotsNotifier();

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availableSlotsNotifierHash() =>
    r'c7a5d4693c9118c29ef12011f11771fc37a4bf95';

final class AvailableSlotsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AvailableSlotsNotifier,
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>,
          (String, String)
        > {
  AvailableSlotsNotifierFamily._()
    : super(
        retry: null,
        name: r'availableSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AvailableSlotsNotifierProvider call(String doctorId, String date) =>
      AvailableSlotsNotifierProvider._(argument: (doctorId, date), from: this);

  @override
  String toString() => r'availableSlotsProvider';
}

abstract class _$AvailableSlotsNotifier extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as (String, String);
  String get doctorId => _$args.$1;
  String get date => _$args.$2;

  FutureOr<List<String>> build(String doctorId, String date);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(AppointmentBookingNotifier)
final appointmentBookingProvider = AppointmentBookingNotifierProvider._();

final class AppointmentBookingNotifierProvider
    extends
        $NotifierProvider<
          AppointmentBookingNotifier,
          AsyncValue<Appointment?>
        > {
  AppointmentBookingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appointmentBookingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appointmentBookingNotifierHash();

  @$internal
  @override
  AppointmentBookingNotifier create() => AppointmentBookingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Appointment?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Appointment?>>(value),
    );
  }
}

String _$appointmentBookingNotifierHash() =>
    r'bcd61ca37d3f2821c2a13368d0fe0f0be3633150';

abstract class _$AppointmentBookingNotifier
    extends $Notifier<AsyncValue<Appointment?>> {
  AsyncValue<Appointment?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Appointment?>, AsyncValue<Appointment?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Appointment?>, AsyncValue<Appointment?>>,
              AsyncValue<Appointment?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
