import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';
import 'package:reading/widgets/ai_dashboard.dart';

class ReaderScreen extends StatefulWidget {
  final String? intent;
  final List<Role> selectedCompanions;
  final bool isGroupMode;
  final VoidCallback onBack;
  final String? pdfAssetPath; // 资产 PDF 路径：例如 assets/PDF/paper.pdf

  const ReaderScreen({
    super.key,
    this.intent,
    this.selectedCompanions = const [],
    this.isGroupMode = false,
    required this.onBack,
    this.pdfAssetPath,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool showDashboard = false;
  bool isPlaying = false;
  bool isListening = false; // 听书状态
  int? showCitation;
  Map<String, dynamic>? contextMenu;
  bool showCatalog = false;
  bool showSettings = false; // 显示设置面板
  bool immersiveReading = false; // 沉浸式阅读开关
  String? selectedQuote; // 最近一次点击的原文
  String dashboardTargetTab = 'chat'; // 打开工作台时默认落到的 tab
  String? injectedQuote; // 传给工作台的引用文本
  int quoteVersion = 0; // 引用变更序号，保证同样内容也能刷新
  late Role currentRole;
  bool showAutoImage = false;
  late PageController _pageController;
  int currentPage = 0;
  late bool isGroupMode;
  int? showCommentIndex; // 显示评论的文本块索引
  int? showExplanationIndex; // 显示释义的文本块索引
  String? _pdfFilePath;
  int? _pdfTotalPages;
  bool _pdfReady = false;
  bool _pdfAsText = false; // 是否将 PDF 转为文字阅读
  bool _pdfTextLoading = false;
  List<String> _pdfPageTexts = [];
  bool _xyjPdfMode = true; // 西游记：默认展示 PDF 文档模式；开启“扫描成文本”后变为现有文本阅读（不改变）
  String? _activePdfAsset; // 当前加载到临时文件的 PDF asset 路径

  @override
  void initState() {
    super.initState();
    currentRole = widget.selectedCompanions.isNotEmpty ? widget.selectedCompanions.first : roles[0];
    isGroupMode = widget.isGroupMode;
    _pageController = PageController();
    // 模拟读到第3段时，AI生成图片浮现
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          showAutoImage = true;
        });
      }
    });

    // 如果是 PDF 阅读模式：提前把 asset 拷贝到临时文件（flutter_pdfview 需要 filePath）
    // - 上传论文：widget.pdfAssetPath != null
    // - 西游记：默认 _xyjPdfMode=true 时使用 assets/PDF/xyj.PDF
    final initialPdfAsset = _currentPdfAssetPath();
    if (initialPdfAsset != null) {
      _preparePdf(initialPdfAsset);
    }
  }

  String? _currentPdfAssetPath() {
    final paper = widget.pdfAssetPath?.trim();
    if (paper != null && paper.isNotEmpty) return paper;
    // 只有在“西游记默认阅读页”才走这个逻辑
    if (_xyjPdfMode) return 'assets/PDF/xyj.pdf';
    return null;
  }

  Future<void> _preparePdf(String assetPath) async {
    try {
      // 如果已经是这个 PDF，不重复拷贝
      if (_activePdfAsset == assetPath && _pdfFilePath != null) return;
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final name = assetPath.split('/').last;
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _activePdfAsset = assetPath;
        _pdfFilePath = file.path;
      });
    } catch (_) {
      // 保持静默失败：UI 会展示加载失败提示
      if (!mounted) return;
      setState(() {
        _pdfFilePath = null;
      });
    }
  }

  Future<void> _ensurePdfText() async {
    if (_pdfTextLoading || _pdfPageTexts.isNotEmpty) {
      // 已经在加载或已加载过
      setState(() {
        _pdfAsText = true;
      });
      return;
    }

    setState(() {
      _pdfTextLoading = true;
    });

    try {
      // 直接从 asset 读取 PDF bytes 做文本抽取，避免再次从临时文件读取失败
      final data = await rootBundle.load(widget.pdfAssetPath!.trim());
      final bytes = data.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final List<String> pages = [];
      final extractor = PdfTextExtractor(document);
      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        ).trim();
        if (text.isNotEmpty) {
          pages.add(text);
        }
      }
      document.dispose();

      if (!mounted) return;
      setState(() {
        _pdfPageTexts = pages.isEmpty ? ['（未能从 PDF 中提取到可阅读文本）'] : pages;
        _pdfAsText = true;
        _pdfTextLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pdfPageTexts = ['（扫描失败，请稍后重试或继续使用原始 PDF 阅读模式）'];
        _pdfAsText = true;
        _pdfTextLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTextTap(TapDownDetails details, BookContent block) {
    if (block.type != 'text') return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      selectedQuote = block.content;
      contextMenu = {
        'x': localPosition.dx.clamp(0.0, screenSize.width - 200),
        'y': localPosition.dy.clamp(0.0, screenSize.height - 100),
        'text': block.content.length > 10
            ? '${block.content.substring(0, 10)}...'
            : block.content,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          contextMenu = null;
        });
      },
      child: Container(
        color: const Color(0xFFFDFBF7), // 米白色背景
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 顶部阅读栏
                  _buildTopBar(),
                  // 正文横向翻页区
                  Expanded(
                    child: _buildPagedContent(),
                  ),
                ],
              ),
              // 目录侧边栏
              if (showCatalog) _buildCatalogPanel(),
              // 划词悬浮菜单
              if (contextMenu != null) _buildContextMenu(),
              // 溯源弹窗
              if (showCitation != null) _buildCitationPopup(),
              // 评论批注弹窗
              if (showCommentIndex != null) _buildCommentPanel(),
              // 释义弹窗
              if (showExplanationIndex != null) _buildExplanationPanel(),
              // 设置面板
              if (showSettings) _buildSettingsPanel(),
              // 底部播放条（听书时显示）
              if (isListening && !showDashboard) _buildAudioPlayerBar(),
              // 底部触发器
              if (!showDashboard) _buildFloatingButton(),
              // AI 工作台
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: AIDashboard(
                    isVisible: showDashboard,
                    currentRole: currentRole,
                    selectedCompanions: widget.selectedCompanions,
                    isGroupMode: isGroupMode,
                  injectedTab: dashboardTargetTab,
                  injectedQuote: injectedQuote,
                  quoteVersion: quoteVersion,
                    onClose: () {
                      setState(() {
                        showDashboard = false;
                      });
                    },
                    onRoleChanged: (role) {
                      setState(() {
                        currentRole = role;
                      });
                    },
                    onGroupModeToggle: (isGroup) {
                      setState(() {
                        isGroupMode = isGroup;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF5F5F4), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF78716C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (!isListening)
            const Expanded(
              child: Center(
                child: Text(
                  '第五十九回 唐三藏路阻火焰山 孙行者一调芭蕉扇',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'serif',
                    color: Color(0xFF78716C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final wasListening = isListening;
                  setState(() {
                    isListening = !isListening;
                    isPlaying = isListening;
                  });
                  // 显示听书提示
                  if (!wasListening && isListening) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.headphones, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            Text('正在听书...', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF4F46E5),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isListening ? Icons.headphones : Icons.headphones_outlined,
                  size: 20,
                  color: isListening
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF78716C),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    showCatalog = !showCatalog;
                  });
                },
                icon: const Icon(Icons.menu_book, size: 20, color: Color(0xFF78716C)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  // 如果当前是 PDF 阅读模式，则将三个点用作“是否扫描为文字”的开关；
                  // 对西游记这类普通文本阅读页则仍然作为设置入口。
                  if (widget.pdfAssetPath != null && widget.pdfAssetPath!.trim().isNotEmpty) {
                    if (!_pdfAsText) {
                      // 第一次开启：触发扫描，并提示用户
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('正在从 PDF 中提取文字并优化排版，请稍候...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      await _ensurePdfText();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已切换为「文字阅读模式」，向右滑动可继续翻页。'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      setState(() {
                        _pdfAsText = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已切回「原始 PDF 模式」。'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    setState(() {
                      showSettings = !showSettings;
                    });
                  }
                },
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF78716C)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 横向翻页内容
  Widget _buildPagedContent() {
    // PDF 模式：
    // - 论文：支持 “原始 PDF / 扫描文字” 两种模式（三个点切换）
    // - 西游记：默认展示 assets/PDF/xyj.PDF；“设置->扫描成文本”打开时回到原本的文本阅读（不改变）
    final currentPdf = _currentPdfAssetPath();
    if (currentPdf != null) {
      if (widget.pdfAssetPath != null && widget.pdfAssetPath!.trim().isNotEmpty) {
        if (_pdfAsText) return _buildPdfTextContent();
      }
      // 确保当前 PDF 已加载到临时文件
      if (_activePdfAsset != currentPdf) {
        // 异步触发，不阻塞 build
        _preparePdf(currentPdf);
      }
      return _buildPdfContent();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算可用高度：总高度 - 顶部栏高度 - SafeArea
        final availableHeight = constraints.maxHeight;
        // 计算可用宽度（减去左右 padding 48 = 24*2）
        final screenWidth = constraints.maxWidth - 48;
        final pages = _buildContentPages(availableHeight, screenWidth);
        
        return PageView.builder(
          controller: _pageController,
          itemCount: pages.length + 1, // 第一页为标题+图片
          onPageChanged: (index) {
            setState(() {
              currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCoverPage();
            }
            final blocks = pages[index - 1];
            return _buildReadingPage(blocks);
          },
        );
      },
    );
  }

  Widget _buildPdfContent() {
    if (_pdfFilePath == null) {
      return Center(
        child: Text(
          '正在加载 PDF…',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      color: const Color(0xFFFDFBF7),
      child: PDFView(
        filePath: _pdfFilePath!,
        swipeHorizontal: true,
        pageFling: true,
        autoSpacing: false,
        fitPolicy: FitPolicy.BOTH,
        onRender: (pages) {
          if (!mounted) return;
          setState(() {
            _pdfTotalPages = pages;
            _pdfReady = true;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _pdfReady = false;
          });
        },
        onPageChanged: (page, total) {
          if (!mounted) return;
          setState(() {
            currentPage = page ?? 0;
            _pdfTotalPages = total;
          });
        },
      ),
    );
  }

  Widget _buildPdfTextContent() {
    if (_pdfTextLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF4F46E5)),
            ),
            const SizedBox(height: 12),
            Text(
              '正在扫描并排版文字...',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_pdfPageTexts.isEmpty) {
      return Center(
        child: Text(
          '暂无可显示的文字内容',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return PageView.builder(
      itemCount: _pdfPageTexts.length,
      onPageChanged: (index) {
        setState(() {
          currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        final text = _pdfPageTexts[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '第 ${index + 1} 页',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    fontFamily: 'serif',
                    color: Color(0xFF1C1917),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<List<BookContent>> _buildContentPages(double availableHeight, double screenWidth) {
    final contents = bookContent.where((b) => b.type != 'title' && b.type != 'image_gen').toList();
    final List<List<BookContent>> result = [];
    
    // 使用 TextPainter 精确计算每页能容纳的内容
    const double fontSize = 17.0;
    const double lineHeight = 2.0;
    const double padding = 32.0; // 上下 padding (16 + 16)
    const double marginBottom = 20.0; // 段落间距
    final double usableHeight = availableHeight - padding;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    List<BookContent> currentPage = [];
    double currentPageHeight = 0;
    
    for (var block in contents) {
      // 使用 TextPainter 精确计算文本高度
      textPainter.text = TextSpan(
        text: block.content,
        style: TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          fontFamily: 'serif',
        ),
      );
      textPainter.layout(maxWidth: screenWidth);
      final textHeight = textPainter.size.height;
      final blockHeight = textHeight + marginBottom;
      
      // 如果当前页加上这个块会超出，就创建新页
      if (currentPageHeight + blockHeight > usableHeight && currentPage.isNotEmpty) {
        result.add(List.from(currentPage));
        currentPage = [block];
        currentPageHeight = blockHeight;
      } else {
        currentPage.add(block);
        currentPageHeight += blockHeight;
      }
    }
    
    // 添加最后一页
    if (currentPage.isNotEmpty) {
      result.add(currentPage);
    }
    
    return result;
  }

  Widget _buildCoverPage() {
    final chapter = chapters.firstWhere(
      (c) => c.chapterNumber == 59,
      orElse: () => chapters.first,
    );

    final imageAssets = const [
      'assets/images/xyj1.png',
      'assets/images/xyj2.png',
      'assets/images/xyj3.png',
      'assets/images/xyj4.png',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              chapter.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: Color(0xFF1C1917),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'AI 小助手为你伴读《西游记》第五十九回',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...imageAssets.map((asset) {
            final index = imageAssets.indexOf(asset);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _showImagePreview(asset),
                child: Hero(
                  tag: asset,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.asset(
                          asset,
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Text(
                              'AI生成插画',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4F46E5)),
                    SizedBox(width: 6),
                    Text(
                      'AI 章节概括',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  chapter.aiSummary,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPage(List<BookContent> blocks) {
    final contentBlocks = bookContent.where((b) => b.type != 'title' && b.type != 'image_gen').toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blocks.asMap().entries.map((entry) {
              final index = entry.key;
              final block = entry.value;
              
              // 跳过图片
              if (block.type == 'image_gen') {
                return const SizedBox.shrink();
              }

              // 找到在完整内容列表中的索引（排除title和image_gen）
              final contentIndex = contentBlocks.indexOf(block);
              // 找到在bookContent数组中的原始索引
              final originalIndex = bookContent.indexOf(block);
              
              return GestureDetector(
                onTapDown: (details) {
                  // 点击：弹出两按钮菜单（AI陪读 / 深度探讨）
                  _handleTextTap(details, block);
                },
                onLongPress: () {
                  // 长按：仅对带下划线且有释义的块弹出释义，避免和“点击菜单”混淆
                  if (block.underline && block.explanation != null) {
                    setState(() {
                      showExplanationIndex = contentIndex;
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 17,
                        height: 2.0,
                        color: const Color(0xFF1C1917),
                        fontFamily: 'serif',
                        backgroundColor: block.highlight
                            ? const Color(0xFFFEF3C7).withOpacity(0.8)
                            : Colors.transparent,
                        decoration: block.underline ? TextDecoration.underline : null,
                        decorationColor: block.underline ? const Color(0xFF4F46E5) : null,
                        decorationStyle: block.underline ? TextDecorationStyle.solid : null,
                        decorationThickness: block.underline ? 1.5 : null,
                      ),
                      children: [
                        TextSpan(text: block.content),
                        if (block.highlight)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  showCommentIndex = originalIndex;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: const Icon(
                                  Icons.comment_outlined,
                                  size: 14,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
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
      },
    );
  }

  void _showImagePreview(String asset) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Hero(
              tag: asset,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: Image.asset(asset),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogPanel() {
    final catalogChapters = chapters.where((c) => c.chapterNumber >= 59 && c.chapterNumber <= 63).toList();
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showCatalog = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {}, // 阻止点击穿透
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '目录与 AI 概括',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            showCatalog = false;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.menu_book, size: 20, color: Color(0xFF4F46E5)),
                                      SizedBox(width: 8),
                                      Text(
                                        'AI 全文概括',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    fullBookSummary,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEEF2FF),
                            Color(0xFFE0F2FE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome, size: 18, color: Color(0xFF4F46E5)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI 全文概括',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: catalogChapters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chapter = catalogChapters[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: chapter.chapterNumber == 59
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: chapter.chapterNumber == 59
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.summarize, size: 14, color: Color(0xFF6B7280)),
                                        SizedBox(width: 4),
                                        Text(
                                          'AI 章节概括',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chapter.aiSummary,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        height: 1.5,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenu() {
    if (contextMenu == null) return const SizedBox.shrink();

    return Positioned(
      left: (contextMenu!['x'] as num).toDouble(),
      top: (contextMenu!['y'] as num).toDouble() - 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF111827),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContextMenuItem(Icons.group, 'AI陪读', () {
                setState(() {
                  contextMenu = null;
                  dashboardTargetTab = 'ai_helper';
                  injectedQuote = selectedQuote;
                  quoteVersion++;
                  showDashboard = true;
                });
              }),
              _buildContextMenuItem(Icons.forum_outlined, '深度探讨', () {
                setState(() {
                  contextMenu = null;
                  dashboardTargetTab = 'deep';
                  injectedQuote = selectedQuote;
                  quoteVersion++;
                  showDashboard = true;
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationPopup() {
    return GestureDetector(
      onTap: () {
        setState(() {
          showCitation = null;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.scanner, size: 14, color: Color(0xFF374151)),
                          SizedBox(width: 4),
                          Text(
                            '原文溯源与事实核查',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            showCitation = null;
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // 内容区
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                      ),
                      child: Column(
                        children: [
                          // 模拟原书扫描件（模糊）
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 16,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  height: 16,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // 高亮框
                                Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red, width: 2),
                                        color: Colors.red.withOpacity(0.1),
                                      ),
                                      child: const Text(
                                        '这部书单表东胜神洲。海外有一国土，名曰傲来国。国近大海，海中有一座名山，唤为花果山。',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                    ),
                                    // Source标签
                                    Positioned(
                                      top: 12,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                        ),
                                        child: const Text(
                                          'Source',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  height: 16,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildAudioPlayerBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 播放图标
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              // 只显示"正在听书"提示，字体小一点
              const Text(
                '正在听书',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return Positioned(
      bottom: isListening ? 72 : 32, // 如果正在听书，浮动按钮上移
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                showDashboard = true;
              });
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFFA855F7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: const Icon(
                  Icons.star,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentPanel() {
    if (showCommentIndex == null) return const SizedBox.shrink();
    
    final comment = comments[showCommentIndex];
    if (comment == null) return const SizedBox.shrink();

    // 过滤出特朗普、鲁迅、宫崎骏的评论
    final filteredAnnotations = comment.annotations.where((ann) {
      return ann.reviewerId == 'trump' || 
             ann.reviewerId == 'luxun' || 
             ann.reviewerId == 'miyazaki';
    }).toList();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showCommentIndex = null;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {}, // 阻止点击穿透
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题栏
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.comment_outlined, size: 18, color: Color(0xFF6366F1)),
                                SizedBox(width: 8),
                                Text(
                                  '伴读评论',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  showCommentIndex = null;
                                });
                              },
                              icon: const Icon(Icons.close, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // 评论内容
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 高亮文本
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFEF3C7),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  comment.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF78350F),
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ),
                              // 评论列表
                              if (filteredAnnotations.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  child: const Center(
                                    child: Text(
                                      '暂无评论',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...filteredAnnotations.map((annotation) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              annotation.reviewerAvatar,
                                              style: const TextStyle(fontSize: 24),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              annotation.reviewerName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          annotation.comment,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.6,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
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
    );
  }

  Widget _buildExplanationPanel() {
    if (showExplanationIndex == null) return const SizedBox.shrink();
    
    final contentBlocks = bookContent.where((b) => b.type != 'title' && b.type != 'image_gen').toList();
    if (showExplanationIndex! >= contentBlocks.length) return const SizedBox.shrink();
    
    final block = contentBlocks[showExplanationIndex!];
    if (block.explanation == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showExplanationIndex = null;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击穿透
              child: Container(
                margin: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Color(0xFF6366F1)),
                              SizedBox(width: 8),
                              Text(
                                '释义',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                showExplanationIndex = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // 内容
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标记文本
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF6366F1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                block.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6366F1),
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                            // 释义
                            Text(
                              block.explanation!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF374151),
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

  Widget _buildSettingsPanel() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showSettings = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击穿透
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '设置',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                showSettings = false;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // 内容
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 沉浸式阅读开关
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '沉浸式阅读',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '开启后，将根据情节自动匹配BGM',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Switch(
                                value: immersiveReading,
                                onChanged: (value) {
                                  setState(() {
                                    immersiveReading = value;
                                    if (value) {
                                      // 如果开启沉浸式阅读，可以在这里添加相关逻辑
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.music_note, color: Colors.white, size: 18),
                                              SizedBox(width: 12),
                                              Text('已开启沉浸式阅读，将根据情节自动匹配BGM', 
                                                style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Color(0xFF4F46E5),
                                        ),
                                      );
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF4F46E5),
                              ),
                            ],
                          ),
                          // 仅对“西游记”阅读页生效：切换 “PDF文档 / 扫描成文本”
                          if (widget.pdfAssetPath == null) ...[
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '扫描成文本',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '关闭时阅读原始文档（assets/PDF/xyj.pdf）；开启后使用可高亮/批注的文本模式',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Switch(
                                  // 开关“开”=扫描成文本=使用现有文本阅读（不改变）
                                  value: !_xyjPdfMode,
                                  onChanged: (scanAsText) async {
                                    if (scanAsText) {
                                      setState(() {
                                        _xyjPdfMode = false; // 切到文本阅读
                                      });
                                      return;
                                    }
                                    // 开关“关”=文档模式=展示 xyj.pdf
                                    setState(() {
                                      _xyjPdfMode = true;
                                    });
                                    await _preparePdf('assets/PDF/xyj.pdf');
                                  },
                                  activeColor: const Color(0xFF4F46E5),
                                ),
                              ],
                            ),
                          ],
                        ],
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

