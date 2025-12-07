import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/ai_chat_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/ai_chat_service.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String category; // 'pregnancy', 'fertility', 'skincare', 'general'
  final Map<String, dynamic>?
      context; // Additional context (pregnancy week, etc.)

  const AIChatScreen({
    super.key,
    required this.category,
    this.context,
  });

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = AIService();
  final _chatService = AIChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isConfigured => _aiService.isConfigured();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    if (!_isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('AI Assistant is not configured. Please contact support.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _messageController.clear();
    });

    try {
      // Get conversation history
      final messagesStream =
          _chatService.getChatMessages(user.userId, widget.category);
      final messagesSnapshot = await messagesStream.first;
      final conversationHistory = messagesSnapshot;

      // Save user message
      final userMessage = AIChatMessage(
        userId: user.userId,
        category: widget.category,
        role: 'user',
        content: text,
        timestamp: DateTime.now(),
        metadata: widget.context,
      );
      await _chatService.saveMessage(userMessage);

      // Get AI response
      final response = await _aiService.sendMessage(
        userId: user.userId,
        category: widget.category,
        message: text,
        conversationHistory: [...conversationHistory, userMessage],
        context: widget.context,
      );

      // Save AI response
      final aiMessage = AIChatMessage(
        userId: user.userId,
        category: widget.category,
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );
      await _chatService.saveMessage(aiMessage);

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
            'Are you sure you want to clear all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserStreamProvider).value;
      if (user != null) {
        await _chatService.clearChatHistory(user.userId, widget.category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat history cleared')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final messagesStream =
        _chatService.getChatMessages(user.userId, widget.category);

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              'AI ${widget.category[0].toUpperCase()}${widget.category.substring(1)} Assistant'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<AIChatMessage>>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppTheme.mediumGray,
                          ),
                          ResponsiveConfig.heightBox(16),
                          Text(
                            'Start a conversation',
                            style: ResponsiveConfig.textStyle(
                              size: 18,
                              weight: FontWeight.bold,
                            ),
                          ),
                          ResponsiveConfig.heightBox(8),
                          Text(
                            'Ask me anything about ${widget.category}!',
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: ResponsiveConfig.padding(all: 16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildLoadingMessage();
                      }
                      return _buildMessageBubble(messages[index]);
                    },
                  );
                },
              ),
            ),
            if (!_isConfigured)
              Container(
                padding: ResponsiveConfig.padding(all: 12),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange),
                    ResponsiveConfig.widthBox(8),
                    Expanded(
                      child: Text(
                        'AI Assistant is not configured. Please contact support.',
                        style: ResponsiveConfig.textStyle(size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: ResponsiveConfig.padding(all: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: ResponsiveConfig.padding(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    ResponsiveConfig.widthBox(8),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: ResponsiveConfig.margin(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: AppTheme.primaryPink,
              ),
            ),
            ResponsiveConfig.widthBox(8),
          ],
          Flexible(
            child: Container(
              padding: ResponsiveConfig.padding(all: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryPink : AppTheme.softGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            ResponsiveConfig.widthBox(8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 18,
                color: AppTheme.primaryPink,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: ResponsiveConfig.margin(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: AppTheme.primaryPink,
            ),
          ),
          ResponsiveConfig.widthBox(8),
          Container(
            padding: ResponsiveConfig.padding(all: 12),
            decoration: BoxDecoration(
              color: AppTheme.softGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}
