import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/place_model.dart';

class ChatService {
  static const String _huggingFaceUrl = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium';
  static const String _apiKey = 'YOUR_HUGGING_FACE_API_KEY'; // Free API key

  /// Process user input using free AI API with fallback to local processing
  Future<ChatProcessingResult> processUserInput(String userInput) async {
    try {
      // Try online processing first
      final response = await http.post(
        Uri.parse(_huggingFaceUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'inputs': userInput,
          'parameters': {
            'max_length': 100,
            'temperature': 0.7,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processAIResponse(data, userInput);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to offline processing
      return _processOffline(userInput);
    }
  }

  /// Offline fallback using keyword matching for essential services
  ChatProcessingResult _processOffline(String userInput) {
    final input = userInput.toLowerCase();
    final List<String> categories = [];
    final List<String> keywords = [];

    // Food-related keywords (highest priority)
    if (input.contains('hungry') || input.contains('food') || input.contains('eat') ||
        input.contains('meal') || input.contains('pantry') || input.contains('soup kitchen') ||
        input.contains('free food') || input.contains('food bank')) {
      categories.add('food');
      keywords.addAll(['food bank', 'soup kitchen', 'food pantry', 'free meals']);
    }

    // Shelter-related keywords (highest priority)
    if (input.contains('homeless') || input.contains('shelter') || input.contains('sleep') ||
        input.contains('place to stay') || input.contains('overnight') || input.contains('housing') ||
        input.contains('kicked out') || input.contains('evicted')) {
      categories.add('shelter');
      keywords.addAll(['homeless shelter', 'emergency housing', 'overnight shelter']);
    }

    // Healthcare keywords (high priority)
    if (input.contains('doctor') || input.contains('hospital') || input.contains('medical') ||
        input.contains('clinic') || input.contains('sick') || input.contains('health') ||
        input.contains('free clinic') || input.contains('emergency room')) {
      categories.add('healthcare');
      keywords.addAll(['free clinic', 'community health center', 'emergency room']);
    }

    // Mental health keywords
    if (input.contains('depressed') || input.contains('anxiety') || input.contains('counseling') ||
        input.contains('therapy') || input.contains('mental') || input.contains('crisis') ||
        input.contains('suicide') || input.contains('help')) {
      categories.add('mentalHealth');
      keywords.addAll(['crisis center', 'counseling', 'mental health services']);
    }

    // Free WiFi keywords
    if (input.contains('wifi') || input.contains('internet') || input.contains('computer') ||
        input.contains('online') || input.contains('charge phone')) {
      categories.add('wifi');
      keywords.addAll(['library', 'starbucks', 'mcdonalds', 'community center', 'free wifi']);
    }

    // Clothing keywords
    if (input.contains('clothes') || input.contains('clothing') || input.contains('shirt') ||
        input.contains('pants') || input.contains('coat') || input.contains('shoes')) {
      categories.add('clothing');
      keywords.addAll(['clothing bank', 'donation center', 'thrift store']);
    }

    // Shower/hygiene keywords
    if (input.contains('shower') || input.contains('wash') || input.contains('clean') ||
        input.contains('hygiene') || input.contains('bathroom')) {
      categories.add('shower');
      categories.add('restrooms');
      keywords.addAll(['community center', 'gym', 'public restrooms']);
    }

    // Job/employment keywords
    if (input.contains('job') || input.contains('work') || input.contains('employment') ||
        input.contains('resume') || input.contains('hire')) {
      categories.add('employment');
      keywords.addAll(['job center', 'workforce development', 'employment services']);
    }

    // Legal aid keywords
    if (input.contains('legal') || input.contains('lawyer') || input.contains('court') ||
        input.contains('eviction') || input.contains('benefits')) {
      categories.add('legal');
      keywords.addAll(['legal aid', 'free lawyer', 'legal services']);
    }

    // Transportation keywords
    if (input.contains('bus') || input.contains('train') || input.contains('ride') ||
        input.contains('transport') || input.contains('get there')) {
      categories.add('transportation');
      keywords.addAll(['bus stop', 'train station', 'public transit']);
    }

    String responseText = _generateResponse(categories, userInput);

    return ChatProcessingResult(
      responseText: responseText,
      detectedCategories: categories,
      searchKeywords: keywords,
      confidence: 0.8, // Higher confidence for essential services
      usedOfflineMode: true,
    );
  }

  ChatProcessingResult _processAIResponse(dynamic apiResponse, String userInput) {
    // Process the AI response and extract relevant information
    // This would depend on the specific API response format
    
    // For now, fall back to offline processing
    return _processOffline(userInput);
  }

  String _generateResponse(List<String> categories, String userInput) {
    if (categories.isEmpty) {
      return "I can help you find essential services like food, shelter, healthcare, and more. What do you need help with?";
    }
    
    if (categories.contains('food')) {
      return "I understand you need food assistance. Let me find food banks, soup kitchens, and free meal programs near you.";
    }
    
    if (categories.contains('shelter')) {
      return "Looking for a safe place to stay? I'll help you find emergency shelters and housing assistance in your area.";
    }
    
    if (categories.contains('healthcare')) {
      return "I can help you find free clinics, community health centers, and emergency medical care nearby.";
    }
    
    if (categories.contains('mentalHealth')) {
      return "Mental health support is important. Let me find crisis centers, counseling services, and support groups for you.";
    }
    
    if (categories.contains('wifi')) {
      return "Need internet access? I'll find places with free WiFi like libraries, community centers, and some businesses.";
    }
    
    if (categories.contains('clothing')) {
      return "Looking for clothing? I can help you find clothing banks, donation centers, and thrift stores.";
    }
    
    if (categories.contains('shower')) {
      return "For shower and hygiene needs, I'll find community centers, gyms, and facilities that offer these services.";
    }
    
    if (categories.contains('employment')) {
      return "Looking for work? I can help you find job centers, employment services, and places that help with resumes.";
    }
    
    if (categories.contains('legal')) {
      return "Need legal help? I'll find legal aid organizations and free legal services in your area.";
    }
    
    return "I found several resources that might help with what you're looking for. Let me search for the closest options.";
  }

  /// Extract place categories from user input
  List<PlaceCategory> extractCategories(List<String> categoryStrings) {
    return categoryStrings
        .map((cat) => _stringToPlaceCategory(cat))
        .where((cat) => cat != null)
        .cast<PlaceCategory>()
        .toList();
  }

  PlaceCategory? _stringToPlaceCategory(String categoryString) {
    switch (categoryString.toLowerCase()) {
      case 'food':
        return PlaceCategory.food;
      case 'shelter':
        return PlaceCategory.shelter;
      case 'healthcare':
      case 'medical':
        return PlaceCategory.healthcare;
      case 'mentalhealth':
      case 'mental':
        return PlaceCategory.mentalHealth;
      case 'clothing':
        return PlaceCategory.clothing;
      case 'wifi':
        return PlaceCategory.wifi;
      case 'library':
        return PlaceCategory.library;
      case 'socialservices':
        return PlaceCategory.socialServices;
      case 'employment':
      case 'job':
        return PlaceCategory.employment;
      case 'education':
        return PlaceCategory.education;
      case 'legal':
        return PlaceCategory.legal;
      case 'transportation':
        return PlaceCategory.transportation;
      case 'emergency':
        return PlaceCategory.emergency;
      case 'restrooms':
        return PlaceCategory.restrooms;
      case 'shower':
        return PlaceCategory.shower;
      default:
        return PlaceCategory.other;
    }
  }
}

class ChatProcessingResult {
  final String responseText;
  final List<String> detectedCategories;
  final List<String> searchKeywords;
  final double confidence;
  final bool usedOfflineMode;

  ChatProcessingResult({
    required this.responseText,
    required this.detectedCategories,
    required this.searchKeywords,
    required this.confidence,
    required this.usedOfflineMode,
  });
}
