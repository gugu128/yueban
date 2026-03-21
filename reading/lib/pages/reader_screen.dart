import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:reading/services/mock_data.dart' as mock_data;
import 'package:reading/models/book_content.dart';
import 'package:reading/widgets/ai_dashboard.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final String avatar;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.avatar,
  });

  factory _ChatMessage.user(String text, {required String avatar}) {
    return _ChatMessage(text: text, isUser: true, avatar: avatar);
  }

  factory _ChatMessage.bot(String text, {required String avatar}) {
    return _ChatMessage(text: text, isUser: false, avatar: avatar);
  }
}


class ReaderScreen extends StatefulWidget {
  final String? intent;
  final List<Role> selectedCompanions;
  final bool isGroupMode;
  final VoidCallback onBack;
  final String? pdfAssetPath; // 资产 PDF 路径：例如 assets/PDF/paper.pdf
  final String bookId; // 当前阅读书目：xyj / jane_eyre / paper

  const ReaderScreen({
    super.key,
    this.intent,
    this.selectedCompanions = const [],
    this.isGroupMode = false,
    required this.onBack,
    this.pdfAssetPath,
    this.bookId = 'xyj',
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with SingleTickerProviderStateMixin {
  bool showDashboard = false;
  bool isPlaying = false;
  bool isListening = false; // 听书状态
  int? showCitation;
  Map<String, dynamic>? contextMenu;
  bool showCatalog = false;
  bool showSettings = false; // 显示设置面板
  bool immersiveReading = false; // 沉浸式阅读开关
  bool wordTranslationMode = false; // 划词翻译模式
  String? selectedQuote; // 最近一次点击的原文
  Set<String> translatedWords = {}; // 已翻译的单词/短语集合
  String dashboardTargetTab = 'chat'; // 打开工作台时默认落到的 tab
  String? injectedQuote; // 传给工作台的引用文本
  int quoteVersion = 0; // 引用变更序号，保证同样内容也能刷新
  String? _lastSelectedText; // 上次选择的文本，用于防抖
  DateTime? _lastSelectionTime; // 上次选择的时间
  bool _isTranslationDialogOpen = false; // 防止重复弹窗
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
  bool _xyjPdfMode = true; // 西游记：默认展示 PDF 文档模式；开启"扫描成文本"后变为现有文本阅读（不改变）
  String? _activePdfAsset; // 当前加载到临时文件的 PDF asset 路径
  late AnimationController _glowController; // 灯泡发光动画控制器
  bool showKnowledgeCard = false; // 是否显示知识卡片
  Offset? _floatingButtonPosition; // 浮动按钮位置（null 表示未初始化）
  bool _isDragging = false; // 是否正在拖动
  Offset _dragStartGlobalPosition = Offset.zero; // 拖动开始的全局位置
  final Map<String, List<_ChatMessage>> _companionChats = {};
  final Map<String, TextEditingController> _chatControllers = {};

  @override
  void initState() {
    super.initState();
    currentRole = widget.selectedCompanions.isNotEmpty
        ? widget.selectedCompanions.first
        : mock_data.roles[0];
    isGroupMode = widget.isGroupMode;
    _pageController = PageController();
    // 初始化灯泡发光动画控制器
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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

  bool get _isJaneEyre =>
      widget.bookId == 'jane_eyre' ||
      (widget.pdfAssetPath != null &&
          widget.pdfAssetPath!.contains('Jane Eyre'));

  bool get _isPaper => widget.bookId == 'paper';
  bool get _isCartoon => widget.bookId == 'cartoon';

  String _getTopBarTitle() {
    if (_isJaneEyre) {
      // 显示简爱的第一个章节标题
      final chapters = _activeChapters;
      if (chapters.isNotEmpty) {
        return chapters.first.title;
      }
      return 'Jane Eyre';
    }
    if (_isPaper || _isCartoon) {
      // 论文模式和cartoon模式不显示标题
      return '';
    }
    // 西游记默认标题
    return '第五十九回 唐三藏路阻火焰山 孙行者一调芭蕉扇';
  }

  List<BookContent> get _activeBookContent {
    if (_isJaneEyre) {
      return mock_data.janeEyreContent;
    }
    return mock_data.bookContent;
  }

  Map<int, Comment> get _activeComments {
    if (_isJaneEyre) {
      return mock_data.janeComments;
    }
    return mock_data.comments;
  }

  List<Chapter> get _activeChapters {
    if (_isJaneEyre) {
      return mock_data.janeChapters;
    }
    return mock_data.chapters;
  }

  String get _activeFullBookSummary {
    if (_isJaneEyre) {
      return mock_data.janeFullBookSummary;
    }
    return mock_data.fullBookSummary;
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
      // 针对简·爱节选：优先使用预置英文原文，保证与教案内容一致
      List<String> pages;
      if (_isJaneEyre) {
        pages = [mock_data.janeEyreChapter23Text.trim()];
      } else {
        // 其他 PDF：从 asset 读取 bytes 做文本抽取
        final data = await rootBundle.load(widget.pdfAssetPath!.trim());
        final bytes = data.buffer.asUint8List();
        final PdfDocument document = PdfDocument(inputBytes: bytes);

        pages = [];
        final extractor = PdfTextExtractor(document);
        for (int i = 0; i < document.pages.count; i++) {
          final text = extractor
              .extractText(
                startPageIndex: i,
                endPageIndex: i,
              )
              .trim();
          if (text.isNotEmpty) {
            pages.add(text);
          }
        }
        document.dispose();
      }

      if (!mounted) return;
      setState(() {
        _pdfPageTexts =
            pages.isEmpty ? ['（未能从 PDF 中提取到可阅读文本）'] : pages;
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
    _glowController.dispose();
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
              // 知识卡片（论文标记）
              if (showKnowledgeCard) _buildKnowledgeCard(),
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
                    bookId: widget.bookId,
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
          if (!isListening && _getTopBarTitle().isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _getTopBarTitle(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'serif',
                    color: Color(0xFF78716C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else if (!isListening)
            const Spacer()
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
                onPressed: () {
                  // 所有模式统一通过「设置」面板展示沉浸式/扫描文本等开关
                  setState(() {
                    showSettings = !showSettings;
                  });
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
    // 0）Cartoon模式：显示图片
    if (_isCartoon) {
      return _buildCartoonContent();
    }
    
    // 1）上传文档 A/B：包括"简·爱选段"的 PDF
    if (widget.pdfAssetPath != null && widget.pdfAssetPath!.trim().isNotEmpty) {
      // B 选项：简·爱 PDF → 开启"扫描成文本"后，直接进入支持高亮/批注的文本阅读模式
      if (_isJaneEyre && _pdfAsText) {
        return _buildTextBookPagedContent();
      }

      final currentPdf = _currentPdfAssetPath();
      if (currentPdf != null) {
        if (_pdfAsText) {
          // 通用上传论文的"扫描成文本"模式
          return _buildPdfTextContent();
        }
        if (_activePdfAsset != currentPdf) {
          _preparePdf(currentPdf);
        }
        return _buildPdfContent();
      }
    }

    // 2）西游记默认阅读页：
    // - _xyjPdfMode=true：展示 xyj.pdf
    // - _xyjPdfMode=false：保持文本阅读（支持高亮/批注）
    final currentPdf = _currentPdfAssetPath();
    if (currentPdf != null && _xyjPdfMode) {
      if (_activePdfAsset != currentPdf) {
        _preparePdf(currentPdf);
      }
      return _buildPdfContent();
    }

    // 3）文本模式：西游记 & 简·爱共用
    return _buildTextBookPagedContent();
  }

  // 仅文本模式下的分页阅读
  Widget _buildTextBookPagedContent() {
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

    // 判断是否是paper.pdf且在第2页
    final isPaperPdf = _isPaper && widget.pdfAssetPath != null && 
                       widget.pdfAssetPath!.contains('paper.pdf');
    final isPage2 = currentPage == 1; // PDF页面从0开始，第2页索引为1

    return Container(
      color: const Color(0xFFFDFBF7),
      child: Stack(
        children: [
          PDFView(
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
          // 在PDF上方叠加标记（仅paper.pdf第2页显示）
          if (isPaperPdf && isPage2)
            Positioned(
              // 标记位置：大约在第二段第二行的位置
              top: MediaQuery.of(context).size.height * 0.35, // 调整这个值来定位到正确位置
              left: MediaQuery.of(context).size.width * 0.65, // 调整这个值来定位到正确位置
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showKnowledgeCard = true;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartoonContent() {
    return Container(
      color: const Color(0xFFFDFBF7),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.asset(
            'assets/images/cartoon.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      '图片加载失败',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
    final contents = _activeBookContent
        .where((b) => b.type != 'title' && b.type != 'image_gen')
        .toList();
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
    if (_isJaneEyre) {
      final chapter = _activeChapters.first;

      final imageAssets = const [
        'assets/images/ja1.png',
        'assets/images/ja2.png',
        'assets/images/ja3.png',
        'assets/images/ja4.png',
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                chapter.title,
                style: const TextStyle(
                  fontSize: 22,
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
                'AI 小助手为你伴读《Jane Eyre》求婚场景',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...imageAssets.map((asset) {
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
                              child: const Text(
                                'AI生成插画',
                                style: TextStyle(
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
                      Icon(Icons.auto_awesome,
                          size: 16, color: Color(0xFF4F46E5)),
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

    final chapter = _activeChapters.firstWhere(
      (c) => c.chapterNumber == 59,
      orElse: () => _activeChapters.first,
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
        mainAxisSize: MainAxisSize.min,
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
                            child: const Text(
                              'AI生成插画',
                              style: TextStyle(
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

  // 简爱文本的翻译映射（写死）
  Map<String, String> get _janeEyreTranslations => {
    'a flock of': '一群',
    'garden': '花园',
    'wicket': '小门',
    'The trees were laden with ripening fruit; the garden was beautiful.': '树上结满了成熟的果实；花园很美。',
  };

  String _normalizeSelection(String s) {
    return s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  String? _getTranslation(String text) {
    if (!_isJaneEyre || !wordTranslationMode) return null;
    // 检查是否包含需要翻译的词或句子
    for (var entry in _janeEyreTranslations.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  Widget _buildReadingPage(List<BookContent> blocks) {
    final contentBlocks = _activeBookContent
        .where((b) => b.type != 'title' && b.type != 'image_gen')
        .toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
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
              final originalIndex = _activeBookContent.indexOf(block);
              
              // 如果是简爱且开启划词翻译模式，使用SelectableText并高亮需要翻译的词
              if (_isJaneEyre && wordTranslationMode) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: _buildTranslatableText(block, contentIndex, originalIndex),
                );
              }
              
              return GestureDetector(
                onTapDown: (details) {
                  // 点击：弹出两按钮菜单（深度探讨 / 深度探讨）
                  _handleTextTap(details, block);
                },
                onLongPress: () {
                  // 长按：仅对带下划线且有释义的块弹出释义，避免和"点击菜单"混淆
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
                        if (block.url != null && block.url!.isNotEmpty)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () => _showImagePreview(block.url!),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                child: Hero(
                                  tag: block.url!,
                                  child: Image.asset(
                                    block.url!,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
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
          ),
        );
      },
    );
  }

  Widget _buildTranslatableText(BookContent block, int contentIndex, int originalIndex) {
    final text = block.content;
    
    // 不自动高亮，只显示普通文本
    return SelectableText.rich(
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 17,
          height: 2.0,
          color: const Color(0xFF1C1917),
          fontFamily: 'serif',
          backgroundColor: block.highlight
              ? const Color(0xFFFEF3C7).withOpacity(0.8)
              : Colors.transparent,
        ),
        children: [
          if (block.url != null && block.url!.isNotEmpty)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => _showImagePreview(block.url!),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  child: Hero(
                    tag: block.url!,
                    child: Image.asset(
                      block.url!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      textAlign: TextAlign.justify,
      onSelectionChanged: (selection, cause) {
        // 当用户选择文本时，查找翻译并显示
        if (selection.isValid && !selection.isCollapsed) {
          final start = selection.start.clamp(0, text.length);
          final end = selection.end.clamp(0, text.length);
          if (start >= end) return;
          final selectedText = text.substring(start, end).trim();
          if (selectedText.isNotEmpty && selectedText != _lastSelectedText) {
            _lastSelectedText = selectedText;
            _lastSelectionTime = DateTime.now();
            
            // 防抖：延迟300ms，如果用户还在选择则取消
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              if (_isTranslationDialogOpen) return;
              // 检查是否还是同一个选择
              if (_lastSelectedText == selectedText && 
                  _lastSelectionTime != null &&
                  DateTime.now().difference(_lastSelectionTime!).inMilliseconds >= 300) {
                // 仅当“划词范围”与写死 key 完全一致时才显示翻译
                final selectedNorm = _normalizeSelection(selectedText);
                for (final entry in _janeEyreTranslations.entries) {
                  final keyNorm = _normalizeSelection(entry.key);
                  if (selectedNorm == keyNorm) {
                    _isTranslationDialogOpen = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;
                      await _showTranslationDialog(entry.key, entry.value);
                      if (mounted) {
                        _isTranslationDialogOpen = false;
                      }
                    });
                    break;
                  }
                }
              }
            });
          }
        } else {
          // 选择被取消或折叠
          _lastSelectedText = null;
          _lastSelectionTime = null;
        }
      },
    );
  }

  Future<void> _showTranslationDialog(String original, String translation) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.translate, color: Color(0xFFEC4899), size: 20),
              SizedBox(width: 8),
              Text('翻译', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 300, // 限制最大宽度避免溢出
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
                ),
                child: Text(
                  original,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'serif',
                    color: Color(0xFF1C1917),
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward, size: 16, color: Color(0xFFEC4899)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        translation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEC4899),
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
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
    final catalogChapters = _isJaneEyre
        ? _activeChapters
        : _activeChapters
            .where((c) => c.chapterNumber >= 59 && c.chapterNumber <= 63)
            .toList();
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
                                  Text(
                                    _activeFullBookSummary,
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
                        // 简爱选中Chapter XXIII (chapterNumber 23)，西游记选中59
                        final isSelected = _isJaneEyre 
                            ? chapter.chapterNumber == 23
                            : chapter.chapterNumber == 59;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
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
                                  color: isSelected
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
              _buildContextMenuItem(Icons.group, '深度探讨', () {
                setState(() {
                  contextMenu = null;
                  dashboardTargetTab = 'ai_helper';
                  injectedQuote = selectedQuote;
                  quoteVersion++;
                  showDashboard = true;
                });
              }),
              // _buildContextMenuItem(Icons.forum_outlined, '深度探讨', () {
              //   setState(() {
              //     contextMenu = null;
              //     dashboardTargetTab = 'deep';
              //     injectedQuote = selectedQuote;
              //     quoteVersion++;
              //     showDashboard = true;
              //   });
              // }), // 已注释：原来的深度探讨
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
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    
    // 按钮尺寸
    const buttonSize = 56.0;
    
    // 初始化位置（如果还未初始化）
    if (_floatingButtonPosition == null) {
      // 初始位置：右下角
      final bottomOffset = isListening ? 82.0 : 42.0;
      _floatingButtonPosition = Offset(
        screenSize.width - 24 - buttonSize, // right: 24, button width: 56
        screenSize.height - bottomOffset - buttonSize - safeAreaBottom, // bottom offset + button height
      );
    }
    
    // 计算实际显示位置（考虑安全区域）
    final displayX = _floatingButtonPosition!.dx.clamp(0.0, screenSize.width - buttonSize);
    final displayY = _floatingButtonPosition!.dy.clamp(
      safeAreaTop,
      screenSize.height - buttonSize - safeAreaBottom - (isListening ? 82 : 42),
    );
    
    return Positioned(
      left: displayX,
      top: displayY,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _dragStartGlobalPosition = details.globalPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            // 更新位置
            _floatingButtonPosition = Offset(
              (_floatingButtonPosition!.dx + details.delta.dx).clamp(0.0, screenSize.width - buttonSize),
              (_floatingButtonPosition!.dy + details.delta.dy).clamp(
                safeAreaTop,
                screenSize.height - buttonSize - safeAreaBottom - (isListening ? 82 : 42),
              ),
            );
          });
        },
        onPanEnd: (details) {
          final wasDragging = _isDragging;
          setState(() {
            _isDragging = false;
          });
          
          // 如果拖动距离很小，认为是点击事件
          final dragDistance = (details.globalPosition - _dragStartGlobalPosition).distance;
          if (dragDistance < 10 && wasDragging) {
            // 触发点击事件
            setState(() {
              showDashboard = true;
            });
            return;
          }
          
          // 吸附到最近的边缘
          final currentX = _floatingButtonPosition!.dx;
          final screenCenterX = screenSize.width / 2;
          
          // 判断应该吸附到左边还是右边
          final targetX = currentX < screenCenterX 
              ? 0.0  // 吸附到左边
              : screenSize.width - buttonSize; // 吸附到右边
          
          // 使用动画平滑移动到目标位置
          final targetPosition = Offset(
            targetX,
            _floatingButtonPosition!.dy,
          );
          
          // 使用动画平滑移动到目标位置
          _animateToPosition(targetPosition);
        },
        onTap: () {
          // 只有在没有拖动的情况下才触发点击
          if (!_isDragging) {
            setState(() {
              showDashboard = true;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDragging ? 0.3 : 0.2),
                blurRadius: _isDragging ? 12 : 8,
                spreadRadius: _isDragging ? 2 : 0,
                offset: Offset(0, _isDragging ? 4 : 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.lightbulb,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  // 动画移动到目标位置
  void _animateToPosition(Offset targetPosition) {
    if (_floatingButtonPosition == null) return;
    
    final startPosition = _floatingButtonPosition!;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
    
    animation.addListener(() {
      if (mounted) {
        setState(() {
          _floatingButtonPosition = Offset.lerp(
            startPosition,
            targetPosition,
            animation.value,
          )!;
        });
      }
    });
    
    controller.forward().then((_) {
      controller.dispose();
    });
  }

  String _getReviewerAvatarById(String reviewerId, String fallbackAvatar) {
    switch (reviewerId) {
      case 'wukong':
      case 'wukong_reviewer':
        return 'assets/images/sunwukong.png';
      case 'lindaiyu':
        return 'assets/images/lindaiyu.png';
      case 'luxun':
        return 'assets/images/luxun.png';
      case 'musk':
        return 'assets/images/masike.png';
      case 'goggins':
        return 'assets/images/daweigejinsi.png';
      case 'socrates':
      case 'socrates_reviewer':
        return 'assets/images/sugeladi.png';
      case 'mayun':
      case 'trump':
        return 'assets/images/mayun.png';
      case 'turing':
        return 'assets/images/tuling.png';
      case 'miyazaki':
        return 'assets/images/gongqijun.png';
      case 'wangyangming':
        return 'assets/images/wangyangming.png';
      case 'kobe':
        return 'assets/images/kebi.png';
      default:
        return fallbackAvatar;
    }
  }

  Widget _buildAvatarWidget(String avatar, {double size = 24}) {
    if (avatar.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: size * 0.8,
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Text(
      avatar,
      style: TextStyle(fontSize: size * 0.75),
    );
  }

  // 根据角色ID返回专属的浅色气泡颜色
  Color _getBubbleColorForRole(String reviewerId) {
    switch (reviewerId) {
      case 'trump':
        return const Color(0xFFFFF4E6); // 浅橙色（特朗普）
      case 'luxun':
        return const Color(0xFFF3F4F6); // 浅灰色（鲁迅）
      case 'miyazaki':
        return const Color(0xFFE6F7F0); // 浅绿色（宫崎骏）
      case 'wukong':
      case 'wukong_reviewer':
        return const Color(0xFFFFF9E6); // 浅黄色（孙悟空）
      case 'socrates':
      case 'socrates_reviewer':
        return const Color(0xFFF3E8FF); // 浅紫色（苏格拉底）
      case 'lindaiyu':
        return const Color(0xFFFFE6F0); // 浅粉色（林黛玉）
      case 'ai_helper':
      case 'ai_helper_modern':
        return const Color(0xFFE6F2FF); // 浅蓝色（AI助手）
      default:
        return const Color(0xFFF9FAFB); // 默认浅灰白色
    }
  }

  Widget _buildCommentPanel() {
    if (showCommentIndex == null) return const SizedBox.shrink();
    
    final comment = _activeComments[showCommentIndex];
    if (comment == null) return const SizedBox.shrink();

    // 过滤出马云、鲁迅、宫崎骏的评论
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 高亮文本
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                            // 评论列表 + 对话输入
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                        // 根据角色ID获取专属气泡颜色
                                        Color bubbleColor = _getBubbleColorForRole(annotation.reviewerId);
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 18),
                                          child: _buildAnnotationWithChat(annotation, bubbleColor),
                                        );
                                      }),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationPanel() {
    if (showExplanationIndex == null) return const SizedBox.shrink();
    
    final contentBlocks = _activeBookContent
        .where((b) => b.type != 'title' && b.type != 'image_gen')
        .toList();
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
                                'AI阅读笔记',
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
                            // 原文
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '原文',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
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
                              ],
                            ),
                            // AI 阅读笔记
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                'AI阅读笔记',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
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

  Widget _buildAnnotationWithChat(Annotation annotation, Color bubbleColor) {
    final threadId = _getAnnotationThreadId(annotation);
    final messages = _companionChats[threadId] ?? _getDefaultChatMessages(annotation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: _buildAvatarWidget(
                _getReviewerAvatarById(
                  annotation.reviewerId,
                  annotation.reviewerAvatar,
                ),
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      annotation.reviewerName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      annotation.comment,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildChatThread(
          threadId: threadId,
          reviewerName: annotation.reviewerName,
          reviewerAvatar: _getReviewerAvatarById(
            annotation.reviewerId,
            annotation.reviewerAvatar,
          ),
        ),
      ],
    );
  }

  Widget _buildChatThread({
    required String threadId,
    required String reviewerName,
    required String reviewerAvatar,
  }) {
    final showMessages = threadId.startsWith('luxun-17');
    final messages = showMessages
        ? (_companionChats[threadId] ?? const <_ChatMessage>[])
        : const <_ChatMessage>[];

    return Container(
      margin: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (messages.isNotEmpty) ...[
            ...messages.map((message) => _buildChatBubble(message)),
            const SizedBox(height: 6),
          ],
          _buildChatInput(
            threadId: threadId,
            reviewerName: reviewerName,
            reviewerAvatar: reviewerAvatar,
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage message) {
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6);
    final textColor = message.isUser ? const Color(0xFF0F172A) : const Color(0xFF1F2937);
    final bubbleRadius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 8, top: 2),
              child: _buildAvatarWidget(message.avatar, size: 22),
            ),
          Flexible(
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.7,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          if (message.isUser)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 8, top: 2),
              child: _buildAvatarWidget(message.avatar, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildChatInput({
    required String threadId,
    required String reviewerName,
    required String reviewerAvatar,
  }) {
    final controller = _chatControllers.putIfAbsent(
      threadId,
      () => TextEditingController(),
    );

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '输入想问的问题...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _handleSendMessage(
                threadId: threadId,
                reviewerName: reviewerName,
                reviewerAvatar: reviewerAvatar,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '发送',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendMessage({
    required String threadId,
    required String reviewerName,
    required String reviewerAvatar,
  }) {
    final controller = _chatControllers[threadId];
    if (controller == null) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      final messages = _companionChats.putIfAbsent(
        threadId,
        () => List<_ChatMessage>.from(_getDefaultChatMessagesByThread(threadId)),
      );
      messages.add(_ChatMessage.user(text, avatar: 'assets/images/yonghu.png'));
      messages.add(
        _ChatMessage.bot(
          _generateRoleReply(threadId, text),
          avatar: reviewerAvatar,
        ),
      );
      controller.clear();
    });
  }

  String _getAnnotationThreadId(Annotation annotation) {
    final contentId = showCommentIndex ?? 0;
    return '${annotation.reviewerId}-$contentId';
  }

  List<_ChatMessage> _getDefaultChatMessages(Annotation annotation) {
    final threadId = _getAnnotationThreadId(annotation);
    return _getDefaultChatMessagesByThread(threadId);
  }

  List<_ChatMessage> _getDefaultChatMessagesByThread(String threadId) {
    if (threadId.startsWith('luxun-17')) {
      return [];
    }

    return [
      _ChatMessage.bot(
        '我在这里等你发问。想从哪个角度聊聊？',
        avatar: '💬',
      ),
    ];
  }

  String _generateRoleReply(String threadId, String userText) {
    if (threadId.startsWith('luxun-17')) {
      if (userText.contains('看清掌扇的人之后')) {
        return '之后就别只停在“知道”，还要想办法“不再依赖”。先从三件事起：一是少欠那把扇子的情，把生计的一小块握回自己手里；二是互相结伴，把同样受困的人拢成一股力；三是学会识破“灵药”的话术，不再用迷信麻醉自己。能结伴就结伴，能自救就自救，把日子过成自己能掌的局面。简单说，就是把希望从“别人施舍”转回“自己能做什么”。';
      }
      return '要是真想走出火焰山，先别去问哪里有“扇子”。你得问：谁让你离不开扇子。看清掌扇的人，才谈得上怎么过这道关。简单来说，就是先看清是谁把路变成火焰山、谁在垄断“解药”，再谈怎么自救，而不是把希望全押在别人的施舍上。';
    }

    return '收到你的想法。我会继续从文本里找线索，也欢迎你继续追问。';
  }

  Widget _buildKnowledgeCard() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showKnowledgeCard = false;
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
                  maxWidth: 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.all(20),
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
                              Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFF6366F1)),
                              SizedBox(width: 8),
                              Text(
                                'AI知识卡片',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                showKnowledgeCard = false;
                              });
                            },
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // 内容
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1. Kaspi (2016) "贝叶斯估计模型" 是什么？',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '论文信息',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '这篇被引用的论文全名为 "Detection of unusable bicycles in bike-sharing systems" (发表于 Omega)。',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '模型简介',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '这是一个用于检测"隐性故障"车辆的概率模型。',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '核心逻辑',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBulletPoint('问题背景：用户借车后发现车是坏的，通常会立刻还车（往往还回同一个桩），且很少主动报修。系统显示该车"在桩且可用"，但实际上它是坏的。'),
                                  const SizedBox(height: 8),
                                  _buildBulletPoint('核心证据：利用行程持续时间（Trip Duration）作为核心证据。如果一辆车被借出后在极短时间内（例如2分钟内）被归还，它极大概率是坏车。'),
                                  const SizedBox(height: 8),
                                  _buildBulletPoint('贝叶斯方法：模型维护每辆车的"不可用概率"（Probability of Unusability, PoU）。每当发生一次借还车事件，模型就根据行程时长更新这辆车坏掉的后验概率。'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '2. 模型公式（基于原论文逻辑的重构）',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '虽然您提供的PDF中没有公式，但该模型的核心是标准的贝叶斯更新（Bayesian Update）。',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '假设：',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBulletPoint('HU：假设车辆是坏的（Unusable）'),
                                  _buildBulletPoint('HW：假设车辆是好的（Working/Usable）'),
                                  _buildBulletPoint('D：观测到的行程数据（主要是行程时间t）'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '贝叶斯公式：',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Text(
                                'P(HU|D) = (P(D|HU) × P(HU)) / (P(D|HU) × P(HU) + P(D|HW) × P(HW))',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '其中：',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBulletPoint('P(HU)：先验概率（Prior）。即在这次借车前，系统认为这辆车是坏车的概率。'),
                                  const SizedBox(height: 6),
                                  _buildBulletPoint('P(D|HU)：似然函数（Likelihood）。如果车是坏的，用户产生该行程时间t的概率（通常坏车的行程时间极短，集中在0-3分钟）。'),
                                  const SizedBox(height: 6),
                                  _buildBulletPoint('P(D|HW)：如果车是好的，用户产生该行程时间t的概率（通常服从正常的骑行时间分布，如对数正态分布）。'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '3. 直观理解',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '如果用户骑了30分钟才还车，那么P(D|HU)极小（坏车很难骑30分钟），计算出的后验概率 P(HU|D) 就会趋近于0（车是好的）。',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '反之，如果用户2分钟就还车了，且P(D|HU)很高，后验概率就会飙升，系统判定该车可能已损坏。',
                              style: TextStyle(
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

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
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
                                      '开启BGM沉浸式阅读',
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
                          // 划词翻译开关
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '划词翻译',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '开启后，可使用粉色荧光笔划词查看翻译',
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
                                value: wordTranslationMode,
                                onChanged: (value) {
                                  setState(() {
                                    wordTranslationMode = value;
                                    if (!value) {
                                      translatedWords.clear();
                                    }
                                  });
                                },
                                activeColor: const Color(0xFFEC4899), // 粉色
                              ),
                            ],
                          ),
                          // 扫描成文本：
                          // - 西游记：在 PDF / 文本两种模式间切换
                          // - 上传文档（论文 / 简·爱）：控制是否从 PDF 切到文字模式
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
                                        '关闭时阅读原始文档；开启后使用可高亮/批注的文本模式',
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
                          ] else ...[
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
                                        _isJaneEyre
                                            ? '关闭时阅读《简·爱》原始 PDF；开启后使用可高亮/批注的文本模式（当前节选章节）。'
                                            : '关闭时阅读原始 PDF 文档；开启后使用自动排版的文字模式（仅供预览）。',
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
                                  value: _pdfAsText,
                                  onChanged: (scanAsText) async {
                                    if (scanAsText) {
                                      if (_pdfPageTexts.isEmpty && !_isJaneEyre) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('正在从 PDF 中提取文字并优化排版，请稍候...'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                      await _ensurePdfText();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_isJaneEyre
                                              ? '已切换为《简·爱》原文「文字阅读模式」，可进行高亮、批注与释义。'
                                              : '已切换为「文字阅读模式」，向右滑动可继续翻页。'),
                                          duration: const Duration(seconds: 2),
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

