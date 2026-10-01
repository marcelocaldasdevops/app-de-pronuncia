import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenRouterModel {
  final String id;
  final String name;
  final String provider;
  final bool isFree;
  final String type; // 'tts', 'stt', 'chat'

  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.isFree,
    required this.type,
  });
}

class OpenRouterService {
  static const String _kApiKeyPref = 'vocalis_openrouter_api_key';
  static const String _kDefaultTtsModel = 'fish-audio/s2.1-pro:free';
  static const String _kDefaultSttModel = 'openai/whisper-large-v3';

  String _apiKey = '';

  String get apiKey => _apiKey;
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  // Modelos recomendados e gratuitos no OpenRouter
  static const List<OpenRouterModel> availableModels = [
    // TTS (Síntese de Voz)
    OpenRouterModel(
      id: 'fish-audio/s2.1-pro:free',
      name: 'Fish Audio S2.1 Pro (Free)',
      provider: 'Fish Audio',
      isFree: true,
      type: 'tts',
    ),
    OpenRouterModel(
      id: 'deepgram/flux:free',
      name: 'Deepgram Flux TTS (Free)',
      provider: 'Deepgram',
      isFree: true,
      type: 'tts',
    ),
    OpenRouterModel(
      id: 'openai/tts-1',
      name: 'OpenAI TTS-1 HD',
      provider: 'OpenAI',
      isFree: false,
      type: 'tts',
    ),

    // STT (Transcrição de Áudio)
    OpenRouterModel(
      id: 'openai/whisper-large-v3',
      name: 'OpenAI Whisper Large V3',
      provider: 'OpenAI',
      isFree: false,
      type: 'stt',
    ),
    OpenRouterModel(
      id: 'openai/whisper-large-v3-turbo',
      name: 'OpenAI Whisper Large V3 Turbo',
      provider: 'OpenAI',
      isFree: false,
      type: 'stt',
    ),

    // LLMs de Avaliação Acústica e Fonética (Chat Completions)
    OpenRouterModel(
      id: 'google/gemini-2.0-flash-exp:free',
      name: 'Gemini 2.0 Flash (Free)',
      provider: 'Google',
      isFree: true,
      type: 'chat',
    ),
    OpenRouterModel(
      id: 'meta-llama/llama-3.3-70b-instruct:free',
      name: 'Llama 3.3 70B Instruct (Free)',
      provider: 'Meta',
      isFree: true,
      type: 'chat',
    ),
  ];

  OpenRouterService() {
    _loadKey();
  }

  Future<void> _loadKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_kApiKeyPref) ?? '';
    } catch (_) {}
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kApiKeyPref, _apiKey);
    } catch (_) {}
  }

  /// Gera áudio através do endpoint TTS do OpenRouter
  Future<Uint8List?> synthesizeSpeech(
    String text, {
    String model = _kDefaultTtsModel,
    String voice = 'alloy',
  }) async {
    if (!isConfigured) return null;

    try {
      final res = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/audio/speech'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://vocalis.ai',
          'X-Title': 'Vocalis AI Pronunciation Trainer',
        },
        body: jsonEncode({
          'model': model,
          'input': text,
          'voice': voice,
        }),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      } else {
        debugPrint('[OpenRouter TTS] Erro ${res.statusCode}: ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[OpenRouter TTS] Exceção: $e');
      return null;
    }
  }

  /// Transcreve áudio através do endpoint STT do OpenRouter (Whisper)
  Future<String?> transcribeAudio(
    List<int> audioBytes, {
    String model = _kDefaultSttModel,
  }) async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.parse('https://openrouter.ai/api/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.headers['HTTP-Referer'] = 'https://vocalis.ai';
      request.headers['X-Title'] = 'Vocalis AI Pronunciation Trainer';

      request.fields['model'] = model;
      request.fields['language'] = 'en';
      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'),
      );

      final streamedRes = await request.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['text'] as String?;
      } else {
        debugPrint('[OpenRouter STT] Erro ${res.statusCode}: ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[OpenRouter STT] Exceção: $e');
      return null;
    }
  }

  /// Avalia a pronúncia de falantes brasileiros com IA (Gemini / Llama gratuito)
  Future<String?> evaluatePronunciationWithAI({
    required String referenceText,
    required String spokenText,
    String model = 'google/gemini-2.0-flash-exp:free',
  }) async {
    if (!isConfigured) return null;

    try {
      final prompt = '''
Você é um linguista e fonoaudiólogo especialista em sotaques de falantes de Português Brasileiro aprendendo Inglês.
O aluno tentou pronunciar a frase em inglês:
Referência: "$referenceText"
O que foi captado da fala: "$spokenText"

Dê um feedback objetivo, encorajador e direto em Português do Brasil com:
1. Uma nota percentual estimada (0 a 100%)
2. Análise dos pontos fortes
3. Vícios fonéticos comuns do português a evitar (ex: colocar som de "i" antes de "st/sp", nasalizar vogais finais, esquecer o flap T americano, ou falar o L de "could/calm")
4. Uma dica prática de onde posicionar a língua e os lábios.

Seja conciso (máximo 4 a 6 linhas).
''';

      final res = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://vocalis.ai',
          'X-Title': 'Vocalis AI Pronunciation Trainer',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'] as String?;
          return content?.trim();
        }
      }
      return null;
    } catch (e) {
      debugPrint('[OpenRouter AI Evaluation] Exceção: $e');
      return null;
    }
  }
}
