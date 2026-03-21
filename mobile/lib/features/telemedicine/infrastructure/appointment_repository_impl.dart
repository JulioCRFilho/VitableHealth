import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../domain/appointment.dart';
import '../domain/appointment_repository.dart';
import '../domain/doctor.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final String? token;

  AppointmentRepositoryImpl({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  @override
  Future<List<Doctor>> getDoctors() async {
    // For MVP, we can fetch from the AI endpoint or create a new one. 
    // Wait, the backend doesn't have an endpoint for strictly getting doctors,
    // but Gemini has a tool. Let's hardcode the MVP list on the client side
    // or we should create a Django endpoint. 
    // Since the task just says "MVP hardcode list of available doctors" and I put it in the backend,
    // I could just hardcode it here too to avoid another API endpoint unless required.
    // Let's just return the hardcoded list for MVP to match the backend list.
    return [
      Doctor(id: "doc_smith", name: "Dr. Smith", specialty: "General Practice"),
      Doctor(id: "doc_johnson", name: "Dr. Johnson", specialty: "Pediatrics"),
      Doctor(id: "doc_williams", name: "Dr. Williams", specialty: "Dermatology"),
    ];
  }

  @override
  Future<List<String>> getAvailableSlots(String doctorId, String date) async {
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/appointments/slots/?doctor_id=$doctorId&date=$date');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['slots'] ?? []);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to fetch slots';
      throw Exception(error);
    }
  }

  @override
  Future<Appointment> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/appointments/');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'doctor_id': doctorId,
        'date': date,
        'time': time,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Appointment.fromJson(data);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to book appointment';
      throw Exception(error);
    }
  }
}
