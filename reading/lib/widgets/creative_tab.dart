import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';

class CreativeTab extends StatelessWidget {
  const CreativeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAF5FF), // purple-50
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 标题
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.call_split,
                      size: 16,
                      color: Color(0xFF6B21A8), // purple-900
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '平行宇宙分支',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '基于当前剧情点的 "What If" 模拟',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 分支卡片
            ...branchCards.map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BranchCard(branch: card),
                )),
            // 自定义分支按钮
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '自定义分支走向',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
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

class _BranchCard extends StatefulWidget {
  final BranchCard branch;

  const _BranchCard({required this.branch});

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _isExpanded = false;

  Color _getTagColor() {
    switch (widget.branch.color) {
      case 'purple':
        return const Color(0xFFE9D5FF); // purple-100
      case 'pink':
        return const Color(0xFFFCE7F3); // pink-100
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getTagTextColor() {
    switch (widget.branch.color) {
      case 'purple':
        return const Color(0xFF6B21A8); // purple-700
      case 'pink':
        return const Color(0xFFBE185D); // pink-700
      default:
        return Colors.grey[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTagColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.branch.tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTagTextColor(),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.branch.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.branch.desc,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.6,
              ),
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

