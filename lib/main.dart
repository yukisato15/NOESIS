import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/ai/ai_client.dart';
import 'presentation/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数読み込み
  await dotenv.load(fileName: ".env");

  // AIクライアント初期化
  AIClient.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
          background: background,
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
            borderSide: BorderSide(color: primary.withOpacity(0.28)),
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
      home: const HomeScreen(),
    );
  }
}
