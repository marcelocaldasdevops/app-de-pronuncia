import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocalis_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
  });

  group('StorageService - Stats', () {
    test('carrega estatísticas padrão quando vazio', () async {
      final stats = await storageService.loadStats();
      expect(stats.streakDays, 0);
      expect(stats.accuracyAvg, 0.0);
      expect(stats.sentencesToday, 0);
      expect(stats.practiceMinutes, 0);
    });

    test('registra sessão e atualiza streak e média de acurácia', () async {
      await storageService.recordPracticeSession(80.0);

      var stats = await storageService.loadStats();
      expect(stats.sentencesToday, 1);
      expect(stats.streakDays, 1);
      expect(stats.accuracyAvg, 80.0);
      expect(stats.practiceMinutes, 2);

      // Segunda sessão no mesmo dia incrementa frases sem alterar streak
      await storageService.recordPracticeSession(90.0);
      stats = await storageService.loadStats();
      expect(stats.sentencesToday, 2);
      expect(stats.streakDays, 1);
      // Média móvel ponderada: ((80 * 4) + 90) / 5 = 410 / 5 = 82.0
      expect(stats.accuracyAvg, closeTo(82.0, 0.01));
      expect(stats.practiceMinutes, 4);
    });
  });

  group('StorageService - Custom Phrases', () {
    test('lista de frases inicia vazia', () async {
      final phrases = await storageService.loadCustomPhrases();
      expect(phrases, isEmpty);
    });

    test('adiciona frase personalizada no início da lista', () async {
      await storageService.saveCustomPhrase('First phrase');
      await storageService.saveCustomPhrase('Second phrase');

      final phrases = await storageService.loadCustomPhrases();
      expect(phrases, ['Second phrase', 'First phrase']);
    });

    test('não duplica frases já existentes', () async {
      await storageService.saveCustomPhrase('Unique phrase');
      await storageService.saveCustomPhrase('Unique phrase');

      final phrases = await storageService.loadCustomPhrases();
      expect(phrases.length, 1);
      expect(phrases.first, 'Unique phrase');
    });

    test('remove frase personalizada com sucesso', () async {
      await storageService.saveCustomPhrase('Phrase to keep');
      await storageService.saveCustomPhrase('Phrase to remove');

      await storageService.removeCustomPhrase('Phrase to remove');
      final phrases = await storageService.loadCustomPhrases();

      expect(phrases, ['Phrase to keep']);
      expect(phrases.contains('Phrase to remove'), isFalse);
    });

    test('limita lista a no máximo 20 frases', () async {
      for (int i = 0; i < 25; i++) {
        await storageService.saveCustomPhrase('Phrase $i');
      }

      final phrases = await storageService.loadCustomPhrases();
      expect(phrases.length, 20);
      expect(phrases.first, 'Phrase 24');
      expect(phrases.contains('Phrase 0'), isFalse);
    });
  });

  group('StorageService - Smart Revision & Attempts', () {
    test('recomendação vazia quando não há tentativas gravadas', () async {
      final rec = await storageService.getReviewRecommendation();
      expect(rec.hasData, isFalse);
      expect(rec.reviewWord, isNull);
    });

    test('recomenda palavra e fonema com maior incidência de erro', () async {
      await storageService.recordPracticeSession(
        65.0,
        exerciseId: 'ex-1',
        weakWords: ['coffee', 'could'],
        weakPhonemes: ['/ʊ/', '/ɔː/'],
      );

      await storageService.recordPracticeSession(
        70.0,
        exerciseId: 'ex-1',
        weakWords: ['coffee'],
        weakPhonemes: ['/ɔː/'],
      );

      final attempts = await storageService.loadAttempts();
      expect(attempts.length, 2);

      final rec = await storageService.getReviewRecommendation();
      expect(rec.hasData, isTrue);
      expect(rec.reviewWord, 'coffee');
      expect(rec.count, 2);
      expect(rec.reviewPhoneme, '/ɔː/');
      expect(rec.targetExerciseId, 'ex-1');
    });

    test('reconhece ausência de dificuldades quando tentativas são perfeitas',
        () async {
      await storageService.recordPracticeSession(
        95.0,
        exerciseId: 'ex-2',
        weakWords: [],
        weakPhonemes: [],
      );

      final rec = await storageService.getReviewRecommendation();
      expect(rec.hasData, isTrue);
      expect(rec.reviewWord, isNull);
      expect(rec.reviewPhoneme, isNull);
    });
  });
}
