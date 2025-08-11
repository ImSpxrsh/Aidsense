import 'package:freezed_annotation/freezed_annotation.dart';
import 'place_model.dart';

part 'search_request_model.freezed.dart';
part 'search_request_model.g.dart';

@freezed
class SearchRequestModel with _$SearchRequestModel {
  const factory SearchRequestModel({
    required String query,
    double? latitude,
    double? longitude,
    String? zipCode,
    int? maxResults,
    double? radiusInMiles,
    List<PlaceCategory>? categories,
    bool? openNow,
    bool? hasWifi,
    bool? wheelchairAccessible,
  }) = _SearchRequestModel;

  factory SearchRequestModel.fromJson(Map<String, dynamic> json) =>
      _$SearchRequestModelFromJson(json);
}

@freezed
class SearchResponseModel with _$SearchResponseModel {
  const factory SearchResponseModel({
    required List<PlaceModel> places,
    required List<PlaceCategory> detectedCategories,
    String? interpretedQuery,
    String? originalQuery,
    bool? usedOfflineMode,
    String? errorMessage,
    int? totalResults,
  }) = _SearchResponseModel;

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseModelFromJson(json);
}
