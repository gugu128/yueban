import 'package:flutter/material.dart';
import 'package:reading/pages/home_screen.dart';
import 'package:reading/pages/scan_screen.dart';
import 'package:reading/pages/intent_screen.dart';
import 'package:reading/pages/companion_selection_screen.dart';
import 'package:reading/pages/reader_screen.dart';
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

  void navigateTo(
    String screen, {
    String? intent,
    List<Role>? companions,
    bool? groupMode,
    String? pdfPath,
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
          onUpload: () => navigateTo('scan', pdfPath: '__doc_chooser__'),
        );
      case 'scan':
        final isDocChooser = pdfAssetPath == '__doc_chooser__';
        return ScanScreen(
          onFinish: () => navigateTo('intent'),
          showDocChooser: isDocChooser,
          onChooseA: isDocChooser ? () => navigateTo('pdf_reader', pdfPath: 'assets/PDF/paper.pdf') : null,
          onChooseB: isDocChooser
              ? () => navigateTo('pdf_reader', pdfPath: 'assets/PDF/Jane Eyre Selected Chapters.pdf')
              : null,
        );
      case 'intent':
        return IntentScreen(
          onConfirm: (intent) => navigateTo('companion', intent: intent),
        );
      case 'companion':
        return CompanionSelectionScreen(
          onConfirm: (companions, groupMode) => navigateTo(
            'reader',
            companions: companions,
            groupMode: groupMode,
          ),
        );
      case 'reader':
        return ReaderScreen(
          intent: selectedIntent,
          selectedCompanions: selectedCompanions,
          isGroupMode: isGroupMode,
          onBack: () => navigateTo('home'),
        );
      case 'pdf_reader':
        return ReaderScreen(
          pdfAssetPath: pdfAssetPath ?? 'assets/PDF/paper.pdf',
          selectedCompanions: selectedCompanions,
          isGroupMode: isGroupMode,
          onBack: () => navigateTo('home'),
        );
      default:
        return HomeScreen(
          onScan: () => navigateTo('scan'),
          onUpload: () => navigateTo('scan', pdfPath: '__doc_chooser__'),
        );
    }
  }
}

