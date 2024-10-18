// models/price_options.dart
class PriceOptions {
  final bool isFree;
  final double? uniquePrice;
  final PriceRange? priceRange;

  PriceOptions({
    required this.isFree,
    this.uniquePrice,
    this.priceRange,
  });

  factory PriceOptions.fromJson(Map<String, dynamic> json) {
    return PriceOptions(
      isFree: json['isFree'] ?? false,
      uniquePrice: (json['uniquePrice'] as num?)?.toDouble(),
      priceRange: json['priceRange'] != null ? PriceRange.fromJson(json['priceRange']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFree': isFree,
      'uniquePrice': uniquePrice,
      'priceRange': priceRange?.toJson(),
    };
  }
}

class PriceRange {
  final double min;
  final double max;

  PriceRange({
    required this.min,
    required this.max,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] ?? 0.0).toDouble(), // Assurez-vous d'avoir une valeur par défaut de 0.0
      max: (json['max'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}
