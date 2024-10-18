// models/attendance_entry.dart
class AttendanceEntry {
  final String firebaseId;
  final String status;

  AttendanceEntry({
    required this.firebaseId,
    required this.status,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      firebaseId: json['firebaseId'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firebaseId': firebaseId,
      'status': status,
    };
  }
}
