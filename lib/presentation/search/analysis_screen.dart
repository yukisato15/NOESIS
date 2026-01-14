import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/ai/ai_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';

/// 分析画面
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _queryController = TextEditingController();

  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _aiInsight;
  String? _customAnalysisResult;

  // 統計データ
  Map<String, int> _archiveCounts = {};
  Map<String, int> _tagFrequency = {};
  Map<String, int> _monthlyActivity = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // アーカイブ別カウント
      final dictCount = await _db.select(_db.dictionaryDefinitions).get();
      final conceptDictCount = await _db.select(_db.conceptDictionaries).get();
      final conceptMemoCount = await _db.conceptMemosDao.getAllConceptMemos();
      final dailyMemoCount = await _db.dailyMemosDao.getAllDailyMemos();
      final booksCount = await _db.booksDao.getAllBooks();
      final readingMemosCount = await _db.readingMemosDao.getAllMemos();
      final codeEntriesCount = await _db.codeEntriesDao.getAllCodeEntries();

      _archiveCounts = {
        '辞書': dictCount.length,
        '概念辞書': conceptDictCount.length,
        '思索メモ': conceptMemoCount.length,
        '日常メモ': dailyMemoCount.length,
        '書籍': booksCount.length,
        '読書メモ': readingMemosCount.length,
        'ITコード': codeEntriesCount.length,
      };

      // タグ頻度分析
      _tagFrequency = {};
      for (final dict in conceptDictCount) {
        if (dict.tags != null) {
          try {
            final tags = (jsonDecode(dict.tags!) as List).cast<String>();
            for (final tag in tags) {
              _tagFrequency[tag] = (_tagFrequency[tag] ?? 0) + 1;
            }
          } catch (_) {}
        }
      }
      for (final memo in dailyMemoCount) {
        if (memo.tags != null) {
          try {
            final tags = (jsonDecode(memo.tags!) as List).cast<String>();
            for (final tag in tags) {
              _tagFrequency[tag] = (_tagFrequency[tag] ?? 0) + 1;
            }
          } catch (_) {}
        }
      }

      // 月別アクティビティ
      _monthlyActivity = {};
      final now = DateTime.now();
      for (var i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MM月').format(month);
        _monthlyActivity[key] = 0;
      }

      // 各アーカイブの作成日をカウント
      for (final dict in conceptDictCount) {
        final key = DateFormat('MM月').format(dict.createdAt);
        if (_monthlyActivity.containsKey(key)) {
          _monthlyActivity[key] = _monthlyActivity[key]! + 1;
        }
      }
      for (final memo in dailyMemoCount) {
        final key = DateFormat('MM月').format(memo.createdAt);
        if (_monthlyActivity.containsKey(key)) {
          _monthlyActivity[key] = _monthlyActivity[key]! + 1;
        }
      }
      for (final code in codeEntriesCount) {
        final key = DateFormat('MM月').format(code.createdAt);
        if (_monthlyActivity.containsKey(key)) {
          _monthlyActivity[key] = _monthlyActivity[key]! + 1;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAIInsight() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final topTags = _tagFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final totalCount = _archiveCounts.values.fold(0, (sum, count) => sum + count);

      final prompt = '''
以下のデータから、ユーザーの学習傾向と洞察を分析してください。

【アーカイブ別登録数】
${_archiveCounts.entries.map((e) => '${e.key}: ${e.value}件').join('\n')}

【頻出タグ Top 5】
${topTags.take(5).map((e) => '${e.key}: ${e.value}回').join('\n')}

【総登録数】
$totalCount件

以下の形式で分析結果を返してください：

1. 学習の傾向（どの分野に注力しているか）
2. バランス評価（偏りがあるか、バランスが良いか）
3. 今後の推奨（どの分野を強化すべきか）
4. 気づき（データから見える特徴）

日本語で、励ましの言葉を含めて、わかりやすく書いてください。
''';

      final insight = await AIClient.instance.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      setState(() {
        _aiInsight = insight;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _executeCustomQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('質問を入力してください')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final prompt = '''
以下のデータに基づいて、ユーザーの質問に答えてください。

【アーカイブ別登録数】
${_archiveCounts.entries.map((e) => '${e.key}: ${e.value}件').join('\n')}

【頻出タグ】
${_tagFrequency.entries.map((e) => '${e.key}: ${e.value}回').join('\n')}

【月別アクティビティ】
${_monthlyActivity.entries.map((e) => '${e.key}: ${e.value}件').join('\n')}

【ユーザーの質問】
$query

具体的なデータを使って、わかりやすく答えてください。
''';

      final result = await AIClient.instance.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      setState(() {
        _customAnalysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('学習データ分析')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalCount = _archiveCounts.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習データ分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 統計サマリー
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: AppPalette.thinking),
                      const SizedBox(width: 8),
                      Text(
                        '統計サマリー',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '総登録数: $totalCount件',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppPalette.thinking,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _archiveCounts.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.soften(AppPalette.thinking, 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // アーカイブ分布円グラフ
          if (_archiveCounts.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アーカイブ分布',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _archiveCounts.entries.map((entry) {
                            final index = _archiveCounts.keys.toList().indexOf(entry.key);
                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title: '${entry.key}\n${entry.value}',
                              color: _getColorForIndex(index),
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 月別アクティビティ
          if (_monthlyActivity.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '月別登録数',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _monthlyActivity.values.isEmpty
                              ? 10
                              : _monthlyActivity.values.reduce((a, b) => a > b ? a : b).toDouble() + 5,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = _monthlyActivity.keys.toList();
                                  if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                    return Text(
                                      keys[value.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          barGroups: _monthlyActivity.entries.toList().asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value.toDouble(),
                                  color: AppPalette.thinking,
                                  width: 20,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 頻出タグ
          if (_tagFrequency.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '頻出タグ Top 10',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_tagFrequency.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .take(10)
                          .map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.soften(AppPalette.thinking, 0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${entry.key} (${entry.value})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // AI洞察分析
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: AppPalette.thinking),
                      const SizedBox(width: 8),
                      Text(
                        'AI洞察分析',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_aiInsight == null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isAnalyzing ? null : _generateAIInsight,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('AIで学習傾向を分析'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.thinking,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(_aiInsight!),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _aiInsight = null;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('再分析'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // カスタム分析クエリ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.question_answer, color: AppPalette.thinking),
                      const SizedBox(width: 8),
                      Text(
                        'カスタム分析',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: '質問を入力',
                      hintText: '例: 先月最も学んだ技術は？',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isAnalyzing ? null : _executeCustomQuery,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: const Text('分析実行'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.thinking,
                      ),
                    ),
                  ),
                  if (_customAnalysisResult != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    SelectableText(_customAnalysisResult!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppPalette.dictionaryGeneral,
      AppPalette.thinking,
      AppPalette.daily,
      AppPalette.reading,
      AppPalette.code,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}
