import 'package:hive/hive.dart';
import 'poi.dart';  // Le modèle POI
import './poi_infos/location.dart';  // Modèle Location
import './poi_infos/price_options.dart';  // Modèle PriceOptions
import './poi_infos/attendance_entry.dart';  // Modèle AttendanceEntry

class POIAdapter extends TypeAdapter<POI> {
  @override
  final int typeId = 0;

  @override
  POI read(BinaryReader reader) {
    return POI(
      eventID: reader.readString(),
      name: reader.readString(),
      organizerName: reader.read(),  // Peut être null
      startDate: reader.readString(),
      endDate: reader.readString(),
      startTime: reader.read(),  // Peut être null
      endTime: reader.read(),  // Peut être null
      photoUrl: reader.read(),  // Peut être null
      videoUrl: reader.read(),  // Peut être null
      description: reader.read(),  // Peut être null
      userOrganizer: reader.read(),  // Peut être null
      professionalOrganizer: reader.read(),  // Peut être null
      eventWazaaURL: reader.read(),  // Peut être null
      website: reader.read(),  // Peut être null
      ticketLink: reader.read(),  // Peut être null
      category: reader.read(),  // Peut être null
      subcategory: reader.read(),  // Peut être null
      tags: (reader.read() as List?)?.cast<String>(),  // Peut être null
      audience: reader.read(),  // Peut être null
      location: reader.read() as Location?,  // Peut être null
      accessibleForDisabled: reader.readBool(),
      priceOptions: reader.read() as PriceOptions?,  // Peut être null
      acceptedPayments: (reader.read() as List?)?.cast<String>(),  // Peut être null
      capacity: reader.read() as int?,
      type: reader.readString(),
      validationStatus: reader.readString(),
      attendance: (reader.read() as List?)?.cast<AttendanceEntry>(),  // Peut être null
      views: reader.readInt(),
      favoritesCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, POI obj) {
    writer.writeString(obj.eventID);
    writer.writeString(obj.name);
    writer.write(obj.organizerName);
    writer.writeString(obj.startDate);
    writer.writeString(obj.endDate);
    writer.write(obj.startTime);
    writer.write(obj.endTime);
    writer.write(obj.photoUrl);
    writer.write(obj.videoUrl);
    writer.write(obj.description);
    writer.write(obj.userOrganizer);
    writer.write(obj.professionalOrganizer);
    writer.write(obj.eventWazaaURL);
    writer.write(obj.website);
    writer.write(obj.ticketLink);
    writer.write(obj.category);
    writer.write(obj.subcategory);
    writer.write(obj.tags);
    writer.write(obj.audience);
    writer.write(obj.location);
    writer.writeBool(obj.accessibleForDisabled ?? false);
    writer.write(obj.priceOptions);
    writer.write(obj.acceptedPayments);
    writer.write(obj.capacity);
    writer.writeString(obj.type);
    writer.writeString(obj.validationStatus);
    writer.write(obj.attendance);
    writer.writeInt(obj.views);
    writer.writeInt(obj.favoritesCount);
  }
}
