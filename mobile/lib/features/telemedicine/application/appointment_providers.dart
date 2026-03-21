import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../identity/application/auth_notifier.dart';
import '../domain/appointment.dart';
import '../domain/appointment_repository.dart';
import '../domain/doctor.dart';
import '../infrastructure/appointment_repository_impl.dart';

part 'appointment_providers.g.dart';

@riverpod
AppointmentRepository appointmentRepository(Ref ref) {
  final token = ref.watch(authProvider.select((e) => e.value?.token));
  return AppointmentRepositoryImpl(token: token);
}

@riverpod
Future<List<Doctor>> availableDoctors(Ref ref) async {
  return ref.watch(appointmentRepositoryProvider).getDoctors();
}

// Provider that fetches slots based on the selected doctor and date
@riverpod
class AvailableSlotsNotifier extends _$AvailableSlotsNotifier {
  @override
  FutureOr<List<String>> build(String doctorId, String date) async {
    if (doctorId.isEmpty || date.isEmpty) return [];
    final repository = ref.watch(appointmentRepositoryProvider);
    return repository.getAvailableSlots(doctorId, date);
  }

  Future<void> refreshSlots(String doctorId, String date) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(appointmentRepositoryProvider);
      return repository.getAvailableSlots(doctorId, date);
    });
  }
}

// Provider for managing the booking process state
@riverpod
class AppointmentBookingNotifier extends _$AppointmentBookingNotifier {
  @override
  AsyncValue<Appointment?> build() {
    return const AsyncData(null);
  }

  Future<void> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(appointmentRepositoryProvider);
      return repository.bookAppointment(
        doctorId: doctorId,
        date: date,
        time: time,
        notes: notes,
      );
    });
  }
}
