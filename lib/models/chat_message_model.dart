import 'package:freezed_annotation/freezed_annotation.dart';
import 'place_model.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

@freezed
class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
    List<PlaceModel>? places,
    ChatMessageType? type,
    String? error,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
}

enum ChatMessageType {
  text,
  places,
  error,
  typing,
}

@freezed
class ChatSessionModel with _$ChatSessionModel {
  const factory ChatSessionModel({
    required String id,
    required List<ChatMessageModel> messages,
    required DateTime createdAt,
    String? title,
  }) = _ChatSessionModel;

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);
}
