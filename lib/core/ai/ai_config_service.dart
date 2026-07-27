import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_llm_model_info.dart';

enum AIProviderType {
  localLlm('オンデバイス AI (ローカルLLM)', '端末内で動作・通信不要・完全無料'),
  openAI('OpenAI API (Cloud)', 'GPT-4o / GPT-4o-mini 等を使用'),
  gemini('Google Gemini API (Cloud)', 'Gemini Flash / Pro 等を使用');

  final String label;
  final String description;

  const AIProviderType(this.label, this.description);
}

class AIConfigService {
  static const String _keyProviderType = 'ai_provider_type';
  static const String _keyOpenAIKey = 'openai_api_key';
  static const String _keyGeminiKey = 'gemini_api_key';
  static const String _keyLocalModelPath = 'local_llm_model_path';
  static const String _keyLocalModelDownloaded = 'local_llm_model_downloaded';
  static const String _keyLocalModelPreset = 'local_llm_model_preset';
  static const String _keyQualityPriority = 'local_llm_quality_priority';

  static AIConfigService? _instance;
  final SharedPreferences _prefs;

  AIConfigService._(this._prefs);

  static Future<AIConfigService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = AIConfigService._(prefs);
    }
    return _instance!;
  }

  /// 現在選択されているプロバイダー種別
  AIProviderType get providerType {
    final raw = _prefs.getString(_keyProviderType);
    if (raw != null) {
      for (final type in AIProviderType.values) {
        if (type.name == raw) {
          return type;
        }
      }
    }
    // デフォルト: OPENAI_API_KEY が .env にある場合は OpenAI、無ければ LocalLLM
    final envOpenAI =
        dotenv.isInitialized ? dotenv.env['OPENAI_API_KEY'] : null;
    if (envOpenAI != null && envOpenAI.isNotEmpty) {
      return AIProviderType.openAI;
    }
    return AIProviderType.localLlm;
  }

  /// プロバイダー種別の設定
  Future<bool> setProviderType(AIProviderType type) async {
    return await _prefs.setString(_keyProviderType, type.name);
  }

  /// OpenAI APIキー（ユーザー設定値がある場合はそれを優先、無ければ .env から取得）
  String get openAIApiKey {
    final customKey = _prefs.getString(_keyOpenAIKey);
    if (customKey != null && customKey.isNotEmpty) {
      return customKey;
    }
    return dotenv.isInitialized ? (dotenv.env['OPENAI_API_KEY'] ?? '') : '';
  }

  Future<bool> setOpenAIApiKey(String key) async {
    return await _prefs.setString(_keyOpenAIKey, key.trim());
  }

  /// Gemini APIキー
  String get geminiApiKey {
    final customKey = _prefs.getString(_keyGeminiKey);
    if (customKey != null && customKey.isNotEmpty) {
      return customKey;
    }
    return dotenv.isInitialized ? (dotenv.env['GEMINI_API_KEY'] ?? '') : '';
  }

  Future<bool> setGeminiApiKey(String key) async {
    return await _prefs.setString(_keyGeminiKey, key.trim());
  }

  /// ローカルLLMモデルの保存パス
  String? get localModelPath {
    return _prefs.getString(_keyLocalModelPath);
  }

  Future<bool> setLocalModelPath(String path) async {
    return await _prefs.setString(_keyLocalModelPath, path);
  }

  /// ローカルモデルがダウンロード済みか
  bool get isLocalModelDownloaded {
    return _prefs.getBool(_keyLocalModelDownloaded) ?? false;
  }

  Future<bool> setLocalModelDownloaded(bool downloaded) async {
    return await _prefs.setBool(_keyLocalModelDownloaded, downloaded);
  }

  /// 選択されているローカルモデルプリセット
  LocalModelPreset get activeModelPreset {
    final raw = _prefs.getString(_keyLocalModelPreset);
    if (raw != null) {
      for (final preset in LocalModelPreset.values) {
        if (preset.id == raw) {
          return preset;
        }
      }
    }
    return LocalModelPreset.qwen15B;
  }

  Future<bool> setActiveModelPreset(LocalModelPreset preset) async {
    return await _prefs.setString(_keyLocalModelPreset, preset.id);
  }

  /// クオリティ優先モード（対話・解説時に自動で高品質3Bモデルへルーティング）
  bool get isQualityPriorityMode {
    return _prefs.getBool(_keyQualityPriority) ?? true;
  }

  Future<bool> setQualityPriorityMode(bool enabled) async {
    return await _prefs.setBool(_keyQualityPriority, enabled);
  }
}
