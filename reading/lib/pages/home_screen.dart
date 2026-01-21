import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';
import 'package:reading/services/server_config.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onScan;
  final VoidCallback onUpload;

  const HomeScreen({super.key, required this.onScan, required this.onUpload});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 40),
                // 上传文档区域
                _buildUploadSection(),
                const SizedBox(height: 40),
                // 最近阅读
                Expanded(
                  child: _buildRecentReads(),
                ),
              ],
            ),
          ),
        );
      case 1:
        return const SafeArea(
          child: Center(child: Text('阅读记录（待接入）')),
        );
      case 2:
        return const SafeArea(
          child: Center(child: Text('解读记录（待接入）')),
        );
      case 3:
        return const MyTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '早安，Alex',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '欢迎来到"阅伴"！今日宜：深度阅读',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC7D2FE), width: 1),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '开始阅读',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // 上传文档按钮（大）
            Expanded(
              child: GestureDetector(
                onTap: () {
                  widget.onUpload();
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF9333EA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '上传文档',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '支持PDF、图片等格式',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 拍照按钮（小）
            GestureDetector(
              onTap: widget.onScan,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '拍照',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentReads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最近上传文件',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '查看全部',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: recentBooks.length,
            itemBuilder: (context, index) {
              final book = recentBooks[index];
              return _BookCard(book: book);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, '主页', 0),
              _buildNavItem(Icons.book, '阅读记录', 1),
              _buildNavItem(Icons.auto_awesome, '解读记录', 2),
              _buildNavItem(Icons.person, '我的', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class MyTab extends StatefulWidget {
  const MyTab({super.key});

  @override
  State<MyTab> createState() => _MyTabState();
}

class _MyTabState extends State<MyTab> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ServerConfig.instance.load();
    if (!mounted) return;
    setState(() {
      _loaded = true;
    });
  }

  Future<void> _openServerConfig() async {
    final hostController = TextEditingController(text: ServerConfig.instance.host);
    final portController = TextEditingController(
      text: ServerConfig.instance.port > 0 ? ServerConfig.instance.port.toString() : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('服务器配置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: '服务器 IP / 域名',
                  hintText: '例如：192.168.1.10',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '端口',
                  hintText: '例如：8080',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '保存后会使用：http://IP:端口',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await ServerConfig.instance.clear();
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('清空'),
            ),
            FilledButton(
              onPressed: () async {
                final host = hostController.text.trim();
                final port = int.tryParse(portController.text.trim()) ?? 0;
                if (host.isEmpty || port <= 0 || port > 65535) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入正确的服务器 IP/域名 与端口(1-65535)')),
                  );
                  return;
                }
                await ServerConfig.instance.save(host: host, port: port);
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    hostController.dispose();
    portController.dispose();

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ServerConfig.instance;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _loaded ? _openServerConfig : null,
                  icon: const Icon(Icons.dns_outlined),
                  tooltip: '服务器配置',
                ),
                const SizedBox(width: 8),
                const Text(
                  '我的',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前服务器',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cfg.isConfigured ? cfg.baseUrl : '未配置',
                    style: TextStyle(
                      fontSize: 13,
                      color: cfg.isConfigured ? const Color(0xFF111827) : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '提示：真机与服务器需在同一局域网；服务器建议监听 0.0.0.0。',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

class _BookCard extends StatelessWidget {
  final RecentBook book;

  const _BookCard({required this.book});

  Color _getColor() {
    switch (book.colorClass) {
      case 'emerald':
        return const Color(0xFFDCFCE7);
      case 'orange':
        return const Color(0xFFFFEDD5);
      case 'slate':
        return const Color(0xFF0F172A);
      default:
        return Colors.grey[100]!;
    }
  }

  // 根据书名生成装饰性图案
  List<Widget> _buildDecorativePatterns(String title, bool isDark) {
    final patterns = <Widget>[];
    final opacity = isDark ? 0.15 : 0.08;
    final iconOpacity = isDark ? 0.2 : 0.12;
    
    if (title.contains('西游记')) {
      // 西游记：古典风格装饰
      patterns.addAll([
        Positioned(
          right: -20,
          top: -20,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Icon(
            Icons.cloud_outlined,
            size: 32,
            color: Colors.white.withOpacity(iconOpacity),
          ),
        ),
        Positioned(
          left: -15,
          bottom: -15,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Icon(
            Icons.landscape_outlined,
            size: 28,
            color: Colors.white.withOpacity(iconOpacity),
          ),
        ),
      ]);
    } else if (title.contains('简爱') || title.contains('Jane')) {
      // 简爱：优雅风格装饰
      patterns.addAll([
        Positioned(
          right: -18,
          top: -18,
          child: Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Icon(
            Icons.local_florist_outlined,
            size: 30,
            color: Colors.white.withOpacity(iconOpacity),
          ),
        ),
        Positioned(
          left: -20,
          bottom: -20,
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Icon(
            Icons.auto_awesome_outlined,
            size: 26,
            color: Colors.white.withOpacity(iconOpacity),
          ),
        ),
      ]);
    } else {
      // 其他书籍：简洁风格装饰
      patterns.addAll([
        Positioned(
          right: -22,
          top: -22,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Icon(
            Icons.chat_bubble_outline,
            size: 34,
            color: Colors.white.withOpacity(iconOpacity),
          ),
        ),
        Positioned(
          left: -16,
          bottom: -16,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.75),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Icon(
            Icons.favorite_outline,
            size: 24,
            color: Colors.white.withOpacity(iconOpacity),
          ),
        ),
      ]);
    }
    
    return patterns;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getColor();
    final isDark = book.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor,
              isDark ? const Color(0xFF020617) : Colors.white,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 装饰图形 - 根据书名生成不同图案
            ..._buildDecorativePatterns(book.title, isDark),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 16,
                            color: isDark ? Colors.grey[300] : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '继续阅读',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[300] : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
