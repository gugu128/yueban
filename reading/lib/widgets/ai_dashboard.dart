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
  final VoidCallback onClose;
  final Function(Role) onRoleChanged;
  final Function(bool)? onGroupModeToggle;

  const AIDashboard({
    super.key,
    required this.isVisible,
    required this.currentRole,
    this.selectedCompanions = const [],
    this.isGroupMode = false,
    required this.onClose,
    required this.onRoleChanged,
    this.onGroupModeToggle,
  });

  @override
  State<AIDashboard> createState() => _AIDashboardState();
}

class _AIDashboardState extends State<AIDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  String activeTab = 'chat';

  @override
  void initState() {
    super.initState();
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
        return const GraphTab();
      case 'lab':
        return const LabTab();
      case 'create':
        return const CreativeTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

