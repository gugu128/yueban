import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart' as mock_data;
import 'package:reading/services/demo_data.dart';
import 'package:reading/models/book_content.dart';
import 'package:reading/utils/text_formatter.dart';

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({
    required this.content,
    this.isUser = false,
  });
}

class IntentScreen extends StatefulWidget {
  final Function(String) onConfirm;

  const IntentScreen({super.key, required this.onConfirm});

  @override
  State<IntentScreen> createState() => _IntentScreenState();
}

class _IntentScreenState extends State<IntentScreen> {
  String? selectedIntent;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  bool _hasReceivedReply = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 添加用户消息
    setState(() {
      _chatMessages.add(ChatMessage(
        content: text,
        isUser: true,
      ));
    });

    _textController.clear();

    // 检查是否是备考请求
    if (text.contains('备考') || text.contains('学习') || text.contains('考试')) {
      setState(() {
        selectedIntent = 'exam'; // 自动选择备考意图
      });
    }

    // AI回复
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
            content: aiWelcomeMessage,
            isUser: false,
          ));
          _hasReceivedReply = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '这次阅读的目的是？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI 将根据你的意图，调整伴读策略与性格。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // 聊天区域
          if (_chatMessages.isNotEmpty) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: message.isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!message.isUser) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  '🤖',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: buildFormattedText(
                                message.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: message.isUser
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                          if (message.isUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // 意图选项（只在没有聊天消息时显示）
            Expanded(
              child: ListView.separated(
                itemCount: mock_data.readingIntents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final intent = mock_data.readingIntents[index];
                  final isSelected = selectedIntent == intent.id;
                  return _IntentCard(
                    intent: intent,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedIntent = intent.id;
                      });
                    },
                  );
                },
              ),
            ),
          ],
          // AI 对话式输入
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.message_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _chatMessages.isEmpty
                          ? '或者直接告诉我，如"我想学习这个情节备考"'
                          : '继续对话...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 开始按钮（在收到AI回复后或选择了意图后可用）
          // 即使没有选择意图卡片，只要用户有输入并收到AI回复，就可以点击
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_hasReceivedReply || selectedIntent != null)
                  ? () {
                      // 如果没有选择意图，使用默认的'fun'（休闲娱乐）
                      widget.onConfirm(selectedIntent ?? 'fun');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: (_hasReceivedReply || selectedIntent != null) ? 8 : 0,
              ),
              child: const Text(
                '开始深度阅读',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  final ReadingIntent intent;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntentCard({
    required this.intent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                intent.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intent.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF312E81) : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intent.desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.5,
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
}

