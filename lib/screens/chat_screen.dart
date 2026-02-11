import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final OPENAI_API_KEY = dotenv.env['OPENAI_API_KEY'];
final GOOGLE_PLACES = dotenv.env['MAPS_API_KEY'];

class ChatScreen extends StatefulWidget {
  final Resource? initialResource;
  final bool showAppBar;
  final List<Resource>? resources;

  const ChatScreen({
    super.key,
    this.initialResource,
    this.showAppBar = false,
    this.resources,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  Future<String> getGpt5NanoResponse(List<Map<String, String>> messages) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final fullMessages = [
      {
        "role": "system",
        "content":
            "You are a helpful assistant that suggests local resources based on the user's request. Be concise."
      },
      ...messages,
    ];

    final body = jsonEncode({
      "model": "o4-mini",
      "messages": fullMessages,
      "temperature": 1,
      "max_completion_tokens": 1500,
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $OPENAI_API_KEY",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'];
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        if (message != null && message['content'] != null) {
          final content = message['content'].toString().trim();
          if (content.isNotEmpty) {
            return content;
          }
        }
      }
    } else {
      throw Exception(
          'Failed to get response: ${response.statusCode} ${response.body}');
    }

    return "Sorry, I couldn't generate a response. Try asking something else.";
  }

  final ResourceService _resourceService = ResourceService();
  bool _isTyping = false;

  void _addWelcomeMessage() {
    String message;
    if (widget.initialResource != null) {
      final r = widget.initialResource!;
      message = "You are now asking about ${r.name} (${r.type}). "
          "You can ask me questions like hours, reviews, directions, or details.";
    } else {
      message =
          "Hello! I'm here to help you find resources in your community. You can ask me things like:\n\n• 'I need food tonight'\n• 'Where can I find shelter?'\n• 'I need medical help'\n• 'Show me pharmacies nearby'\n• 'I need mental health support'\n\n**Crisis Support Available 24/7** 🆘\nIf you're in crisis, I can provide immediate helpline numbers and connect you to professional support.\n\nWhat can I help you with today?";
    }

    _messages.add(ChatMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _sendMessage(String message, {bool showResources = true}) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Check if message matches a quick suggestion intent
    final lowerMessage = message.toLowerCase();
    String? resourceType;
    if (lowerMessage.contains('food')) {
      resourceType = 'food';
    } else if (lowerMessage.contains('shelter')) {
      resourceType = 'shelter';
    } else if (lowerMessage.contains('medical') ||
        lowerMessage.contains('doctor') ||
        lowerMessage.contains('clinic')) {
      resourceType = 'clinic';
    } else if (lowerMessage.contains('mental')) {
      resourceType = 'mental';
    }

    if (resourceType != null) {
      // Fetch top 5 resources of this type
      final resources =
          widget.resources ?? await _resourceService.fetchResourcesOnce();
      final matches = resources
          .where((r) => r.type.toLowerCase().contains(resourceType!))
          .take(5)
          .toList();
      setState(() {
        _messages.add(ChatMessage(
          text: matches.isNotEmpty
              ? 'Here are the nearest $resourceType resources:'
              : 'Sorry, I could not find any $resourceType resources nearby.',
          isUser: false,
          timestamp: DateTime.now(),
          suggestedResources: matches,
        ));
        _isTyping = false;
      });
      _scrollToBottom();
      return;
    }

    final response = await _processUserMessage(message);

    setState(() {
      _messages.add(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedResources: showResources ? response.resources : null,
      ));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.add(m);
      _isTyping = true;
    });

    final messagesForApi = _messages.map((msg) {
      return {"role": msg.isUser ? "user" : "assistant", "content": msg.text};
    }).toList();

    try {
      final responseText = await getGpt5NanoResponse(messagesForApi);

      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  Future<ChatResponse> _processUserMessage(String message) async {
    final lowerMessage = message.toLowerCase().trim();
    final resources =
        widget.resources ?? await _resourceService.fetchResourcesOnce();
    print("Fetched " + resources.length.toString() + " resources from service");

    final Set<Resource> suggestedResources = {};
    final Map<String, List<String>> explicitRequests = {
      'shelter': ['i need shelter'],
      'food': ['i need food'],
      'clinic': ['i need medical help', 'i need a doctor', 'i need a clinic'],
      'mental': ['i need therapy', 'i need counseling', 'i need mental help'],
    };

    for (final type in explicitRequests.keys) {
      for (final phrase in explicitRequests[type]!) {
        if (lowerMessage.contains(phrase)) {
          final matched =
              resources.where((r) => r.type.toLowerCase().contains(type));
          print("Matched " +
              matched.length.toString() +
              " resources for " +
              type);
          suggestedResources.addAll(matched);
          break;
        }
      }
    }

    if (suggestedResources.isEmpty && resources.isNotEmpty) {
      suggestedResources.addAll(resources.take(5));
      print("No explicit match, fallback to first 5 resources");
    }

    final topResources = suggestedResources.take(5).toList();
    String gptResponse;
    try {
      final gptPrompt = """
User asked: \"$message\"
About resource: \"${widget.initialResource?.name ?? "general"}\"
Nearby resources found:
${topResources.map((r) => "- ${r.name} at ${r.address} (${r.type})").join("\n")}
Respond helpfully and specifically about this resource.
""";
      gptResponse = await getGpt5NanoResponse([
        {"role": "user", "content": gptPrompt}
      ]);
    } catch (e) {
      gptResponse =
          "I couldn't fully process your request, but here are some helpful resources:";
    }

    print(
        "Returning " + topResources.length.toString() + " suggested resources");
    return ChatResponse(
      text: gptResponse,
      resources: topResources,
    );
  }

  Future<List<Map<String, dynamic>>> fetchNearbyPlaces(
      String query, double lat, double lng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&keyword=${Uri.encodeComponent(query)}&key=$GOOGLE_PLACES');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      print('Google Places API error: ${response.statusCode}');
      return [];
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildQuickButton(String text, Color primary) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withAlpha(76)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color primary, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: isLast ? 40 : 16,
        top: isLast ? 12 : 0,
      ),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser)
                CircleAvatar(
                  backgroundColor: primary.withAlpha(204),
                  radius: 16,
                  child: const Icon(Icons.smart_toy,
                      color: Colors.white, size: 18),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          message.isUser ? const Radius.circular(4) : null,
                      bottomLeft:
                          !message.isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: message.text == '__typing__'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTypingDot(0),
                            const SizedBox(width: 4),
                            _buildTypingDot(1),
                            const SizedBox(width: 4),
                            _buildTypingDot(2),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!message.isUser)
                              Row(
                                children: [
                                  Icon(
                                    Icons.smart_toy,
                                    color: primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Assistant',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            if (!message.isUser) const SizedBox(height: 4),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: message.isUser
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (message.isUser) const SizedBox(width: 8),
              if (message.isUser)
                CircleAvatar(
                  backgroundColor: primary.withAlpha(204),
                  radius: 16,
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 18),
                ),
            ],
          ),
          if (message.suggestedResources != null &&
              message.suggestedResources!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: message.suggestedResources!
                    .map((resource) => _buildResourceCard(resource, primary))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Customized quick suggestions per resource type
  List<String> _getSuggestionsForType(String? type) {
    switch (type) {
      case 'food':
        return [
          'What are the hours?',
          'Is there a food pantry nearby?',
          'How do I get free meals?'
        ];
      case 'shelter':
        return [
          'Is there space available?',
          'What do I need to bring?',
          'How long can I stay?'
        ];
      case 'clinic':
        return [
          'What services are offered?',
          'Do I need insurance?',
          'What are the hours?'
        ];
      case 'mental':
        return [
          'Is there a counselor available?',
          'How do I get support?',
          'Is it confidential?'
        ];
      default:
        return [
          'I need food',
          'I need shelter',
          'I need medical help',
          'I need mental health support',
        ];
    }
  }

  Widget _buildQuickSuggestions(Color primary) {
    String? type;
    if (widget.initialResource != null) {
      type = widget.initialResource!.type.toLowerCase();
    }
    final suggestions = _getSuggestionsForType(type);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final s in suggestions.take(3)) ...[
            _buildQuickButton(s, primary),
            const SizedBox(width: 8),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFF48A8A),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Ask AI',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    // Show typing animation as a chat bubble (AI style)
                    return _buildTypingBubble(primary);
                  }
                  return _buildMessageBubble(
                      _messages[index], primary, index == _messages.length - 1);
                },
              ),
            ),
            // Quick action buttons (scrollable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildQuickSuggestions(primary),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: Icon(
                            Icons.mic,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                        maxLines: null,
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_messageController.text,
                          showResources: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble(Color primary) {
    // This is a chat bubble styled like an AI message, but only shows the animated dots
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: primary.withAlpha(25),
            radius: 16,
            child: Icon(Icons.smart_toy, color: primary, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                AnimatedChatDot(index: 0),
                SizedBox(width: 4),
                AnimatedChatDot(index: 1),
                SizedBox(width: 4),
                AnimatedChatDot(index: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildResourceCard(Resource resource, Color primary) {
    print("Building resource card: ${resource.name}, ${resource.type}");
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 40),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primary.withAlpha(25),
          child: Icon(
            _getResourceIcon(resource.type),
            color: primary,
            size: 18,
          ),
        ),
        title: Text(resource.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.address, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(resource.type),
                  backgroundColor: primary.withAlpha(25),
                  labelStyle: TextStyle(color: primary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () =>
            Navigator.pushNamed(context, '/resource', arguments: resource),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'shelter':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'clinic':
        return Icons.local_hospital;
      default:
        return Icons.location_on;
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Resource>? suggestedResources;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedResources,
  });
}

class ChatResponse {
  final String text;
  final List<Resource> resources;

  ChatResponse({
    required this.text,
    required this.resources,
  });
}

class AnimatedChatDot extends StatefulWidget {
  final int index;
  const AnimatedChatDot({super.key, required this.index});

  @override
  State<AnimatedChatDot> createState() => _AnimatedChatDotState();
}

class _AnimatedChatDotState extends State<AnimatedChatDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.2,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF48A8A),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
