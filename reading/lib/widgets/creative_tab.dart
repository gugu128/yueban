import 'package:flutter/material.dart';
import 'package:reading/services/demo_data.dart';
import 'package:reading/utils/text_formatter.dart';

class CreativeTab extends StatefulWidget {
  final String bookId; // 'xyj' 或 'jane_eyre'
  
  const CreativeTab({super.key, this.bookId = 'xyj'});

  @override
  State<CreativeTab> createState() => _CreativeTabState();
}

class _CreativeTabState extends State<CreativeTab> {
  final TextEditingController _customInputController = TextEditingController();
  bool _showCustomInput = false;
  FanficBranch? _customBranch;

  @override
  void dispose() {
    _customInputController.dispose();
    super.dispose();
  }

  void _generateCustomBranch() {
    final text = _customInputController.text.trim();
    if (text.isEmpty) return;

    // 模拟AI生成自定义分支
    setState(() {
      _customBranch = FanficBranch(
        tag: '自定义分支',
        color: 'purple',
        title: text,
        content: '基于你的想法"$text"，AI正在生成一个全新的故事分支...\n\n（这里会显示AI生成的自定义分支内容，包括情节发展和结局分析）',
        analysis: '这是一个由你创意启发的全新分支，展现了故事的另一种可能性。',
      );
      _showCustomInput = false;
      _customInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果是论文模式，显示不支持此功能
    if (widget.bookId == 'paper') {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '本文不支持此功能',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '番外创作仅适用于小说类文本',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            // 分支卡片（根据bookId选择不同的数据）
            ...(widget.bookId == 'jane_eyre' ? janeEyreFanficBranches : fanficBranches)
                .map((branch) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BranchCard(branch: branch),
                    )),
            // 自定义生成的分支
            if (_customBranch != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BranchCard(branch: _customBranch!),
              ),
            // 自定义分支输入区域
            if (_showCustomInput) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '输入你的创意想法',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customInputController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: widget.bookId == 'jane_eyre' 
                            ? '例如：如果简·爱没有离开桑菲尔德...'
                            : '例如：如果悟空先去找牛魔王...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showCustomInput = false;
                              _customInputController.clear();
                            });
                          },
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _generateCustomBranch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('生成分支'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 自定义分支按钮
            GestureDetector(
              onTap: () {
                setState(() {
                  _showCustomInput = !_showCustomInput;
                });
              },
              child: Container(
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
                    Icon(
                      _showCustomInput ? Icons.close : Icons.edit_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showCustomInput ? '取消输入' : '自定义分支走向',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
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
}

class _BranchCard extends StatefulWidget {
  final FanficBranch branch;

  const _BranchCard({required this.branch});

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _showContent = false;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 假设标题卡片（点击后展开）
        GestureDetector(
          onTap: () {
            setState(() {
              _showContent = !_showContent;
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
            child: Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.branch.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Icon(
                  _showContent ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        // 续写内容卡片（点击后显示）
        if (_showContent) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                    Icon(
                      Icons.auto_stories,
                      size: 16,
                      color: _getTagTextColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI续写内容',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getTagTextColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildFormattedText(
                  widget.branch.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 14,
                            color: _getTagTextColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '结局分析',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getTagTextColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      buildFormattedText(
                        widget.branch.analysis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

