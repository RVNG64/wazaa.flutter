import 'package:hive/hive.dart';
import 'package:wazaa_app/models/poi_infos/attendance_entry.dart';

class AttendanceEntryAdapter extends TypeAdapter<AttendanceEntry> {
  @override
  final int typeId = 3;

  @override
  AttendanceEntry read(BinaryReader reader) {
    return AttendanceEntry(
      firebaseId: reader.readString(),
      status: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceEntry obj) {
    writer.writeString(obj.firebaseId);
    writer.writeString(obj.status);
  }
}
