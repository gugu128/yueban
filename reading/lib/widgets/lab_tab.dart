import 'package:flutter/material.dart';
import 'package:reading/models/book_content.dart';
import 'package:reading/services/demo_data.dart';
import 'package:reading/utils/text_formatter.dart';

class LabTab extends StatefulWidget {
  const LabTab({super.key});

  @override
  State<LabTab> createState() => _LabTabState();
}

class _LabTabState extends State<LabTab> {
  final TextEditingController _inputController = TextEditingController();
  bool _hasGenerated = false;
  CitationEvidence? _selectedCitation;

  // 模拟的引用数据（结合实际内容）
  final List<CitationEvidence> _citations = [
    CitationEvidence(
      index: 1,
      sourceText: '罗刹女见行者厉害，便将芭蕉扇一扇，顿时狂风大作，飞沙走石。行者一时不防，被扇得在空中乱转，如纺车一般，直飘到小须弥山，方才止住。\n\n行者稳住身形，心中暗道："好厉害的扇子！我须得想个法子，定住她。"行者想起灵吉菩萨曾言，此地有个定风丹，可定狂风。\n\n行者便驾云去找灵吉菩萨，求得定风丹，含在口中。再至芭蕉洞，罗刹女见行者又来，大怒，举起芭蕉扇，连扇数下，狂风大作，但行者却如定身一般，毫不动摇。',
      pageNumber: 3,
      paragraphIndex: 5,
      chapterTitle: '第五十九回 唐三藏路阻火焰山 孙行者一调芭蕉扇',
      contentBlockIndex: 33,
      derivedConclusion: '悟空面对铁扇公主的拒绝和考验，没有放弃，而是寻找解决之道（如定风丹）。这体现了在面对困难时，应该主动寻找工具和方法，而不是被动接受失败。',
    ),
    CitationEvidence(
      index: 2,
      sourceText: '行者闻言，急抽身走入里面，将糕递与三藏道："师父放心，且莫焦恼，如今天色又晚，且坐在这边略略歇待，等我去问铁扇仙借扇子去。"\n\n三藏闻言道："火焰山却在那边？可阻西去之路？"老者道："西方却去不得。那山离此有六十里远，正是西方必由之路，却有八百里火焰，四周围寸草不生。若过得山，就是铜脑盖，铁身躯，也要化成汁哩。"\n\n行者道："这里有座翠云山，山中有一仙洞，名唤芭蕉洞，洞里有位铁扇仙，又名罗刹女。我这里人家，十年拜求一度。四猪四羊，花红表里，异香时果，鸡鹅美酒，沐浴虔诚，拜到那仙山，请他出洞，至此施为。"',
      pageNumber: 2,
      paragraphIndex: 8,
      chapterTitle: '第五十九回 唐三藏路阻火焰山 孙行者一调芭蕉扇',
      contentBlockIndex: 19,
      derivedConclusion: '不要被表面的拒绝吓退。悟空遇到困难时，会寻找工具和方法（定风丹）。在面对看似不可能的挑战时，应该分析问题的本质，寻找相应的资源和策略，而不是直接放弃。',
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateAdvice() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      // 如果没有输入，使用默认的示例内容
      _inputController.text = '最近数学太难了，我爸妈收走了我的手机，我气得和他们大吵一架，现在冷战两天了。我想摆烂，不想复习了。';
    }
    setState(() {
      _hasGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFECFDF5), // emerald-50
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 18,
                  color: Color(0xFF065F46), // emerald-700
                ),
                const SizedBox(width: 8),
                const Text(
                  '知识迁移与应用',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 输入卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前生活困境',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤔', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: '最近觉得工作很迷茫，不知道要不要跳槽去大城市...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateAdvice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // emerald-600
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '生成书中建议',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_hasGenerated) ...[
              const SizedBox(height: 24),
              // CoT步骤和结果卡片
              Stack(
                children: [
                  // 时间线
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
                  // 内容
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Column(
                      children: [
                        ...cotAdviceData.steps.map((step) => _buildCotStep(
                          step: step.step,
                          title: step.title,
                          content: step.content,
                          isExpanded: true,
                        )),
                        _buildResultCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
        if (_selectedCitation != null) ...[_buildCitationPopup()!],
      ],
    );
  }

  Widget _buildCotStep({
    required int step,
    required String title,
    required String content,
    required bool isExpanded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                buildFormattedText(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间点
          Stack(
            children: [
              Positioned(
                left: -40,
                top: 16,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // emerald-500
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 咨询师正在思考...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFormattedText(
                          cotAdviceData.finalAdvice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF065F46),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flag,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '行动指令：${cotAdviceData.actionCommand}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建带引用标注的文本
  Widget _buildTextWithCitations(String text) {
    final regex = RegExp(r'\[(\d+)\]');
    final parts = <InlineSpan>[];
    int lastEnd = 0;

    for (var match in regex.allMatches(text)) {
      // 添加匹配前的文本
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ));
      }

      // 添加引用标注（右上角上标）
      final citationIndex = int.parse(match.group(1)!);
      final citation = _citations.firstWhere(
        (c) => c.index == citationIndex,
        orElse: () => _citations[0],
      );

      parts.add(WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedCitation = citation;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(left: 2, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '[$citationIndex]',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // 添加剩余的文本
    if (lastEnd < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          height: 1.5,
        ),
      ));
    }

    return RichText(text: TextSpan(children: parts));
  }

  // 构建引用浮窗（屏幕中心显示）
  Widget? _buildCitationPopup() {
    if (_selectedCitation == null) return null;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCitation = null;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击穿透
              child: Container(
                margin: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          const Row(
                            children: [
                              Icon(Icons.source, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                '原文依据',
                          style: TextStyle(
                                  fontSize: 18,
                            fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                            ],
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedCitation = null;
                            });
                          },
                            icon: const Icon(Icons.close, size: 20, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    ),
                    // 内容区
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 来源信息
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                              child: Row(
                                children: [
                                  const Icon(Icons.book, size: 16, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCitation!.chapterTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '第${_selectedCitation!.pageNumber}页 · 第${_selectedCitation!.paragraphIndex}段',
                                          style: const TextStyle(
                              fontSize: 11,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                            ),
                          ),
                        ],
                      ),
                    ),
                            const SizedBox(height: 20),
                            // 原文内容
                            const Row(
                              children: [
                                Icon(Icons.description, size: 16, color: Color(0xFF6B7280)),
                                SizedBox(width: 8),
                                Text(
                                  '原文内容',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                    const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                _selectedCitation!.sourceText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                                  height: 1.8,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 推导过程
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFECFDF5),
                                    Color(0xFFD1FAE5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.psychology, size: 16, color: Color(0xFF065F46)),
                                      SizedBox(width: 8),
                                      Text(
                                        'AI推导过程',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 4, right: 12),
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            _selectedCitation!.derivedConclusion,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF065F46),
                        height: 1.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
