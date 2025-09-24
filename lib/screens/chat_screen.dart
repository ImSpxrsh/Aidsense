import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ResourceService _resourceService = ResourceService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm here to help you find resources in your community. You can ask me things like:\n\n• 'I need food tonight'\n• 'Where can I find shelter?'\n• 'I need medical help'\n• 'Show me pharmacies nearby'\n• 'I need mental health support'\n\n**Crisis Support Available 24/7** 🆘\nIf you're in crisis, I can provide immediate helpline numbers and connect you to professional support.\n\nWhat can I help you with today?",
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

    await Future.delayed(const Duration(seconds: 1));

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

  Future<ChatResponse> _processUserMessage(String message) async {
    final lowerMessage = message.toLowerCase();
    final resources = await _resourceService.fetchResourcesOnce();
    
    List<Resource> suggestedResources = [];
    String responseText = "";

    // CRISIS RESPONSE KEYWORDS (highest priority)
    if (lowerMessage.contains('suicide') || lowerMessage.contains('kill myself') || 
        lowerMessage.contains('end my life') || lowerMessage.contains('want to die') || 
        lowerMessage.contains('suicidal') || lowerMessage.contains('harm myself')) {
      responseText = "🚨 **IMMEDIATE HELP AVAILABLE** 🚨\n\n"
          "If you're having thoughts of suicide, please reach out for help immediately:\n\n"
          " **National Suicide Prevention Lifeline**: 988 or 1-800-273-8255\n"
          " **Crisis Text Line**: Text HOME to 741741\n"
          " **Online Chat**: suicidepreventionlifeline.org\n\n"
          "You are not alone, and your life has value. These trained counselors are available 24/7 and want to help.";
      
      suggestedResources = resources.where((r) => 
        r.type.toLowerCase().contains('mental') || 
        r.tags.any((tag) => tag.toLowerCase().contains('mental') || 
                           tag.toLowerCase().contains('counseling') ||
                           tag.toLowerCase().contains('therapy'))
      ).toList();
    } 
    else if (lowerMessage.contains('depression') || lowerMessage.contains('depressed') || 
             lowerMessage.contains('anxiety') || lowerMessage.contains('mental health') ||
             lowerMessage.contains('counseling') || lowerMessage.contains('therapy')) {
      responseText = "💙 **Mental Health Support** 💙\n\n"
          "It's brave to reach out for mental health support. Here are immediate resources:\n\n"
          "📞 **SAMHSA National Helpline**: 1-800-662-4357 (24/7, free)\n"
          "📞 **Crisis Text Line**: Text HOME to 741741\n"
          "📞 **NAMI Helpline**: 1-800-950-6264\n\n"
          "Professional help is available, and you deserve support.";
          
      suggestedResources = resources.where((r) => 
        r.type.toLowerCase().contains('mental') || 
        r.tags.any((tag) => tag.toLowerCase().contains('mental') || 
                           tag.toLowerCase().contains('counseling') ||
                           tag.toLowerCase().contains('therapy'))
      ).toList();
    }
    else if (lowerMessage.contains('abuse') || lowerMessage.contains('domestic violence') || 
             lowerMessage.contains('being hurt') || lowerMessage.contains('unsafe at home')) {
      responseText = "🛡️ **Safety First** 🛡️\n\n"
          "If you're experiencing abuse, you deserve safety and support:\n\n"
          "📞 **National Domestic Violence Hotline**: 1-800-799-7233\n"
          "📱 **Text**: START to 88788\n"
          "🌐 **Online Chat**: thehotline.org\n\n"
          "These services are confidential and available 24/7. Your safety matters.";
          
      suggestedResources = resources.where((r) => 
        r.tags.any((tag) => tag.toLowerCase().contains('shelter') || 
                           tag.toLowerCase().contains('safety') ||
                           tag.toLowerCase().contains('women') ||
                           tag.toLowerCase().contains('domestic'))
      ).toList();
    }
    else if (lowerMessage.contains('addiction') || lowerMessage.contains('substance') || 
             lowerMessage.contains('alcohol') || lowerMessage.contains('drug problem') ||
             lowerMessage.contains('overdose')) {
      responseText = "🤝 **Addiction Support** 🤝\n\n"
          "Recovery is possible, and help is available:\n\n"
          "📞 **SAMHSA Treatment Locator**: 1-800-662-4357\n"
          "📞 **Narcotics Anonymous**: 1-818-773-9999\n"
          "📞 **Alcoholics Anonymous**: Check aa.org for local meetings\n\n"
          "Recovery takes courage, and you're taking the first step by reaching out.";
          
      suggestedResources = resources.where((r) => 
        r.tags.any((tag) => tag.toLowerCase().contains('addiction') || 
                           tag.toLowerCase().contains('recovery') ||
                           tag.toLowerCase().contains('substance'))
      ).toList();
    }
    // REGULAR RESOURCE KEYWORDS
    else if (lowerMessage.contains('food') || lowerMessage.contains('hungry') || lowerMessage.contains('eat')) {
      suggestedResources = resources.where((r) => r.type == 'food').toList();
      responseText = "I found ${suggestedResources.length} food resources near you. These include food banks, pantries, and meal programs:";
    } else if (lowerMessage.contains('shelter') || lowerMessage.contains('home') || lowerMessage.contains('sleep') || lowerMessage.contains('homeless')) {
      suggestedResources = resources.where((r) => r.type == 'shelter').toList();
      responseText = "Here are ${suggestedResources.length} shelter options I found for you:";
    } else if (lowerMessage.contains('medicine') || lowerMessage.contains('pharmacy') || lowerMessage.contains('prescription') || lowerMessage.contains('drug')) {
      suggestedResources = resources.where((r) => r.type == 'pharmacy').toList();
      responseText = "I found ${suggestedResources.length} pharmacies that can help with your medication needs:";
    } else if (lowerMessage.contains('doctor') || lowerMessage.contains('medical') || lowerMessage.contains('clinic') || lowerMessage.contains('sick') || lowerMessage.contains('health')) {
      suggestedResources = resources.where((r) => r.type == 'clinic').toList();
      responseText = "Here are ${suggestedResources.length} medical facilities that can provide healthcare services:";
    } else if (lowerMessage.contains('help') || lowerMessage.contains('emergency') || lowerMessage.contains('crisis')) {
      suggestedResources = resources.take(3).toList(); // Show top 3 resources
      responseText = "I'm here to help! Here are some essential resources that might be useful in your situation. If this is a medical emergency, please call 911 immediately.";
    } else {
      // General search across all resources
      suggestedResources = resources.where((r) => 
        r.name.toLowerCase().contains(lowerMessage) ||
        r.tags.any((tag) => tag.toLowerCase().contains(lowerMessage)) ||
        r.address.toLowerCase().contains(lowerMessage)
      ).toList();
      
      if (suggestedResources.isEmpty) {
        responseText = "I couldn't find specific resources for your request, but here are some general community resources that might help:";
        suggestedResources = resources.take(3).toList();
      } else {
        responseText = "I found ${suggestedResources.length} resources related to your request:";
      }
    }

    return ChatResponse(
      text: responseText,
      resources: suggestedResources.take(5).toList(), // Limit to 5 suggestions
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
    final primary = const Color(0xFFF48A8A);
    
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask me about resources...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser)
                CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.1),
                  radius: 16,
                  child: Icon(Icons.support_agent, color: primary, size: 18),
                ),
              if (!message.isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: message.isUser ? const Radius.circular(4) : null,
                      bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (message.isUser) const SizedBox(width: 8),
              if (message.isUser)
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 16,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
            ],
          ),
          if (message.suggestedResources != null && message.suggestedResources!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: message.suggestedResources!.map((resource) => 
                  _buildResourceCard(resource, primary)
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Resource resource, Color primary) {
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
        title: Text(resource.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
        onTap: () => Navigator.pushNamed(context, '/resource', arguments: resource),
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
            child: const Icon(Icons.support_agent, color: Color(0xFFF48A8A), size: 18),
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