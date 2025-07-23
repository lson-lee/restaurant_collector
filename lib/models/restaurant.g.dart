// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RestaurantAdapter extends TypeAdapter<Restaurant> {
  @override
  final int typeId = 0;

  @override
  Restaurant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Restaurant(
      id: fields[0] as int?,
      name: fields[1] as String,
      address: fields[2] as String?,
      phone: fields[3] as String?,
      cuisine: fields[4] as String?,
      priceRange: fields[5] as String?,
      rating: fields[6] as double?,
      description: fields[7] as String?,
      sourceUrl: fields[8] as String?,
      recommendedDishes: (fields[9] as List?)?.cast<String>(),
      businessHours: fields[10] as String?,
      images: (fields[11] as List?)?.cast<String>(),
      latitude: fields[12] as String?,
      longitude: fields[13] as String?,
      fullAddress: fields[14] as String?,
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
      features: (fields[17] as List?)?.cast<String>(),
      environment: fields[18] as String?,
      serviceHighlights: (fields[19] as List?)?.cast<String>(),
      userReviewKeywords: (fields[20] as List?)?.cast<String>(),
      marketingPoints: (fields[21] as List?)?.cast<String>(),
      parkingInfo: fields[22] as String?,
      specialOffers: fields[23] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Restaurant obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.cuisine)
      ..writeByte(5)
      ..write(obj.priceRange)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.sourceUrl)
      ..writeByte(9)
      ..write(obj.recommendedDishes)
      ..writeByte(10)
      ..write(obj.businessHours)
      ..writeByte(11)
      ..write(obj.images)
      ..writeByte(12)
      ..write(obj.latitude)
      ..writeByte(13)
      ..write(obj.longitude)
      ..writeByte(14)
      ..write(obj.fullAddress)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.features)
      ..writeByte(18)
      ..write(obj.environment)
      ..writeByte(19)
      ..write(obj.serviceHighlights)
      ..writeByte(20)
      ..write(obj.userReviewKeywords)
      ..writeByte(21)
      ..write(obj.marketingPoints)
      ..writeByte(22)
      ..write(obj.parkingInfo)
      ..writeByte(23)
      ..write(obj.specialOffers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
