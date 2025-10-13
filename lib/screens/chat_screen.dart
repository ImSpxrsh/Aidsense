import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final OPENAI_API_KEY = dotenv.env['OPENAI_API_KEY'];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
      "model": "gpt-5-nano",
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

    // Ensure a return for all other cases
    return "Sorry, I couldn't generate a response. Try asking something else.";
  }

  final ResourceService _resourceService = ResourceService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text:
          "Hello! I'm here to help you find resources in your community. You can ask me things like:\n\n• 'I need food tonight'\n• 'Where can I find shelter?'\n• 'I need medical help'\n• 'Show me pharmacies nearby'\n• 'I need mental health support'\n\n**Crisis Support Available 24/7** 🆘\nIf you're in crisis, I can provide immediate helpline numbers and connect you to professional support.\n\nWhat can I help you with today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage(String message) async {
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

    final response = await _processUserMessage(message);

    setState(() {
      _messages.add(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedResources: response.resources,
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
    final resources = await _resourceService.fetchResourcesOnce();
    print("Fetched ${resources.length} resources from service"); // DEBUG

    final Set<Resource> suggestedResources = {};

    final Map<String, List<String>> explicitRequests = {
      'shelter': ['i need shelter'],
      'food': ['i need food'],
      'clinic': ['i need medical help', 'i need a doctor', 'i need a clinic'],
      'pharmacy': ['i need medication', 'i need a pharmacy'],
      'mental': ['i need therapy', 'i need counseling', 'i need mental help'],
    };

    for (final type in explicitRequests.keys) {
      for (final phrase in explicitRequests[type]!) {
        if (lowerMessage.contains(phrase)) {
          final matched = resources.where((r) => r.type.toLowerCase() == type);
          print("Matched ${matched.length} resources for $type"); // DEBUG
          suggestedResources.addAll(matched);
          break;
        }
      }
    }

    if (suggestedResources.isEmpty && resources.isNotEmpty) {
      suggestedResources.addAll(resources.take(3));
      print("No explicit match, fallback to first 3 resources"); // DEBUG
    }

    String gptResponse;
    try {
      gptResponse = await getGpt5NanoResponse([
        {"role": "user", "content": message}
      ]);
    } catch (e) {
      gptResponse =
          "I couldn't fully process your request, but here are some helpful resources:";
      print('Error fetching GPT response: $e');
    }

    print(
        "Returning ${suggestedResources.length} suggested resources"); // DEBUG

    return ChatResponse(
      text: gptResponse,
      resources: suggestedResources.toList(),
    );
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

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_messages[index], primary);
            },
          ),
        ),
        // Quick action buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickButton("I need food", primary),
                const SizedBox(width: 8),
                _buildQuickButton("I need shelter", primary),
                const SizedBox(width: 8),
                _buildQuickButton("I need medical help", primary),
                const SizedBox(width: 8),
                _buildQuickButton("I need mental health support", primary),
              ],
            ),
          ),
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
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color primary) {
    // Check if this is the first welcome message
    final isWelcomeMessage = !message.isUser &&
        message.text.contains("Hello! I'm here to help you find resources");

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser)
                CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.1),
                  radius: 16,
                  child: Icon(Icons.smart_toy, color: primary, size: 18),
                ),
              if (!message.isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWelcomeMessage
                        ? const Color.fromARGB(255, 255, 167,
                            167) // Highlighted red for welcome message
                        : message.isUser
                            ? primary
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          message.isUser ? const Radius.circular(4) : null,
                      bottomLeft:
                          !message.isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isUser && !isWelcomeMessage)
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
                      if (!message.isUser && !isWelcomeMessage)
                        const SizedBox(height: 4),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : isWelcomeMessage
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
                              : isWelcomeMessage
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
                  backgroundColor: primary.withValues(alpha: 0.8),
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
    print(
        "Building resource card: ${resource.name}, ${resource.type}"); // DEBUG
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 40),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.1),
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
                  backgroundColor: primary.withValues(alpha: 0.1),
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF48A8A).withValues(alpha: 0.1),
            radius: 16,
            child:
                const Icon(Icons.smart_toy, color: Color(0xFFF48A8A), size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
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

  Widget _buildQuickButton(String text, Color primary) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
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

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'shelter':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'pharmacy':
        return Icons.local_pharmacy;
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
