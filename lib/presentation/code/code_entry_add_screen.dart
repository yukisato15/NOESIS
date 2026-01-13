import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/live_text_image_view.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/local/tables/code_entries_table.dart';
import '../../data/local/tables/code_entry_entries_table.dart';

/// コードエントリー追加画面
/// 複数画像からコードを抽出し、AI解析を行う
class CodeEntryAddScreen extends ConsumerStatefulWidget {
  const CodeEntryAddScreen({super.key});

  @override
  ConsumerState<CodeEntryAddScreen> createState() => _CodeEntryAddScreenState();
}

class _CodeEntryAddScreenState extends ConsumerState<CodeEntryAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();

  final List<XFile> _sourceImages = [];
  CodeEntryType _entryType = CodeEntryType.whole;
  bool _isSaving = false;
  bool _isAnalyzing = false;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _sourceImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撮影に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _sourceImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像選択に失敗しました: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _sourceImages.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _sourceImages.removeAt(oldIndex);
      _sourceImages.insert(newIndex, item);
    });
  }

  Future<void> _extractTextFromImages() async {
    if (_sourceImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像が選択されていません')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      StringBuffer extractedCode = StringBuffer();

      for (final image in _sourceImages) {
        // Live Text機能を使ってテキストを抽出
        final text = await _extractTextFromImage(image);
        if (text.isNotEmpty) {
          extractedCode.write(text);
          extractedCode.write('\n\n');
        }
      }

      if (extractedCode.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('テキストを抽出できませんでした')),
          );
        }
      } else {
        setState(() {
          _codeController.text = extractedCode.toString().trim();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('テキスト抽出に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<String> _extractTextFromImage(XFile image) async {
    // LiveTextImageViewのロジックを使用してテキストを抽出
    // ここでは簡易的にダイアログを表示して抽出したテキストを返す
    String? extractedText;

    if (!mounted) return '';

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: LiveTextImageView(
          imagePath: image.path,
        ),
      ),
    );

    // Note: テキスト抽出は手動で行う必要があります
    // LiveTextImageViewから抽出されたテキストを取得する仕組みが必要

    return extractedText ?? '';
  }

  Future<Map<String, dynamic>?> _analyzeCode(String code) async {
    try {
      final prompt = '''
以下のコードを詳細に解析して、学習に必要な情報を網羅的に抽出してください。
とにかく丁寧に、初心者でも理解できるように説明してください。

【コード】
$code

以下の情報を生成してください：

【基本情報】
1. language: プログラミング言語名（例: Python, JavaScript, Dart, Java, C++など）
2. libraries: 使用されているライブラリやフレームワークのリスト（配列）
3. structure: コードの構造説明（クラス、関数、変数の構成など）
4. capabilities: このコードができること、機能の説明
5. useCases: 実際の用途や使用例
6. learningPoints: このコードから学べる重要なポイント

【関連コード】
7. synonymousCodes: 類義のコード（同じ目的を達成する別の書き方、配列）
8. antonymousCodes: 対義のコード（逆の動作をするコード、配列）
9. relatedCodes: 関連するコード（一緒に使われることが多いコード、配列）
10. examples: 具体的な使用例（実際の使い方を示すコード例、配列）

【学習サポート】
11. cautions: 使用上の注意点や落とし穴
12. trivia: 面白エピソードやトリビア（このコードの歴史や由来など）
13. tips: ワンポイントアドバイス（プロが知っているコツ）
14. commonMistakes: よくある誤用や間違い

【わかりやすい説明】
15. gyaruExplanation: ギャル風の親しみやすい説明（「マジで」「ヤバい」など使って）
16. kindergartenExplanation: 幼稚園児でも理解できる説明（身近な例えで）
''';

      final schema = {
        'type': 'object',
        'properties': {
          'language': {'type': 'string', 'description': 'プログラミング言語名'},
          'libraries': {'type': 'array', 'items': {'type': 'string'}, 'description': 'ライブラリリスト'},
          'structure': {'type': 'string', 'description': 'コードの構造説明'},
          'capabilities': {'type': 'string', 'description': 'このコードができること'},
          'useCases': {'type': 'string', 'description': '実際の用途や使用例'},
          'learningPoints': {'type': 'string', 'description': '学習ポイント'},
          'synonymousCodes': {'type': 'array', 'items': {'type': 'string'}, 'description': '類義のコード'},
          'antonymousCodes': {'type': 'array', 'items': {'type': 'string'}, 'description': '対義のコード'},
          'relatedCodes': {'type': 'array', 'items': {'type': 'string'}, 'description': '関連するコード'},
          'examples': {'type': 'array', 'items': {'type': 'string'}, 'description': '具体例'},
          'cautions': {'type': 'string', 'description': '使用上の注意'},
          'trivia': {'type': 'string', 'description': '面白エピソード・トリビア'},
          'tips': {'type': 'string', 'description': 'ワンポイントアドバイス'},
          'commonMistakes': {'type': 'string', 'description': 'よくある誤用・間違い'},
          'gyaruExplanation': {'type': 'string', 'description': 'ギャルによる説明'},
          'kindergartenExplanation': {'type': 'string', 'description': '幼稚園児向け説明'},
        },
        'required': ['language', 'structure', 'capabilities', 'useCases', 'learningPoints',
                     'cautions', 'tips', 'commonMistakes', 'gyaruExplanation', 'kindergartenExplanation']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      return result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI解析に失敗しました: $e')),
        );
      }
      return null;
    }
  }

  /// OCRで読み取ったコードをAIで修正する
  Future<String?> _fixOcrCode(String ocrText) async {
    try {
      final prompt = '''
以下はOCRで読み取ったコードですが、縦番号（1, 2, 3...）が混入していたり、
文字認識ミスがある可能性があります。
プログラミングコードとして正しく動作するように修正してください。

【OCRで読み取ったテキスト】
$ocrText

以下の作業を行ってください：
1. 行頭の縦番号（1, 2, 3, 4...）を削除する
2. よくあるOCR誤字を修正する（例: l→I、O→0、など）
3. 構文エラーがあれば修正する
4. インデントを適切に整える
5. 不要な空白や改行を削除する

修正後のコードのみを返してください（説明は不要です）。
''';

      final schema = {
        'type': 'object',
        'properties': {
          'fixedCode': {
            'type': 'string',
            'description': '修正後のコード'
          },
          'corrections': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '修正した内容のリスト'
          },
        },
        'required': ['fixedCode']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      return result['fixedCode'] as String;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('コード修正に失敗しました: $e')),
        );
      }
      return null;
    }
  }

  /// OCRコード修正ボタンの処理
  Future<void> _fixCodeWithAI() async {
    final currentCode = _codeController.text.trim();
    if (currentCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コードを入力してください')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AIがコードを修正中...'),
          duration: Duration(seconds: 2),
        ),
      );

      final fixedCode = await _fixOcrCode(currentCode);
      if (fixedCode != null) {
        setState(() {
          _codeController.text = fixedCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コードを修正しました')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveCodeEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コードを入力してください')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // AI解析を実行
      Map<String, dynamic>? analysis;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AIでコードを解析中...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      analysis = await _analyzeCode(code);

      // データベースに保存
      final codeEntryId = await _db.codeEntriesDao.insertCodeEntry(
        CodeEntriesCompanion.insert(
          title: title.isEmpty ? 'コード記録' : title,
          code: code,
          entryType: _entryType,
          // 基本情報
          language: analysis != null
              ? Value(analysis['language'] as String)
              : const Value.absent(),
          libraries: analysis != null && analysis['libraries'] != null
              ? Value(jsonEncode(analysis['libraries']))
              : const Value.absent(),
          structure: analysis != null
              ? Value(analysis['structure'] as String)
              : const Value.absent(),
          capabilities: analysis != null
              ? Value(analysis['capabilities'] as String)
              : const Value.absent(),
          useCases: analysis != null
              ? Value(analysis['useCases'] as String)
              : const Value.absent(),
          learningPoints: analysis != null
              ? Value(analysis['learningPoints'] as String)
              : const Value.absent(),
          // 関連コード
          synonymousCodes: analysis != null && analysis['synonymousCodes'] != null
              ? Value(jsonEncode(analysis['synonymousCodes']))
              : const Value.absent(),
          antonymousCodes: analysis != null && analysis['antonymousCodes'] != null
              ? Value(jsonEncode(analysis['antonymousCodes']))
              : const Value.absent(),
          relatedCodes: analysis != null && analysis['relatedCodes'] != null
              ? Value(jsonEncode(analysis['relatedCodes']))
              : const Value.absent(),
          examples: analysis != null && analysis['examples'] != null
              ? Value(jsonEncode(analysis['examples']))
              : const Value.absent(),
          // 学習サポート
          cautions: analysis != null
              ? Value(analysis['cautions'] as String)
              : const Value.absent(),
          trivia: analysis != null
              ? Value(analysis['trivia'] as String)
              : const Value.absent(),
          tips: analysis != null
              ? Value(analysis['tips'] as String)
              : const Value.absent(),
          commonMistakes: analysis != null
              ? Value(analysis['commonMistakes'] as String)
              : const Value.absent(),
          gyaruExplanation: analysis != null
              ? Value(analysis['gyaruExplanation'] as String)
              : const Value.absent(),
          kindergartenExplanation: analysis != null
              ? Value(analysis['kindergartenExplanation'] as String)
              : const Value.absent(),
        ),
      );

      // オリジナルエントリを追加
      await _db.codeEntryEntriesDao.insertEntry(
        CodeEntryEntriesCompanion.insert(
          codeEntryId: codeEntryId,
          entryType: CodeEntryEntryType.original,
          content: code,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(codeEntryId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コード記録'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCodeEntry,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // タイトル入力
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: '関数名やクラス名など',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // オプション
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // エントリタイプ選択
            SegmentedButton<CodeEntryType>(
              segments: const [
                ButtonSegment(
                  value: CodeEntryType.whole,
                  label: Text('コード全体'),
                  icon: Icon(Icons.code),
                ),
                ButtonSegment(
                  value: CodeEntryType.function,
                  label: Text('関数単位'),
                  icon: Icon(Icons.functions),
                ),
                ButtonSegment(
                  value: CodeEntryType.block,
                  label: Text('ブロック'),
                  icon: Icon(Icons.view_compact),
                ),
              ],
              selected: {_entryType},
              onSelectionChanged: (Set<CodeEntryType> selected) {
                setState(() {
                  _entryType = selected.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // 画像選択エリア
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image),
                        const SizedBox(width: 8),
                        const Text(
                          '画像からコードを抽出',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('カメラ'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('写真'),
                        ),
                        const Spacer(),
                        if (_sourceImages.isNotEmpty)
                          FilledButton.icon(
                            onPressed: _isAnalyzing ? null : _extractTextFromImages,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_fix_high),
                            label: const Text('テキスト化'),
                          ),
                      ],
                    ),
                    if (_sourceImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        '${_sourceImages.length}枚の画像（長押しで並び替え）',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _sourceImages.length,
                          onReorder: _reorderImages,
                          itemBuilder: (context, index) {
                            return Stack(
                              key: ValueKey(_sourceImages[index].path),
                              children: [
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_sourceImages[index].path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.broken_image),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // コード入力
            TextFormField(
              controller: _codeController,
              maxLines: 20,
              decoration: const InputDecoration(
                labelText: 'コード',
                hintText: 'コードを入力または画像から抽出',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'コードを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // AIコード修正ボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _fixCodeWithAI,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('AIでコードを修正（OCR誤字・縦番号削除）'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.code,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
