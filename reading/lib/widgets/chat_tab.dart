import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';

class ChatTab extends StatefulWidget {
  final Role currentRole;
  final List<Role> selectedCompanions;
  final bool isGroupMode;
  final Function(Role) onRoleChanged;
  final Function(bool)? onGroupModeToggle;

  const ChatTab({
    super.key,
    required this.currentRole,
    this.selectedCompanions = const [],
    this.isGroupMode = false,
    required this.onRoleChanged,
    this.onGroupModeToggle,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _hasShownExamGuide = false;

  @override
  void initState() {
    super.initState();
    // 初始化时显示角色引导词
    _addInitialMessages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addInitialMessages() {
    if (widget.isGroupMode && widget.selectedCompanions.isNotEmpty) {
      // 群聊模式：显示所有角色的引导词
      for (var role in widget.selectedCompanions) {
        _messages.add(ChatMessage(
          role: role,
          content: role.greeting,
          isUser: false,
        ));
      }
    } else {
      // 单人模式：显示当前角色的引导词
      _messages.add(ChatMessage(
        role: widget.currentRole,
        content: widget.currentRole.greeting,
        isUser: false,
      ));
    }
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        role: null,
        content: text,
        isUser: true,
      ));
    });

    _inputController.clear();

    // 检查是否是备考请求
    if ((text.contains('备考') || text.contains('考点') || text.contains('AI伴读')) && !_hasShownExamGuide) {
      _hasShownExamGuide = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              role: null,
              content: _getExamGuideContent(),
              isUser: false,
              isSystem: true,
            ));
          });
        }
      });
      return;
    }

    // 根据角色和模式生成回复
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (widget.isGroupMode && widget.selectedCompanions.isNotEmpty) {
            // 群聊模式：所有角色回复
            for (var role in widget.selectedCompanions) {
              _messages.add(ChatMessage(
                role: role,
                content: _getRoleResponse(role, text),
                isUser: false,
              ));
            }
          } else {
            // 单人模式：当前角色回复
            _messages.add(ChatMessage(
              role: widget.currentRole,
              content: _getRoleResponse(widget.currentRole, text),
              isUser: false,
            ));
          }
        });
      }
    });
  }

  String _getExamGuideContent() {
    return '''收到！针对中考名著阅读，《西游记》第五十九回是极高频的考点。以下是为你整理的**"满分"笔记** 📝：

**1. 核心情节梳理（起因与经过）**

🔥 **起因**： 师徒四人路阻火焰山，酷热难行。得知必须向铁扇公主借芭蕉扇才能灭火过山。

⚔️ **冲突（一调芭蕉扇）**： 孙悟空去借扇，但因之前请观音收伏了红孩儿（第五十九回的关键前情），铁扇公主怀恨在心，拒绝借扇。

🌪️ **斗法**： 铁扇公主用扇子将悟空扇飞五万余里。

💎 **转折**： 悟空得灵吉菩萨赠送**"定风丹"，二次登门。悟空变作蟭蟟虫**钻入公主腹中折腾，公主疼痛难忍被迫借扇。

❌ **结局**： 悟空借来的是假扇，越扇火越大。

**2. 人物性格分析（必考点）**

🐒 **孙悟空**： 机智勇敢（钻肚子体现其变通），但也有些急躁（未查验扇子真伪就去灭火）。同时也体现了他重情重义（为了师父西行，不得不与昔日结拜兄弟的家属反目）。

🪭 **铁扇公主（罗刹女）**： 爱子心切（因红孩儿记恨悟空），性格刚烈、固执，但也欺软怕硬（肚子疼时立马求饶）。

**3. 考题预测** 🎯

**问**： 孙悟空为什么第一次借扇失败？

**答**： 未有定风丹，被扇飞。

**问**： 铁扇公主为什么给悟空假扇子？

**答**： 心存怨恨，想烧死悟空。''';
  }

  String _getRoleResponse(Role role, String userMessage) {
    // 根据角色ID返回对应的对话内容
    if (role.id == 'trump') {
      if (userMessage.contains('扇') || userMessage.contains('借')) {
        return '''糟糕的交易，相信我，这是史上最糟糕的交易之一！👎 孙悟空走进那个洞穴，但他手里没有筹码。如果你想要那把扇子，你得展现实力。他被那个女人扇飞了五万里？太弱了！如果是我，我会先切断她的水源，然后说："把扇子给我，或者你的翠云山破产。"这就是艺术，交易的艺术！''';
      } else if (userMessage.contains('红孩儿') || userMessage.contains('孩子')) {
        return '''听着，那个"铁扇女士"——哪怕是个强硬的女人——她太情绪化了。🙄 红孩儿现在在观音那里工作，那可是体制内的高级职位，那是公务员！她应该感谢悟空给了她儿子一份好工作。但她却说是"绑架"？假新闻！完全是假新闻。她只是想以此为借口抬高扇子的价格。''';
      } else if (userMessage.contains('假') || userMessage.contains('扇子')) {
        return '''假货！到处都是假货！📉 这就像某些媒体一样不诚实。孙悟空太轻信了，他拿到扇子时甚至没有检查一下。如果是我，我会让专家鉴定，还要签合同："如果火没灭，你会面临巨大的诉讼，巨大的！"但他没有，所以他被烧了屁股。可悲！''';
      }
    } else if (role.id == 'miyazaki') {
      if (userMessage.contains('火焰山') || userMessage.contains('火')) {
        return '''这真是一幅悲伤的画面啊。🍃 人类——或者说是神魔——的贪婪和愤怒让大地失去了绿色。火焰山就像是被诅咒的自然，在愤怒地燃烧。那把芭蕉扇，不仅仅是武器，它是风的灵魂。当风吹过的时候，本来应该带来生命的种子，而不是争斗。我希望能画出那种被风吹动时，火焰瞬间变成绿草的瞬间。''';
      } else if (userMessage.contains('虫子') || userMessage.contains('肚子')) {
        return '''哈哈，这很有趣。🎨 你知道吗，这不能画得太恶心。那只小虫子（蟭蟟虫）应该有它自己的性格，也许它在那个巨大的"肚子迷宫"里迷路了，周围是粉红色的肉壁，像云层一样柔软但又充满危险。孙悟空虽然在战斗，但他其实只是个顽皮的孩子。这种身体里的冒险，充满了童趣和荒诞感。''';
      } else if (userMessage.contains('母亲') || userMessage.contains('铁扇')) {
        return '''所有的母亲都是强大的。👵 铁扇公主虽然是妖怪，但她此时此刻只是一个失去了孩子的母亲。她的愤怒是有力量的，就像暴风雨一样。在我的电影里，女性往往背负着诅咒或重担，她也是一样。她不是单纯的坏人，她只是在守护她认为珍贵的东西，即便那意味着要对抗整个世界。''';
      }
    } else if (role.id == 'luxun') {
      if (userMessage.contains('百姓') || userMessage.contains('扇子')) {
        return '''这大约便是吃人的世道了。🚬 百姓要种地，本是靠天吃饭，如今却要仰仗一家妖怪的鼻息。那扇子本是天地灵宝，却成了罗刹女敛财的私器。百姓们长年累月地被"热"煎熬着，还要千恩万谢地去求那一点凉风，这是何等的奴性，又是何等的悲凉。''';
      } else if (userMessage.contains('钻') || userMessage.contains('肚子')) {
        return '''泼猴的手段，虽嫌无赖，却是对付顽固者的必需。🗡️ 对于那些手握强权（扇子）、不讲道理的人，你同他作揖打拱，他是看不见的；非得钻进他的肚肠里，让他痛得打滚，他才晓得你也是个人物。在这个世上，有时候"讲理"是行不通的，得有点"钻肚子"的精神。''';
      } else if (userMessage.contains('假') || userMessage.contains('扇')) {
        return '''给人虚假的希望，比直接拒绝更加可恶。🌑 这假扇子，像极了那些开给国民的空头支票。你以为挥一挥就能灭火、就能太平，结果那火势反而更猛，烧焦了你的皮肉。然而人们往往拿到这"假扇子"时是狂喜的，非得被烧痛了，才肯承认那只是涂了色的簸箕。''';
      }
    }

    // 默认回复
    return role.greeting;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 角色切换条
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Column(
            children: [
              // 只显示一开始选择的角色
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 显示选择的角色
                    ...widget.selectedCompanions.map((role) {
                      final isSelected = widget.currentRole.id == role.id && !widget.isGroupMode;
                      return GestureDetector(
                        onTap: () {
                          widget.onRoleChanged(role);
                          if (widget.onGroupModeToggle != null) {
                            widget.onGroupModeToggle!(false);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getRoleColor(role.colorClass)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(role.avatar,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                role.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? _getRoleTextColor(role.colorClass)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // 群聊按钮（当有选择的角色时显示）
                    if (widget.selectedCompanions.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          if (widget.onGroupModeToggle != null) {
                            widget.onGroupModeToggle!(!widget.isGroupMode);
                            // 切换群聊模式时，显示群聊内容
                            if (!widget.isGroupMode) {
                              _showGroupChatMessages();
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.isGroupMode
                                ? const Color(0xFF4F46E5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.isGroupMode
                                  ? Colors.transparent
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group,
                                size: 16,
                                color: widget.isGroupMode
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '群聊',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: widget.isGroupMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: widget.isGroupMode
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 消息区域
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 系统提示
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      widget.isGroupMode
                          ? '已进入群聊模式，所有角色将一起回复'
                          : '已进入沉浸模式，当前角色：${widget.currentRole.name}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  // 消息列表
                  ..._messages.map((msg) => _buildMessageBubble(msg)),
                ],
              ),
            ),
          ),
        ),
        // 输入区域
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.mic, size: 20, color: Colors.grey[400]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: widget.isGroupMode
                          ? '在群聊中与大家探讨...'
                          : '与${widget.currentRole.name}探讨...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGroupChatMessages() {
    // 显示群聊的三轮对话
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: null,
            content: '第一轮：关于"火焰山的所有权与垄断"',
            isUser: false,
            isSystem: true,
          ));
        });
      }
    });

    final trump = widget.selectedCompanions.firstWhere((r) => r.id == 'trump', orElse: () => widget.selectedCompanions.first);
    final luxun = widget.selectedCompanions.firstWhere((r) => r.id == 'luxun', orElse: () => widget.selectedCompanions.first);
    final miyazaki = widget.selectedCompanions.firstWhere((r) => r.id == 'miyazaki', orElse: () => widget.selectedCompanions.first);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: trump,
            content: '只要她是合法拥有的，这就是聪明的商业模式！💰 垄断？那是赢家的代名词。百姓给钱，她提供服务，公平交易！',
            isUser: false,
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: luxun,
            content: '哼，所谓的公平，不过是弱肉强食的遮羞布。🩸 垄断了生机，便是扼住了百姓的咽喉，这哪里是交易，分明是勒索。',
            isUser: false,
          ));
        });
      }
    });

    // 第二轮
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: null,
            content: '第二轮：关于"定风丹"的作用',
            isUser: false,
            isSystem: true,
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: miyazaki,
            content: '那定风丹，大概就是内心的平静吧。🌪️ 无论外面的风暴（铁扇公主的愤怒）多么猛烈，只要心是定的，就不会被吹跑。',
            isUser: false,
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: trump,
            content: '错！定风丹就是制裁豁免权！🛡️ 或者是坚固的防弹玻璃。有了它，别人攻击不了你，你就可以为所欲为。我也想要一颗定风丹。',
            isUser: false,
          ));
        });
      }
    });

    // 第三轮
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: null,
            content: '第三轮：关于"结局的假扇子"',
            isUser: false,
            isSystem: true,
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: luxun,
            content: '即使是齐天大圣，也难免被虚伪的外表蒙蔽。👁️ 悟空啊，切记，莫要在未曾检验真理之前，便盲目地欢呼。',
            isUser: false,
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: miyazaki,
            content: '也许火没有灭，是因为那把扇子里没有"爱"吧。💔 假的扇子只能带来风，却带不走内心的仇恨之火。',
            isUser: false,
          ));
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: trump,
            content: '悟空，下次找我，我给你介绍最好的律师。⚖️ 我们要起诉翠云山芭蕉洞，让她们赔偿你的猴毛，还要赔偿精神损失费！',
            isUser: false,
          ));
        });
      }
    });
  }

  Color _getRoleColor(String colorClass) {
    switch (colorClass) {
      case 'yellow':
        return const Color(0xFFFEF3C7);
      case 'blue':
        return const Color(0xFFDBEAFE);
      case 'purple':
        return const Color(0xFFE9D5FF);
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getRoleTextColor(String colorClass) {
    switch (colorClass) {
      case 'yellow':
        return const Color(0xFF78350F);
      case 'blue':
        return const Color(0xFF1E3A8A);
      case 'purple':
        return const Color(0xFF581C87);
      default:
        return Colors.grey[800]!;
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      // 用户消息（右侧）
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
        ),
      );
    }

    if (message.isSystem) {
      // 系统消息（居中）
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // AI角色消息（左侧）
    final role = message.role!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                role.avatar,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: role.id == 'wukong'
                        ? const Color(0xFFFEF3C7)
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: role.id == 'wukong'
                          ? const Color(0xFF78350F)
                          : const Color(0xFF1F2937),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 10,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '播放语音 (定制音色)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 聊天消息模型
class ChatMessage {
  final Role? role;
  final String content;
  final bool isUser;
  final bool isSystem;

  ChatMessage({
    this.role,
    required this.content,
    this.isUser = false,
    this.isSystem = false,
  });
}

