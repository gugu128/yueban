import 'package:flutter/material.dart';
import 'package:reading/services/demo_data.dart';
import 'package:reading/models/book_content.dart';
import 'package:reading/utils/text_formatter.dart';

class ChatTab extends StatefulWidget {
  final Role currentRole;
  final List<Role> selectedCompanions;
  final bool isGroupMode;
  final Function(Role) onRoleChanged;
  final Function(bool)? onGroupModeToggle;
  final String bookId; // 当前书目：xyj / jane_eyre / paper / cartoon

  const ChatTab({
    super.key,
    required this.currentRole,
    this.selectedCompanions = const [],
    this.isGroupMode = false,
    required this.onRoleChanged,
    this.onGroupModeToggle,
    this.bookId = 'xyj',
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _hasShownExamGuide = false;

  bool _isImageAvatar(String avatar) {
    return avatar.startsWith('assets/');
  }

  Widget _buildRoleAvatar(String avatar, {double size = 16}) {
    if (_isImageAvatar(avatar)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: size,
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }
    return Text(
      avatar,
      style: TextStyle(fontSize: size),
    );
  }
  // 记录每个角色的对话索引，按顺序回复
  final Map<String, int> _roleDialogueIndex = {};
  // 记录群聊当前显示到第几轮（0表示还没开始）
  int _groupChatRoundIndex = 0;

  @override
  void initState() {
    super.initState();
    // 初始化时显示角色引导词
    _addInitialMessages();
  }

  @override
  void didUpdateWidget(ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果切换了角色或模式，清空消息并重新初始化
    if (oldWidget.currentRole.id != widget.currentRole.id || 
        oldWidget.isGroupMode != widget.isGroupMode) {
      setState(() {
        _messages.clear();
        _groupChatRoundIndex = 0; // 重置群聊轮次
        _addInitialMessages();
      });
    }
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
            // 群聊模式：显示群聊对话
            _showGroupChatMessages();
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
    return aiExamGuideContent;
  }

  String _getRoleResponse(Role role, String userMessage) {
    // Cartoon模式：检查是否是关于漫画深意的问题，且角色是宫崎骏
    if (widget.bookId == 'cartoon' && role.id == 'miyazaki') {
      final cartoonReply = _getCartoonReplyForMiyazaki(userMessage);
      if (cartoonReply != null) {
        return cartoonReply;
      }
    }
    
    // 根据角色ID返回对应的对话内容（使用demo_data中的数据）
    final dialogues = companionDialogues[role.id];
    if (dialogues != null && dialogues.isNotEmpty) {
      // 获取当前角色的对话索引
      final currentIndex = _roleDialogueIndex[role.id] ?? 0;
      
      // 按顺序返回对话，循环使用
      final response = dialogues[currentIndex % dialogues.length];
      
      // 更新索引，下次使用下一个对话
      _roleDialogueIndex[role.id] = (currentIndex + 1) % dialogues.length;
      
      return response;
    }

    // 默认回复
    return role.greeting;
  }
  
  // Cartoon模式：获取宫崎骏关于漫画深意的回答
  String? _getCartoonReplyForMiyazaki(String userInput) {
    String normalize(String s) => s.replaceAll('"', '').replaceAll('"', '').replaceAll('：', ':').trim().toLowerCase();
    final normalized = normalize(userInput);
    
    // 检查是否包含漫画相关关键词
    final keywords = ['漫画', '深意', '意思', '含义', '意义', '讽刺', '什么'];
    final matchedCount = keywords.where((k) => normalized.contains(k)).length;
    
    if (matchedCount >= 2 || normalized.contains('漫画') && (normalized.contains('深意') || normalized.contains('意思'))) {
      return '哎呀，这真是一个被施了悲伤魔法的画面呢……就像是被某种看不见的诅咒缠绕着。\n\n请允许我用一个老婆婆（或者是森林里看守旧时光的精灵）的眼光，来为你解读这个奇怪的世界吧：\n\n1. 建立在虚幻之上的悲伤\n你看那个穿着黑衣服的人，他在低头默哀，那是人类最沉重、最私密的时刻。那棵枯树，那朵花，那是生命的凋零。可是，孩子，你看他的脚下——支撑着这片土地的，不再是厚实温暖的泥土，也不再是盘根错节的树根，而是一个巨大的、冰冷的"大拇指"。\n\n这让我想起那些被贪婪吞噬的幽灵。这幅画在告诉我们：在这个时代，如果悲伤没有被"点赞"托举起来，仿佛它就不存在一样。\n人们是不是已经忘记了如何安静地独自流泪？是不是只有当痛苦变成了别人的谈资和认可，这份痛苦才算有了"重量"？\n\n2. 吞噬真心的机器\n那个巨大的手势，就像是汤婆婆油屋里的金子，看着诱人，其实是虚空的。\n这幅画有着令人心疼的讽刺：我们在用最真实的眼泪，去喂养那个渴望关注的怪兽。\n上面是生离死别的痛，下面却是轻松随意的"真棒"。多么荒谬啊，对他人的死亡和离去，现代人只能给出一个轻飘飘的点击。这种对比，就像是把森林砍光了去建游乐场一样，让人心里空落落的。\n\n3. 迷失的自我\n你看那个人，他低着头。他是在看坟墓，还是在看那个深埋地下的"赞"呢？\n这就像是中了魔法的人类。我们把生活建立在他人的评价之上。\n我们的喜怒哀乐，如果不展示出来换取那个大拇指，好像就没有了意义。我们变得不再是为了纪念逝者而悲伤，而是为了"表演悲伤"而悲伤。\n\n结语\n孩子，你要记住，真正的心意是不需要那个按钮的。就像风吹过树梢的声音，就像泥土的芬芳，真正的悲伤和爱，应该是静悄悄的，沉在心底的，那是属于你和逝者之间神圣的契约，而不是演给世界看的一出戏。\n\n快醒醒吧，不要让那个巨大的手指，把你真正的心给偷走了。';
    }
    
    return null;
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
                              _buildRoleAvatar(role.avatar, size: 20),
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
                            // 切换群聊模式时，清空消息并重新初始化（不自动显示群聊内容）
                            if (!widget.isGroupMode) {
                              setState(() {
                                _messages.clear();
                                _addInitialMessages();
                              });
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
                  // 消息列表（单人模式下只显示当前角色的消息）
                  ..._messages
                      .where((msg) => widget.isGroupMode || 
                          msg.isUser || 
                          msg.isSystem || 
                          (msg.role != null && msg.role!.id == widget.currentRole.id))
                      .map((msg) => _buildMessageBubble(msg)),
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
    // 只显示一轮对话（使用demo_data中的数据）
    if (_groupChatRoundIndex >= groupChatRounds.length) {
      // 如果已经显示完所有轮次，循环回到第一轮
      _groupChatRoundIndex = 0;
    }

    final round = groupChatRounds[_groupChatRoundIndex];

    // 仅在已选择角色中精确匹配，避免错误地回退到第一个角色（导致同一角色重复发言）
    final Map<String, Role> selectedRoleMap = {
      for (final role in widget.selectedCompanions) role.id: role,
    };

    int delay = 500;

    // 不显示轮次标题，直接添加这一轮的消息
    for (var msg in round.messages) {
      Role? role = selectedRoleMap[msg.roleId];

      // 兼容旧数据：trump 与 mayun 互为别名
      if (role == null && msg.roleId == 'trump') {
        role = selectedRoleMap['mayun'];
      } else if (role == null && msg.roleId == 'mayun') {
        role = selectedRoleMap['trump'];
      }

      if (role != null) {
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                role: role,
                content: msg.content,
                isUser: false,
              ));
            });
          }
        });
        delay += 500;
      }
    }

    // 更新轮次索引，下次发送消息时显示下一轮
    _groupChatRoundIndex++;
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
                  child: buildFormattedText(
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
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/yonghu.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
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
            child: buildFormattedText(
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
              child: _buildRoleAvatar(role.avatar, size: 24),
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
                  child: buildFormattedText(
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

