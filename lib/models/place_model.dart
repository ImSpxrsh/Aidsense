import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_model.freezed.dart';
part 'place_model.g.dart';

@freezed
class PlaceModel with _$PlaceModel {
  const factory PlaceModel({
    required String id,
    required String name,
    required String description,
    required PlaceCategory category,
    required ContactInfo contactInfo,
    required Address address,
    required OperatingHours operatingHours,
    String? website,
    String? notes,
    List<String>? amenities,
    List<String>? services,
    bool? hasWifi,
    bool? wheelchairAccessible,
    double? rating,
    int? reviewCount,
    DateTime? lastUpdated,
  }) = _PlaceModel;

  factory PlaceModel.fromJson(Map<String, dynamic> json) =>
      _$PlaceModelFromJson(json);
}

@freezed
class ContactInfo with _$ContactInfo {
  const factory ContactInfo({
    String? phone,
    String? email,
    String? website,
  }) = _ContactInfo;

  factory ContactInfo.fromJson(Map<String, dynamic> json) =>
      _$ContactInfoFromJson(json);
}

@freezed
class Address with _$Address {
  const factory Address({
    required String street,
    required String city,
    required String state,
    required String zipCode,
    double? latitude,
    double? longitude,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}

@freezed
class OperatingHours with _$OperatingHours {
  const factory OperatingHours({
    Map<String, String>? weekdayHours,
    Map<String, String>? weekendHours,
    String? specialNotes,
    bool? isOpen24Hours,
    bool? isCurrentlyOpen,
  }) = _OperatingHours;

  factory OperatingHours.fromJson(Map<String, dynamic> json) =>
      _$OperatingHoursFromJson(json);
}

enum PlaceCategory {
  food,
  shelter,
  healthcare,
  mentalHealth,
  clothing,
  wifi,
  library,
  socialServices,
  employment,
  education,
  legal,
  transportation,
  emergency,
  restrooms,
  shower,
  other,
}
