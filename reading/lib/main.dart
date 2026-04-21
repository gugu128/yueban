import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:reading/pages/home_screen.dart';
import 'package:reading/pages/scan_screen.dart';
import 'package:reading/pages/intent_screen.dart';
import 'package:reading/pages/companion_selection_screen.dart';
import 'package:reading/pages/reader_screen.dart';
import 'package:reading/pages/analysis_screen.dart';
import 'package:reading/models/book_content.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI伴读',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // indigo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // gray-50
      ),
      home: const AppContainer(),
    );
  }
}

// 主容器，管理屏幕切换
class AppContainer extends StatefulWidget {
  const AppContainer({super.key});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  String currentScreen = 'home';
  String? selectedIntent;
  List<Role> selectedCompanions = [];
  bool isGroupMode = false;
  String? pdfAssetPath;
  String? pendingFileName;

  void navigateTo(
    String screen, {
    String? intent,
    List<Role>? companions,
    bool? groupMode,
    String? pdfPath,
    String? fileName,
  }) {
    setState(() {
      currentScreen = screen;
      if (intent != null) {
        selectedIntent = intent;
      }
      if (companions != null) {
        selectedCompanions = companions;
      }
      if (groupMode != null) {
        isGroupMode = groupMode;
      }
      if (pdfPath != null) {
        pdfAssetPath = pdfPath;
      }
      if (fileName != null) {
        pendingFileName = fileName;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreenContent(),
    );
  }

  Widget _buildScreenContent() {
    switch (currentScreen) {
      case 'home':
        return HomeScreen(
          onScan: () => navigateTo('scan'),
          onUpload: _pickDocumentAndNavigate,
        );
      case 'analysis':
        final fileName = pendingFileName ?? '';
        final cfg = _analysisConfigFor(fileName);
        return AnalysisScreen(
          title: cfg.$1,
          subtitle: cfg.$2,
          duration: cfg.$3,
          onFinished: () {
            final normalized = fileName.toLowerCase();
            if (normalized == 'jane eyre selected chapters.pdf') {
              navigateTo(
                'intent',
                pdfPath: 'assets/PDF/Jane Eyre Selected Chapters.pdf',
                fileName: fileName,
              );
            } else if (normalized == 'journey to the west.pdf') {
              navigateTo(
                'intent',
                pdfPath: 'assets/PDF/Journey to the West.pdf',
                fileName: fileName,
              );
            } else if (normalized == 'paper.pdf') {
              navigateTo(
                'intent',
                pdfPath: 'assets/PDF/paper.pdf',
                fileName: fileName,
              );
            } else if (normalized == 'cartoon.png') {
              navigateTo(
                'intent',
                pdfPath: '__cartoon__',
                fileName: fileName,
              );
            } else {
              navigateTo('scan', pdfPath: '__doc_chooser__');
            }
          },
        );
      case 'scan':
        final isDocChooser = pdfAssetPath == '__doc_chooser__';
        return ScanScreen(
          onFinish: () => navigateTo('intent'),
          showDocChooser: isDocChooser,
          onChooseA: isDocChooser ? () => navigateTo('intent', pdfPath: 'assets/PDF/paper.pdf') : null,
          onChooseB: isDocChooser
              ? () => navigateTo('intent', pdfPath: 'assets/PDF/Jane Eyre Selected Chapters.pdf')
              : null,
          onChooseC: isDocChooser ? () => navigateTo('intent', pdfPath: '__cartoon__') : null,
        );
      case 'intent':
        return IntentScreen(
          onConfirm: (intent) => navigateTo('companion', intent: intent),
        );
      case 'companion':
        return CompanionSelectionScreen(
          bookId: pdfAssetPath == '__cartoon__'
              ? 'cartoon'
              : (pdfAssetPath != null && pdfAssetPath != '__doc_chooser__'
                  ? (pdfAssetPath!.contains('Jane Eyre')
                      ? 'jane_eyre'
                      : (pdfAssetPath!.contains('Journey to the West') ? 'xyj' : 'paper'))
                  : 'xyj'),
          onConfirm: (companions, groupMode) {
            if (pdfAssetPath == '__cartoon__') {
              navigateTo('cartoon_reader', companions: companions, groupMode: groupMode);
            } else if (pdfAssetPath != null && pdfAssetPath != '__doc_chooser__') {
              final isJane = pdfAssetPath!.contains('Jane Eyre');
              final isJourney = pdfAssetPath!.contains('Journey to the West');
              if (isJane) {
                navigateTo('pdf_reader', companions: companions, groupMode: groupMode);
              } else if (isJourney) {
                navigateTo('reader', companions: companions, groupMode: groupMode);
              } else {
                navigateTo('pdf_reader', companions: companions, groupMode: groupMode);
              }
            } else {
              navigateTo('reader', companions: companions, groupMode: groupMode);
            }
          },
        );
      case 'reader':
        return ReaderScreen(
          intent: selectedIntent,
          selectedCompanions: selectedCompanions,
          isGroupMode: isGroupMode,
          onBack: () => navigateTo('home'),
          bookId: pdfAssetPath == 'assets/PDF/Journey to the West.pdf' ? 'xyj' : 'xyj',
          pdfAssetPath: pdfAssetPath == 'assets/PDF/Journey to the West.pdf'
              ? 'assets/PDF/Journey to the West.pdf'
              : null,
        );
      case 'pdf_reader':
        final path = pdfAssetPath ?? 'assets/PDF/paper.pdf';
        final bookId = path.contains('Jane Eyre') ? 'jane_eyre' : 'paper';
        return ReaderScreen(
          intent: selectedIntent,
          pdfAssetPath: path,
          bookId: bookId,
          selectedCompanions: selectedCompanions,
          isGroupMode: isGroupMode,
          onBack: () => navigateTo('home'),
        );
      case 'cartoon_reader':
        return ReaderScreen(
          intent: selectedIntent,
          pdfAssetPath: '__cartoon__',
          bookId: 'cartoon',
          selectedCompanions: selectedCompanions,
          isGroupMode: isGroupMode,
          onBack: () => navigateTo('home'),
        );
      default:
        return HomeScreen(
          onScan: () => navigateTo('scan'),
          onUpload: _pickDocumentAndNavigate,
        );
    }
  }

  Future<void> _pickDocumentAndNavigate() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择要上传的文档',
      allowMultiple: false,
      type: FileType.any,
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final fileName = result.files.first.name;
    navigateTo('analysis', fileName: fileName);
  }

  (String, String, Duration) _analysisConfigFor(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized == 'jane eyre selected chapters.pdf') {
      return (
        '正在分析《简爱》节选',
        '系统正在识别章节、人物关系与可阅读段落...',
        const Duration(seconds: 2),
      );
    }
    if (normalized == 'journey to the west.pdf') {
      return (
        '正在分析《西游记》文档',
        '系统正在识别回目、人物与段落结构...',
        const Duration(milliseconds: 1500),
      );
    }
    if (normalized == 'paper.pdf') {
      return (
        '正在分析论文',
        '系统正在识别摘要、标题与知识点...',
        const Duration(milliseconds: 1500),
      );
    }
    if (normalized == 'cartoon.png') {
      return (
        '正在分析漫画图片',
        '系统正在识别画面元素与主题含义...',
        const Duration(milliseconds: 1500),
      );
    }
    return (
      '正在分析文档',
      '系统正在识别文档类型与内容...',
      const Duration(milliseconds: 1200),
    );
  }
}

