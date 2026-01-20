import 'package:flutter/material.dart';
import 'package:reading/models/book_content.dart';
import 'package:reading/widgets/chat_tab.dart';
import 'package:reading/widgets/graph_tab.dart';
import 'package:reading/widgets/lab_tab.dart';
import 'package:reading/widgets/creative_tab.dart';

class AIDashboard extends StatefulWidget {
  final bool isVisible;
  final Role currentRole;
  final List<Role> selectedCompanions;
  final bool isGroupMode;
  final String bookId; // 当前书目：xyj / jane_eyre / paper
  final String injectedTab; // 默认显示的 tab
  final String? injectedQuote; // 从正文划词传入的引用
  final int quoteVersion; // 引用变更序号
  final VoidCallback onClose;
  final Function(Role) onRoleChanged;
  final Function(bool)? onGroupModeToggle;

  const AIDashboard({
    super.key,
    required this.isVisible,
    required this.currentRole,
    this.selectedCompanions = const [],
    this.isGroupMode = false,
    this.injectedTab = 'chat',
    this.injectedQuote,
    this.quoteVersion = 0,
    required this.onClose,
    required this.onRoleChanged,
    this.onGroupModeToggle,
    this.bookId = 'xyj',
  });

  @override
  State<AIDashboard> createState() => _AIDashboardState();
}

class _AIDashboardState extends State<AIDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late String activeTab;
  String? pendingQuote;
  int lastQuoteVersion = 0;

  @override
  void initState() {
    super.initState();
    activeTab = widget.injectedTab;
    pendingQuote = widget.injectedQuote;
    lastQuoteVersion = widget.quoteVersion;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AIDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当父组件“明确注入的 tab”发生变化时，才强制切换；
    // 避免键盘弹出等导致父组件 rebuild 时把用户手动切到的 tab 又切回去。
    if (widget.injectedTab != oldWidget.injectedTab && widget.injectedTab != activeTab) {
      activeTab = widget.injectedTab;
    }
    if (widget.quoteVersion != lastQuoteVersion) {
      lastQuoteVersion = widget.quoteVersion;
      pendingQuote = widget.injectedQuote;
    }
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _controller.value == 0) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // 把手
            GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Tabs 导航
            _buildTabBar(),
            // Tab 内容区
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
      final tabs = [
        {'id': 'chat', 'label': '伴读', 'icon': Icons.message_outlined},
        {'id': 'ai_helper', 'label': 'AI陪读', 'icon': Icons.smart_toy_outlined},
        {'id': 'deep', 'label': '深度探讨', 'icon': Icons.psychology_alt_outlined},
        {'id': 'graph', 'label': '图谱', 'icon': Icons.account_tree},
        {'id': 'lab', 'label': '实验室', 'icon': Icons.work_outline},
        {'id': 'create', 'label': '番外', 'icon': Icons.call_split},
      ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  activeTab = tab['id'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 20,
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF4F46E5)
                            : Colors.grey[400],
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 32,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (activeTab) {
      case 'chat':
        return ChatTab(
          currentRole: widget.currentRole,
          selectedCompanions: widget.selectedCompanions,
          isGroupMode: widget.isGroupMode,
          onRoleChanged: widget.onRoleChanged,
          onGroupModeToggle: widget.onGroupModeToggle,
        );
      case 'graph':
        return GraphTab(bookId: widget.bookId);
      case 'lab':
        return const LabTab();
      case 'create':
        return CreativeTab(bookId: widget.bookId);
      case 'ai_helper':
        return AIReadingCompanionTab(
          injectedQuote: pendingQuote,
          quoteVersion: lastQuoteVersion,
        );
      case 'deep':
        return DeepDiveTab(
          injectedQuote: pendingQuote,
          quoteVersion: lastQuoteVersion,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class AIReadingCompanionTab extends StatefulWidget {
  final String? injectedQuote;
  final int quoteVersion;

  const AIReadingCompanionTab({
    super.key,
    this.injectedQuote,
    this.quoteVersion = 0,
  });

  @override
  State<AIReadingCompanionTab> createState() => _AIReadingCompanionTabState();
}

class _AIReadingCompanionTabState extends State<AIReadingCompanionTab> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final List<_SimpleMessage> _messages = [
    _SimpleMessage(
      sender: 'AI小伴读',
      content: '你好，我是 AI 陪读。引用任意原文句子并发问，我会结合引用快速解释。',
    ),
  ];
  int _lastQuoteVersion = 0;
  int _nextCitationIndex = 1;

  @override
  void dispose() {
    _quoteController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AIReadingCompanionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quoteVersion != _lastQuoteVersion && widget.injectedQuote != null) {
      _lastQuoteVersion = widget.quoteVersion;
      _quoteController.text = widget.injectedQuote!;
      // 提示已插入引用
      setState(() {
        _messages.add(_SimpleMessage(
          sender: 'AI小伴读',
          content: '已插入你刚才选中的原文，将随之后的提问一起发送。',
          quote: widget.injectedQuote,
        ));
      });
    }
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final quote = _quoteController.text.trim().isEmpty ? null : _quoteController.text.trim();

    setState(() {
      _messages.add(_SimpleMessage(sender: '我', content: text, quote: quote, isUser: true));
      _messages.add(_SimpleMessage(
        sender: 'AI小伴读',
        content: _aiReply(text, quote),
        quote: quote,
        citationIndex: quote == null || quote.isEmpty ? null : _nextCitationIndex++,
      ));
    });
    _inputController.clear();
  }

  String _aiReply(String user, String? quote) {
    final q = (quote ?? '').trim();
    final hasQuote = q.isNotEmpty;
    final quoteLine = hasQuote ? '引用：$q\n\n' : '';

    String normalize(String s) => s.replaceAll('“', '').replaceAll('”', '').replaceAll('：', ':').trim();
    final nq = normalize(q);
    final nu = normalize(user);

    bool askMeaning() => nu.contains('什么意思') || nu.contains('意思') || nu.contains('怎么理解');
    bool askAppreciation() => nu.contains('赏析') || nu.contains('分析') || nu.contains('解读');
    bool askFunction() => nu.contains('作用') || nu.contains('有什么用') || nu.contains('起什么作用');

    // 示例段落 1：景物诗
    final isPoem1 = nq.contains('薄云断绝西风紧') || nq.contains('鹤鸣远岫霜林锦') || nq.contains('山长水更长');
    // 示例段落 2：老者出场 + 叠词描写
    final isOldMan = nq.contains('穿一领黄不黄') || nq.contains('红不红的葛布深衣') || nq.contains('篾丝凉帽') || nq.contains('暴节竹杖');

    if (!hasQuote) {
      return '你还没有引用原文哦～先在上方“当前引用”里粘贴/自动带入一段原文，再问我「什么意思/赏析/有什么作用」之类的问题，我会结合引用回答。';
    }

    if (isPoem1) {
      if (askMeaning() && !askAppreciation()) {
        return '${quoteLine}这段是用一连串意象写“秋寒苍凉、旅途孤寂”。大意是：西风劲、薄云散，远山鹤鸣，霜林像锦；景色清冷，山路漫长、水路更长；大雁从北塞飞来，玄鸟向南陌归去；客途让人怯于孤单，出家人的衲衣也难御寒。\n\n一句话：写景写到骨子里，落脚在“行路人的清冷与孤独”。';
      }
      if (askAppreciation() || askFunction()) {
        return '${quoteLine}赏析要点（也可理解为它的“作用”）：\n1) **意象群铺陈**：薄云/西风/鹤鸣/霜林/征鸿/玄鸟，把“秋”写得有声有色有温度（冷）。\n2) **由景入情**：前半纯景，后半一句“客路怯孤单，衲衣容易寒”突然点出人物处境与心理，景变成情的证据。\n3) **节奏感**：短句对偶、层层递进（天—山—水—雁—人），读起来像镜头推远再推近。\n\n综合作用：在叙事前先立气氛——“苍凉 + 孤旅”，为后面行路艰辛、遇事生变做情绪铺垫。';
      }
      // 兜底
      return '${quoteLine}我能从两条线回答：\n- 想问“什么意思”：我会翻译成白话并解释意象。\n- 想问“赏析/作用”：我会从意象、节奏、情绪推进、叙事功能来拆。\n\n你这句更想要哪一种？';
    }

    if (isOldMan) {
      if (askMeaning() && !askAppreciation()) {
        return '${quoteLine}这段是描写一个老者突然出场的外貌与行头。“黄不黄、红不红”“青不青、皂不皂”“弯不弯、直不直”“新不新、旧不旧”这些叠词，是在说：他的衣帽器物颜色暧昧、陈旧朴素，竹杖疙瘩暴节、形状不齐，鞋子也半新半旧。\n\n一句话：写出他风尘仆仆、寒酸朴素、身份不显却有几分怪异的气质。';
      }
      if (askAppreciation() || askFunction()) {
        return '${quoteLine}赏析/作用可以抓住“叠词 + 反差感”：\n1) **叠词制造画面感**：一连串“X不X”的颜色/形状/新旧，把人物写得立体、具体，像镜头扫过全身。\n2) **气质暗示**：半新半旧、颜色不正，既显清贫又显行旅；竹杖暴节、形态不齐，带点“怪”“硬”的气。\n3) **铺垫身份与戏剧性**：这种“不确定”的描写让读者好奇：他是谁？为何如此？为后续情节埋钩子。\n\n如果你愿意，我还能顺着这段推测：作者在用“外貌不整齐”来暗示他将带来不整齐的消息/变故。';
      }
      return '${quoteLine}你是想要白话翻译（什么意思），还是更偏“赏析/作用/写法”？你说一句我就按那种格式继续。';
    }

    // 通用回答：没有命中示例段落时
    if (askMeaning() && !askAppreciation()) {
      return '${quoteLine}我先给你白话翻译：\n- 逐句：把关键词拆开解释\n- 整体：总结这段在说什么\n\n你也可以补一句：你卡在哪个词/哪一句？我会更精确。';
    }
    if (askAppreciation() || askFunction()) {
      return '${quoteLine}我从“写法—情绪—作用”三层来赏析：\n1) 写法：用了哪些修辞/节奏/意象\n2) 情绪：让读者感到什么\n3) 作用：在章节里起铺垫/转折/塑造人物/推动冲突的哪一种\n\n你希望我更偏文学赏析，还是更偏情节作用？';
    }
    return '${quoteLine}收到。你可以直接问我：\n- 「这段什么意思？」（白话翻译）\n- 「请赏析这段话」或「这段有什么作用？」（写法/情绪/功能）\n我会按你选择的方向回答。';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('AI陪读', '即时问答 · 可多次引用不同段落'),
        _quoteBox(
          controller: _quoteController,
          label: '当前引用（仅支持从正文点击自动带入）',
          readOnly: true,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _MessageBubble(
              message: _messages[i],
              onCitationTap: _showCitation,
            ),
          ),
        ),
        _inputBar(
          controller: _inputController,
          hint: '向 AI 发问，引用会随本次消息一起发出',
          onSend: _send,
        ),
      ],
    );
  }

  void _showCitation(_SimpleMessage message) {
    if (message.citationIndex == null || message.quote == null || message.quote!.trim().isEmpty) {
      return;
    }
    _showAiCitationDialog(
      context: context,
      message: message,
      title: 'AI陪读 · 精准溯源 [${message.citationIndex}]',
    );
  }
}

class DeepDiveTab extends StatefulWidget {
  final String? injectedQuote;
  final int quoteVersion;

  const DeepDiveTab({
    super.key,
    this.injectedQuote,
    this.quoteVersion = 0,
  });

  @override
  State<DeepDiveTab> createState() => _DeepDiveTabState();
}

class _DeepDiveTabState extends State<DeepDiveTab> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final List<_SimpleMessage> _messages = [
    _SimpleMessage(
      sender: 'AI深度探讨',
      content: '先指定一个段落，我会围绕它持续追问与拆解。要换观点，点“开启新的深度探讨”。',
    ),
  ];
  String? _activeQuote;
  int _lastQuoteVersion = 0;
  int _nextCitationIndex = 1;

  @override
  void dispose() {
    _quoteController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DeepDiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quoteVersion != _lastQuoteVersion && widget.injectedQuote != null) {
      _lastQuoteVersion = widget.quoteVersion;
      _quoteController.text = widget.injectedQuote!;
      _startDeepDive(auto: true);
    }
  }

  void _startDeepDive({bool auto = false}) {
    final quote = _quoteController.text.trim();
    if (quote.isEmpty) return;
    setState(() {
      _activeQuote = quote;
      _messages
        ..clear()
        ..add(_SimpleMessage(
          sender: 'AI深度探讨',
          content: auto
              ? '已自动锁定你刚才选中的原文：$quote\n\n我会围绕它持续提问与分析，除非你开启新的深度探讨。'
              : '已锁定引用：$quote\n\n我会围绕它持续提问与分析，除非你开启新的深度探讨。',
          quote: quote,
          citationIndex: _nextCitationIndex++,
        ));
    });
  }

  void _send() {
    if (_activeQuote == null) return;
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_SimpleMessage(sender: '我', content: text, isUser: true, quote: _activeQuote));
      _messages.add(_SimpleMessage(
        sender: 'AI深度探讨',
        content: _deepReply(text, _activeQuote!),
        quote: _activeQuote,
        citationIndex: _nextCitationIndex++,
      ));
    });
    _inputController.clear();
  }

  String _deepReply(String user, String quote) {
    String normalize(String s) => s.replaceAll('“', '').replaceAll('”', '').replaceAll('：', ':').trim();
    final nq = normalize(quote);
    final nu = normalize(user);
    final isPoem1 = nq.contains('薄云断绝西风紧') || nq.contains('鹤鸣远岫霜林锦') || nq.contains('山长水更长');
    final isOldMan = nq.contains('穿一领黄不黄') || nq.contains('红不红的葛布深衣') || nq.contains('篾丝凉帽') || nq.contains('暴节竹杖');

    if (isPoem1) {
      return '引用段落：$quote\n\n我先抛 3 个问题引导你思考（你可以逐个答）：\n1) **情绪从哪来**：你觉得“冷”主要来自天气（西风/霜林）还是来自处境（客路孤单/衲衣易寒）？\n2) **镜头怎么走**：这段从“天象”写到“飞鸟”再落到“人”，这种推进对你有什么阅读感受？\n3) **叙事功能**：如果把这段删掉，后面的“行路/遭遇”会少掉什么？\n\n我的示范答案（供你对照）：它用景物把“孤旅与苍凉”提前灌进读者心里，让后续剧情更有重量。\n\n你刚才说：「$nu」——你更同意第 1 点（情绪）还是第 3 点（功能）？';
    }

    if (isOldMan) {
      return '引用段落：$quote\n\n引导问题（你选 1-2 个回答）：\n1) **叠词的效果**：反复“X不X”让你感觉这个人更真实，还是更神秘？为什么？\n2) **身份猜测**：仅凭衣帽器物的“不正”“不齐”，你会把他归为哪一类人（贫寒/行旅/隐士/怪人）？\n3) **作者动机**：作者为什么不直接说“衣服旧、帽子旧”，而要绕这么一圈？\n\n我的示范答案：这种写法像“打灯”，用不确定性把人物照得更立体，也顺便吊起读者的好奇，给后文埋钩子。\n\n你刚才说：「$nu」——你更想从“写法技巧”聊，还是从“剧情作用”聊？';
    }

    return '引用段落：$quote\n\n我会按“文本细节 → 作者选择 → 读者感受 → 情节/主题作用”来带你。\n\n先问你 2 个问题：\n1) 这段里你觉得最关键的一个词/一句是哪一个？为什么？\n2) 你读完的第一情绪是：紧张/悲凉/好笑/敬畏/别的？\n\n我的初步解读：这段很可能在用细节（意象/动作/口吻）塑造人物或铺垫冲突。\n\n你先回答第 1 个问题，我再顺着你的答案继续追问并给出对应分析。';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('深度探讨', '从正文点“深度探讨”后，我会围绕该段持续追问'),
        _quoteBox(
          controller: _quoteController,
          label: '要探讨的段落/观点（仅支持从正文点击“深度探讨”自动带入）',
          readOnly: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _startDeepDive,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(_activeQuote == null ? '开启新的深度探讨' : '重新开启并锁定新观点'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _MessageBubble(
              message: _messages[i],
              onCitationTap: _showCitation,
            ),
          ),
        ),
        _inputBar(
          controller: _inputController,
          hint: _activeQuote == null ? '先填上方引用，再开始对话' : '围绕当前引用继续探讨...',
          onSend: _send,
          enabled: _activeQuote != null,
        ),
      ],
    );
  }

  void _showCitation(_SimpleMessage message) {
    if (message.citationIndex == null || message.quote == null || message.quote!.trim().isEmpty) {
      return;
    }
    _showAiCitationDialog(
      context: context,
      message: message,
      title: '深度探讨 · 精准溯源 [${message.citationIndex}]',
    );
  }
}

class _SimpleMessage {
  final String sender;
  final String content;
  final String? quote;
  final bool isUser;
  final int? citationIndex;

  _SimpleMessage({
    required this.sender,
    required this.content,
    this.quote,
    this.isUser = false,
    this.citationIndex,
  });
}

class _MessageBubble extends StatelessWidget {
  final _SimpleMessage message;
  final void Function(_SimpleMessage message)? onCitationTap;

  const _MessageBubble({required this.message, this.onCitationTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.sender,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUser ? const Color(0xFF4338CA) : const Color(0xFF111827),
              ),
            ),
            if (message.quote != null && message.quote!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Text(
                  message.quote!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
            const SizedBox(height: 6),
            _buildContentWithCitation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContentWithCitation(BuildContext context) {
    final baseStyle = const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2937));
    final hasCitation = !message.isUser &&
        message.citationIndex != null &&
        message.quote != null &&
        message.quote!.trim().isNotEmpty &&
        onCitationTap != null;

    if (!hasCitation) {
      return Text(message.content, style: baseStyle);
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: message.content),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () => onCitationTap?.call(message),
              child: Container(
                margin: const EdgeInsets.only(left: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '[${message.citationIndex}]',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAiCitationDialog({
  required BuildContext context,
  required _SimpleMessage message,
  required String title,
}) {
  // 在追溯弹窗里，我们只展示“溯源原文 + AI 的思考过程”，
  // 不再把整段答案原封不动塞进来，避免用户感觉是在重复阅读同一段内容。
  String _buildReasoning() {
    final quote = (message.quote ?? '').trim();
    final answer = message.content.trim();
    final hasQuote = quote.isNotEmpty;

    final List<String> lines = [];

    if (hasQuote) {
      lines.add('1. 先把你选中的原文当作「唯一可靠的依据」，确认回答必须围绕这段话展开。');
      lines.add('2. 从原文里抓关键词（意象、情绪词、人物动作或修辞结构），判断它主要在写景、写人还是推进情节。');
      lines.add('3. 再对照你的问题，在这些关键词允许的范围内组织回答，尽量避免编造原文中不存在的细节。');
    } else {
      lines.add('1. 当前这条记录没有检测到明显的原文引用，只能把你的提问本身当作主要信息源。');
      lines.add('2. 我会从问题里的关键词推断你是在问「字面意思」「赏析」还是「情节作用」，再选择相应的回答结构。');
    }

    lines.add('4. 生成答案后，会再对照原文做一轮自检：如果发现推断与原文明显不符，按设计应优先以原文为准，并在后续对话中纠正。');

    // 如果回答本身很短，可以作为「推理的示例结果」简单带一句，但不整段贴出。
    if (answer.isNotEmpty && answer.length <= 80) {
      lines.add('（本次回答的大意是：$answer）');
    }

    return lines.join('\n');
  }

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '溯源原文',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.quote ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF111827),
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '推理路径（AI 如何从原文走到这条回答）',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                        const SizedBox(height: 8),
                      Text(
                        _buildReasoning(),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _sectionHeader(String title, String subtitle) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        _pill(subtitle),
      ],
    ),
  );
}

Widget _quoteBox({
  required TextEditingController controller,
  required String label,
  bool readOnly = false,
}) {
  final text = controller.text.trim();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: readOnly
              ? SelectableText(
                  text.isEmpty ? '（等待从正文自动引用）' : text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: text.isEmpty ? Colors.grey[500] : const Color(0xFF0F172A),
                  ),
                )
              : TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: null,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '输入你在正文选中的句子或观点',
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
        ),
      ],
    ),
  );
}

Widget _inputBar({
  required TextEditingController controller,
  required String hint,
  required VoidCallback onSend,
  bool enabled = true,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 48, width: 12),
        GestureDetector(
          onTap: enabled ? onSend : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF4F46E5) : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ),
      ],
    ),
  );
}

Widget _pill(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE0E7FF),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF4338CA),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

