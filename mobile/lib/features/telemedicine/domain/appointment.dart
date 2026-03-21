class Appointment {
  final String id;
  final String doctorId;
  final String date;
  final String time;
  final String status;
  final String? notes;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String? ?? '',
      doctorId: json['doctor_id'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'date': date,
      'time': time,
      'status': status,
      'notes': notes,
    };
  }
}
