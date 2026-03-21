import 'package:mobile/features/telemedicine/domain/appointment.dart';
import 'package:mobile/features/telemedicine/domain/appointment_repository.dart';
import 'package:mobile/features/telemedicine/domain/doctor.dart';

class FakeAppointmentRepository implements AppointmentRepository {
  bool networkFails = false;

  @override
  Future<List<Doctor>> getDoctors() async {
    return [
      Doctor(id: 'doc-1', name: 'Dr. Sarah Smith', specialty: 'General Practice'),
      Doctor(id: 'doc-busy', name: 'Dr. Busy', specialty: 'Dermatology'),
      Doctor(id: 'doc-conflict', name: 'Dr. Conflict', specialty: 'Cardiology'),
    ];
  }

  @override
  Future<List<String>> getAvailableSlots(String doctorId, String date) async {
    if (networkFails) throw Exception('Network connection lost');
    if (doctorId == 'doc-busy') return [];
    return ['09:00', '09:30', '10:00', '10:30'];
  }

  @override
  Future<Appointment> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? notes,
  }) async {
    if (networkFails) throw Exception('Network connection lost');
    if (doctorId == 'doc-conflict') throw Exception('Conflict');
    
    return Appointment(
      id: 'app-test',
      doctorId: doctorId,
      date: date,
      time: time,
      status: 'scheduled',
    );
  }
}

final fakeAppointmentRepository = FakeAppointmentRepository();
