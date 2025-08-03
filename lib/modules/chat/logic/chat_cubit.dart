import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/firebase/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/chat_message_model.dart';
import '../../../core/models/place_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  final FirestoreService _firestoreService;
  final LocationService _locationService;

  ChatCubit({
    required ChatService chatService,
    required FirestoreService firestoreService,
    required LocationService locationService,
  })  : _chatService = chatService,
        _firestoreService = firestoreService,
        _locationService = locationService,
        super(const ChatState.initial());

  Future<void> sendMessage(String message) async {
    // Add user message
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );

    final currentState = state;
    List<ChatMessageModel> messages = [];
    
    if (currentState is ChatLoaded) {
      messages = [...currentState.messages, userMessage];
    } else {
      messages = [userMessage];
    }

    emit(ChatState.loaded(messages));

    // Show typing indicator
    final typingMessage = ChatMessageModel(
      id: 'typing',
      text: 'AidSense is thinking...',
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.typing,
    );

    emit(ChatState.loaded([...messages, typingMessage]));

    try {
      // Process message with AI
      final result = await _chatService.processUserInput(message);
      
      // Remove typing indicator
      messages = messages.where((msg) => msg.id != 'typing').toList();

      // Search for places if categories were detected
      List<PlaceModel> places = [];
      if (result.detectedCategories.isNotEmpty) {
        places = await _searchPlaces(result.detectedCategories);
      }

      // Create bot response
      final botMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: result.responseText,
        isUser: false,
        timestamp: DateTime.now(),
        type: places.isNotEmpty ? ChatMessageType.places : ChatMessageType.text,
        places: places.isNotEmpty ? places : null,
      );

      messages = [...messages, botMessage];
      emit(ChatState.loaded(messages));

    } catch (e) {
      // Remove typing indicator and show error
      messages = messages.where((msg) => msg.id != 'typing').toList();
      
      final errorMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.error,
        error: e.toString(),
      );

      messages = [...messages, errorMessage];
      emit(ChatState.loaded(messages));
    }
  }

  Future<List<PlaceModel>> _searchPlaces(List<String> categories) async {
    try {
      // Get user location
      final position = await _locationService.getCurrentLocation();
      
      // Convert string categories to PlaceCategory enums
      final placeCategories = _chatService.extractCategories(categories);
      
      // Search Firestore for places
      final places = await _firestoreService.searchPlaces(
        categories: placeCategories,
        latitude: position?.latitude,
        longitude: position?.longitude,
        limit: 5,
      );

      // Sort by distance if location is available
      if (position != null && places.isNotEmpty) {
        places.sort((a, b) {
          if (a.address.latitude == null || a.address.longitude == null) return 1;
          if (b.address.latitude == null || b.address.longitude == null) return -1;

          final distanceA = _locationService.calculateDistanceInMiles(
            position.latitude,
            position.longitude,
            a.address.latitude!,
            a.address.longitude!,
          );

          final distanceB = _locationService.calculateDistanceInMiles(
            position.latitude,
            position.longitude,
            b.address.latitude!,
            b.address.longitude!,
          );

          return distanceA.compareTo(distanceB);
        });
      }

      return places;
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  void clearChat() {
    emit(const ChatState.initial());
  }

  void startNewSession() {
    final welcomeMessage = ChatMessageModel(
      id: 'welcome',
      text: 'Hello! I\'m your AidSense assistant. I can help you find local resources in New Jersey Congressional District 9. Try asking me about places with free WiFi, restaurants, libraries, or other local services.',
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );

    emit(ChatState.loaded([welcomeMessage]));
  }
}
