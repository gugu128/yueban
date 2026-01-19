import 'dart:async';
import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const ScanScreen({super.key, required this.onFinish});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // 模拟处理时间后跳转
    Timer(const Duration(milliseconds: 2800), () {
      widget.onFinish();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // 模拟摄像头取景
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&q=80&w=800',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.6),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.white54, size: 48),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                );
              },
            ),
          ),
          // 扫描框
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // 四个角
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                  // 扫描光效
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * MediaQuery.of(context).size.height * 0.5,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF818CF8), // indigo-400
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.8),
                                blurRadius: 15,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // 识别出的文字块模拟
                  _buildTextBlock(Alignment(0, -0.3)),
                  _buildTextBlock(Alignment(0, -0.1)),
                  _buildTextBlock(Alignment(0.2, 0.3)),
                ],
              ),
            ),
          ),
          // 底部提示
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'AI 正在提取排版与内容...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 8),
                    _buildDot(150),
                    const SizedBox(width: 8),
                    _buildDot(300),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF818CF8),
              width: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 4 : 0,
            ),
            bottom: BorderSide(
              color: const Color(0xFF818CF8),
              width: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 4 : 0,
            ),
            left: BorderSide(
              color: const Color(0xFF818CF8),
              width: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 4 : 0,
            ),
            right: BorderSide(
              color: const Color(0xFF818CF8),
              width: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 4 : 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextBlock(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 120,
        height: 16,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -value * 8),
          child: Opacity(
            opacity: 1 - value,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}

