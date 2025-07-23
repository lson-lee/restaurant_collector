import 'package:hive/hive.dart';

part 'restaurant.g.dart';

@HiveType(typeId: 0)
class Restaurant extends HiveObject {
  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? address;
  
  @HiveField(3)
  final String? phone;
  
  @HiveField(4)
  final String? cuisine;
  
  @HiveField(5)
  final String? priceRange;
  
  @HiveField(6)
  final double? rating;
  
  @HiveField(7)
  final String? description;
  
  @HiveField(8)
  final String? sourceUrl;
  
  @HiveField(9)
  final List<String>? recommendedDishes;
  
  @HiveField(10)
  final String? businessHours;
  
  @HiveField(11)
  final List<String>? images;
  
  @HiveField(12)
  final String? latitude;
  
  @HiveField(13)
  final String? longitude;
  
  @HiveField(14)
  final String? fullAddress;
  
  @HiveField(15)
  final DateTime? createdAt;
  
  @HiveField(16)
  final DateTime? updatedAt;
  
  // 新增拓展字段
  @HiveField(17)
  final List<String>? features;
  
  @HiveField(18)
  final String? environment;
  
  @HiveField(19)
  final List<String>? serviceHighlights;
  
  @HiveField(20)
  final List<String>? userReviewKeywords;
  
  @HiveField(21)
  final List<String>? marketingPoints;
  
  @HiveField(22)
  final String? parkingInfo;
  
  @HiveField(23)
  final String? specialOffers;

  Restaurant({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.cuisine,
    this.priceRange,
    this.rating,
    this.description,
    this.sourceUrl,
    this.recommendedDishes,
    this.businessHours,
    this.images,
    this.latitude,
    this.longitude,
    this.fullAddress,
    this.createdAt,
    this.updatedAt,
    this.features,
    this.environment,
    this.serviceHighlights,
    this.userReviewKeywords,
    this.marketingPoints,
    this.parkingInfo,
    this.specialOffers,
  });



  // copyWith方法
  Restaurant copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? cuisine,
    String? priceRange,
    double? rating,
    String? description,
    String? sourceUrl,
    List<String>? recommendedDishes,
    String? businessHours,
    List<String>? images,
    String? latitude,
    String? longitude,
    String? fullAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? features,
    String? environment,
    List<String>? serviceHighlights,
    List<String>? userReviewKeywords,
    List<String>? marketingPoints,
    String? parkingInfo,
    String? specialOffers,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      cuisine: cuisine ?? this.cuisine,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      recommendedDishes: recommendedDishes ?? this.recommendedDishes,
      businessHours: businessHours ?? this.businessHours,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fullAddress: fullAddress ?? this.fullAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      features: features ?? this.features,
      environment: environment ?? this.environment,
      serviceHighlights: serviceHighlights ?? this.serviceHighlights,
      userReviewKeywords: userReviewKeywords ?? this.userReviewKeywords,
      marketingPoints: marketingPoints ?? this.marketingPoints,
      parkingInfo: parkingInfo ?? this.parkingInfo,
      specialOffers: specialOffers ?? this.specialOffers,
    );
  }

  @override
  String toString() {
    return 'Restaurant{id: $id, name: $name, address: $address, cuisine: $cuisine, rating: $rating}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
} 