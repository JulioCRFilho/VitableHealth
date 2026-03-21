import 'appointment.dart';
import 'doctor.dart';

abstract class AppointmentRepository {
  /// Fetches the list of available doctors/specialists.
  Future<List<Doctor>> getDoctors();

  /// Fetches available slots for a given doctor on a given date (YYYY-MM-DD).
  Future<List<String>> getAvailableSlots(String doctorId, String date);

  /// Books an appointment for the user.
  Future<Appointment> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? notes,
  });
}
