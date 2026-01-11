import 'package:flutter/material.dart';
import '../search/search_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../reading/reading_screen.dart';
import '../thinking/thinking_screen.dart';
import '../daily/daily_memo_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              const Color(0xFFF0E9DF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandHeader(),
                const SizedBox(height: 24),
                _ArchiveTile(
                  icon: ArchiveIconType.thinking,
                  title: '思索アーカイブ',
                  subtitle: '思考と概念を残す',
                  detail: '哲学的対話・概念辞書・概念メモ',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ThinkingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ArchiveTile(
                  icon: ArchiveIconType.reading,
                  title: '読書アーカイブ',
                  subtitle: '本ごとに残す',
                  detail: '本データ・読書メモ・読書感想',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReadingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ArchiveTile(
                  icon: ArchiveIconType.dictionary,
                  title: '辞書アーカイブ',
                  subtitle: '言葉を整理する',
                  detail: '一般辞書・英語辞書・IT用語辞書',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DictionaryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ArchiveTile(
                  icon: ArchiveIconType.daily,
                  title: '日常メモ',
                  subtitle: '短いメモを残す',
                  detail: '短文メモ・タスク・思いつき',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DailyMemoScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ArchiveTile(
                  icon: ArchiveIconType.search,
                  title: '検索',
                  subtitle: 'まとめて探す',
                  detail: '種類別・タグ・日付',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOESIS',
          style: theme.textTheme.headlineLarge?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '知を育成する',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

enum ArchiveIconType {
  thinking,
  reading,
  dictionary,
  daily,
  search,
}

class _ArchiveIcon extends StatelessWidget {
  final ArchiveIconType type;

  const _ArchiveIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withOpacity(0.8);
    return Center(
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _ArchiveIconPainter(type: type, color: color),
      ),
    );
  }
}

class _ArchiveIconPainter extends CustomPainter {
  final ArchiveIconType type;
  final Color color;

  _ArchiveIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case ArchiveIconType.thinking:
        _drawNode(canvas, const Offset(6, 7), paint);
        _drawNode(canvas, const Offset(22, 9), paint);
        _drawNode(canvas, const Offset(14, 22), paint);
        canvas.drawLine(const Offset(6, 7), const Offset(22, 9), paint);
        canvas.drawLine(const Offset(22, 9), const Offset(14, 22), paint);
        break;
      case ArchiveIconType.reading:
        final left = RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 6, 9, 16),
          const Radius.circular(3),
        );
        final right = RRect.fromRectAndRadius(
          const Rect.fromLTWH(15, 6, 9, 16),
          const Radius.circular(3),
        );
        canvas.drawRRect(left, paint);
        canvas.drawRRect(right, paint);
        canvas.drawLine(const Offset(14, 6), const Offset(14, 22), paint);
        break;
      case ArchiveIconType.dictionary:
        _drawNode(canvas, const Offset(8, 20), paint);
        _drawNode(canvas, const Offset(20, 8), paint);
        canvas.drawLine(const Offset(8, 20), const Offset(20, 8), paint);
        break;
      case ArchiveIconType.daily:
        _drawDot(canvas, const Offset(9, 9), paint);
        _drawDot(canvas, const Offset(19, 9), paint);
        _drawDot(canvas, const Offset(9, 19), paint);
        _drawDot(canvas, const Offset(19, 19), paint);
        break;
      case ArchiveIconType.search:
        _drawNode(canvas, const Offset(10, 11), paint, radius: 5);
        _drawNode(canvas, const Offset(20, 19), paint, radius: 3);
        canvas.drawLine(const Offset(14, 14), const Offset(17, 17), paint);
        break;
    }
  }

  void _drawNode(Canvas canvas, Offset center, Paint paint,
      {double radius = 3}) {
    canvas.drawCircle(center, radius, paint);
  }

  void _drawDot(Canvas canvas, Offset center, Paint paint) {
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArchiveTile extends StatelessWidget {
  final ArchiveIconType icon;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  const _ArchiveTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.background.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _ArchiveIcon(type: icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
