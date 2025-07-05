import 'package:flutter/material.dart';
import '../../services/ollama_service.dart';

class ChatbotWidget extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final String? financialContext;

  const ChatbotWidget({
    super.key,
    required this.isVisible,
    required this.onClose,
    this.financialContext,
  });

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hi! I'm your AI-powered financial assistant. I can help you analyze spending patterns, provide budgeting advice, set savings goals, and answer any questions about your finances. I'm connected to advanced AI to give you personalized financial insights. How can I help you today?",
      isBot: true,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void didUpdateWidget(ChatbotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isBot: false,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();

    // Add typing indicator
    setState(() {
      _messages.add(ChatMessage(
        text: "Thinking...",
        isBot: true,
        timestamp: DateTime.now(),
        isTyping: true,
      ));
    });

    try {
      // Get response from Ollama LLM
      final response = await OllamaService.sendMessage(
        messageText,
        context: widget.financialContext,
      );

      // Remove typing indicator and add actual response
      setState(() {
        _messages.removeWhere((msg) => msg.isTyping);
        _messages.add(ChatMessage(
          text: response,
          isBot: true,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      // Remove typing indicator and add fallback response
      setState(() {
        _messages.removeWhere((msg) => msg.isTyping);
        _messages.add(ChatMessage(
          text: _generateFallbackResponse(messageText),
          isBot: true,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('spending') || message.contains('expenses')) {
      return "I can help you analyze your spending patterns! Upload your bank CSV file and I'll show you insights about where your money goes, identify trends, and suggest ways to save.";
    } else if (message.contains('budget')) {
      return "Budgeting is key to financial health! I can help you set realistic budgets based on your spending history and track your progress throughout the month.";
    } else if (message.contains('save') || message.contains('saving')) {
      return "Great question about savings! I can help you set savings goals and show you exactly how much you need to save each month to reach them. Would you like to set a new savings goal?";
    } else if (message.contains('alert') || message.contains('notification')) {
      return "I monitor your spending 24/7 and send smart alerts when you're approaching budget limits, spending more than usual, or when I spot opportunities to save money.";
    } else if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return "Hello! I'm here to help you take control of your finances. You can ask me about your spending patterns, budgeting tips, savings goals, or anything else related to your money management.";
    } else if (message.contains('help')) {
      return "I can help you with:\n• Analyzing your spending patterns\n• Setting and tracking budgets\n• Creating savings goals\n• Getting spending alerts\n• Financial tips and insights\n\nJust ask me anything about your finances!";
    } else {
      return "I'm currently experiencing some technical difficulties with my AI brain, but I can still help you with basic financial questions! Try asking about spending analysis, budgeting, or savings goals.";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      bottom: 80,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 350,
              height: 500,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Financial Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Messages
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                  ),
                  
                  // Input area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[850] 
                          : Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Ask me about your finances...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[800] 
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isBot 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyan.withValues(alpha: 0.1),
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.cyan[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isBot 
                    ? Colors.grey[100] 
                    : Colors.cyan,
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.isTyping
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.cyan[700]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: message.isBot 
                            ? Colors.grey[800] 
                            : Colors.white,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.isTyping = false,
  });
}
