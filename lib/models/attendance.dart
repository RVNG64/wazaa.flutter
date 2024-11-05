class Attendance {
  final String userId;
  final String userFirstName;
  final String userLastName;
  final String status;
  final String? userProfilePicture;
  final String? organizerProfilePicture;

  Attendance({
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.status,
    this.userProfilePicture,
    this.organizerProfilePicture,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      userId: json['user']['_id'],
      userFirstName: json['user']['firstName'],
      userLastName: json['user']['lastName'],
      status: json['status'],
      userProfilePicture: json['user']['profilePicture'],
      organizerProfilePicture: json['organizer']['profilePicture'],
    );
  }
}
