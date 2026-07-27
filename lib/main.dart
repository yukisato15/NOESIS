import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/ai/ai_client.dart';
import 'core/ai/search_client.dart';
import 'data/local/database.dart';
import 'presentation/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数読み込み
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('[main] .env could not be loaded: $error');
  }

  // AIクライアント初期化
  AIClient.initialize();
  SearchClient.initialize(
    baseUrl: dotenv.env['SEARCH_PROXY_BASE_URL'],
    googleApiKey: dotenv.env['GOOGLE_API_KEY'],
    googleSearchEngineId: dotenv.env['GOOGLE_SEARCH_ENGINE_ID'],
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF4EFE8);
    const surface = Color(0xFFFBFAF7);
    const primary = Color(0xFF2F3A3B);
    const secondary = Color(0xFF8C7A63);

    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.notoSansJpTextTheme(baseTextTheme).copyWith(
      headlineLarge: GoogleFonts.notoSerifJp(
        textStyle: baseTextTheme.headlineLarge,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineMedium: GoogleFonts.notoSerifJp(
        textStyle: baseTextTheme.headlineMedium,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: GoogleFonts.notoSerifJp(
        textStyle: baseTextTheme.titleLarge,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.notoSerifJp(
        textStyle: baseTextTheme.titleMedium,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.notoSansJp(
        textStyle: baseTextTheme.bodyLarge,
        color: primary,
      ),
      bodyMedium: GoogleFonts.notoSansJp(
        textStyle: baseTextTheme.bodyMedium,
        color: primary,
      ),
      bodySmall: GoogleFonts.notoSansJp(
        textStyle: baseTextTheme.bodySmall,
        color: primary,
      ),
      labelLarge: GoogleFonts.notoSansJp(
        textStyle: baseTextTheme.labelLarge,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );

    return MaterialApp(
      title: 'NOESIS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: surface,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: textTheme.titleLarge,
          iconTheme: const IconThemeData(color: primary),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primary.withValues(alpha: 0.28)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<DatabaseRuntimeStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = _loadStatus();
  }

  Future<DatabaseRuntimeStatus> _loadStatus() async {
    final db = AppDatabase();
    try {
      return await db.inspectRuntimeStatus();
    } finally {
      await db.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DatabaseRuntimeStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _StartupIssueScreen(
            title: '起動確認に失敗しました',
            description:
                'データベース状態の確認中にエラーが発生しました。このまま使うと保存済みデータを見失う可能性があります。',
            details: [snapshot.error.toString()],
            onRetry: () {
              setState(() {
                _statusFuture = _loadStatus();
              });
            },
          );
        }

        final status = snapshot.requireData;
        if (!status.isCompatible) {
          return _StartupIssueScreen(
            title: '古いアプリデータを開いています',
            description:
                '今のアプリが、読書表紙や音声保存に必要なテーブル/列を持たない古いDBを見ています。'
                ' この状態では表紙や音声が消えたように見えます。',
            details: [
              'DB schema version: ${status.userVersion}',
              ...status.issues,
              'DB path: ${status.databasePath}',
            ],
            onRetry: () {
              setState(() {
                _statusFuture = _loadStatus();
              });
            },
          );
        }

        return const HomeScreen();
      },
    );
  }
}

class _StartupIssueScreen extends StatelessWidget {
  final String title;
  final String description;
  final List<String> details;
  final VoidCallback onRetry;

  const _StartupIssueScreen({
    required this.title,
    required this.description,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFC97A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final detail in details) ...[
                          Text(
                            '• $detail',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: const Color(0xFFE86A00),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('再確認'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
