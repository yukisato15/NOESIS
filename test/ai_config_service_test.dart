import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noesis_flutter/core/ai/ai_client.dart';
import 'package:noesis_flutter/core/ai/ai_config_service.dart';
import 'package:noesis_flutter/core/ai/local_llm_provider.dart';
import 'package:noesis_flutter/core/ai/openai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIConfigService & AIClient Provider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('デフォルトプロバイダーの取得と切替', () async {
      final config = await AIConfigService.getInstance();
      expect(config.providerType, equals(AIProviderType.localLlm));

      await config.setProviderType(AIProviderType.openAI);
      expect(config.providerType, equals(AIProviderType.openAI));

      await config.setOpenAIApiKey('sk-test-key-12345');
      expect(config.openAIApiKey, equals('sk-test-key-12345'));
    });

    test('AIClient のプロバイダー初期化と機能検証', () async {
      final config = await AIConfigService.getInstance();
      await config.setProviderType(AIProviderType.localLlm);

      await AIClient.initialize();
      expect(AIClient.instance.activeProvider, isA<LocalLLMProvider>());

      final response = await AIClient.instance.chat(messages: []);
      expect(response, contains('ローカル'));
    });

    test('OpenAI プロバイダーへの切替テスト', () async {
      final config = await AIConfigService.getInstance();
      await config.setProviderType(AIProviderType.openAI);
      await config.setOpenAIApiKey('sk-test-key-abc');

      await AIClient.initialize();
      expect(AIClient.instance.activeProvider, isA<OpenAIProvider>());
      expect(AIClient.instance.providerName, contains('OpenAI'));
    });
  });
}
