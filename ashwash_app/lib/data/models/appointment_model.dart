import 'specialist_model.dart';

class AppointmentModel {
  final int id;
  final SpecialistModel specialist;
  final String appointmentDate;
  final String timeSlot;
  final String status;
  final String meetingLink;

  AppointmentModel({
    required this.id,
    required this.specialist,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    required this.meetingLink,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      specialist: SpecialistModel.fromJson(json['specialist'] ?? {}),
      appointmentDate: json['appointment_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      status: json['status'] ?? 'confirmed',
      meetingLink: json['meeting_link'] ?? 'https://meet.google.com/ash-wash-wellness',
    );
  }
}
