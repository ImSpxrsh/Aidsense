import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/chat_message_model.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState.initial() = _Initial;
  
  const factory ChatState.loading() = _Loading;
  
  const factory ChatState.loaded(List<ChatMessageModel> messages) = ChatLoaded;
  
  const factory ChatState.error(String message) = _Error;
}
