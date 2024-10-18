import 'package:hive/hive.dart';
import 'package:wazaa_app/models/poi_infos/location.dart';

class LocationAdapter extends TypeAdapter<Location> {
  @override
  final int typeId = 1;

  @override
  Location read(BinaryReader reader) {
    return Location(
      address: reader.read(),
      postalCode: reader.read(),
      city: reader.read(),
      latitude: reader.readDouble(),
      longitude: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Location obj) {
    writer.write(obj.address);
    writer.write(obj.postalCode);
    writer.write(obj.city);
    writer.writeDouble(obj.latitude ?? 0.0);
    writer.writeDouble(obj.longitude ?? 0.0);
  }
}
