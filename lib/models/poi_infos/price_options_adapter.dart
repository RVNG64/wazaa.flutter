import 'package:hive/hive.dart';
import 'package:wazaa_app/models/poi_infos/price_options.dart';

class PriceOptionsAdapter extends TypeAdapter<PriceOptions> {
  @override
  final int typeId = 2;

  @override
  PriceOptions read(BinaryReader reader) {
    return PriceOptions(
      isFree: reader.readBool(),
      uniquePrice: reader.read(),
      priceRange: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, PriceOptions obj) {
    writer.writeBool(obj.isFree);
    writer.write(obj.uniquePrice);
    writer.write(obj.priceRange);
  }
}
