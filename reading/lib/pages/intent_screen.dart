import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';

class IntentScreen extends StatefulWidget {
  final Function(String) onConfirm;

  const IntentScreen({super.key, required this.onConfirm});

  @override
  State<IntentScreen> createState() => _IntentScreenState();
}

class _IntentScreenState extends State<IntentScreen> {
  String? selectedIntent;
  final TextEditingController _textController = TextEditingController();
  bool showWelcomeMessage = false;

  // AI欢迎语内容
  final String welcomeMessage = '''好的，收到！📚

针对中考名著备考，这一回（第五十九回）绝对是重难点区域。我已经为你开启了**"考点雷达"模式**，会在接下来的阅读中重点标注核心情节冲突和人物性格分析。

准备好了吗？那让我们开始阅读吧！🚀''';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkInput() {
    final text = _textController.text.trim().toLowerCase();
    if (text.contains('备考') || text.contains('学习') || text.contains('考试')) {
      setState(() {
        showWelcomeMessage = true;
        selectedIntent = 'exam'; // 自动选择备考意图
      });
    } else {
      setState(() {
        showWelcomeMessage = false;
      });
    }
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
          // 意图选项
          Expanded(
            child: ListView.separated(
              itemCount: readingIntents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final intent = readingIntents[index];
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
                      hintText: '或者直接告诉我，如"为了解决和同事吵架"',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                    onChanged: (_) => _checkInput(),
                  ),
                ),
              ],
            ),
          ),
          // AI欢迎语
          if (showWelcomeMessage) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      welcomeMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 开始按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedIntent != null
                  ? () => widget.onConfirm(selectedIntent!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: selectedIntent != null ? 8 : 0,
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

