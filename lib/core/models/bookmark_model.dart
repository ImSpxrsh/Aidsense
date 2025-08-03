import 'package:freezed_annotation/freezed_annotation.dart';
import 'place_model.dart';

part 'bookmark_model.freezed.dart';
part 'bookmark_model.g.dart';

@freezed
class BookmarkModel with _$BookmarkModel {
  const factory BookmarkModel({
    required String id,
    required String placeId,
    required PlaceModel place,
    required DateTime createdAt,
    String? notes,
    List<String>? tags,
    String? userId,
  }) = _BookmarkModel;

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);
}
