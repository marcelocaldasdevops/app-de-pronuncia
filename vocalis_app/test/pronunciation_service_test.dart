import 'package:flutter_test/flutter_test.dart';
import 'package:vocalis_app/models/pronunciation_result.dart';
import 'package:vocalis_app/services/pronunciation_service.dart';

void main() {
  final service = PronunciationService(backendUrl: 'http://127.0.0.1:59999');

  test('pontuação não funde palavras na avaliação offline', () async {
    final result = await service.assessAudio(
      audioBytes: [0],
      referenceText: 'Could you recommend a cozy coffee shop nearby?How much does this cost?',
      spokenTranscript: 'Could you recommend a cozy coffe shop nearby how much does this cost',
    );

    final words = result.words.map((w) => w.word).toList();
    expect(words, contains('nearby'));
    expect(words, contains('how'));
    expect(words, isNot(contains('nearbyhow')));
    expect(words.length, 13);
  });

  test('erro de digitação curto é marcado como perto, não como erro', () async {
    final result = await service.assessAudio(
      audioBytes: [0],
      referenceText: 'coffee',
      spokenTranscript: 'coffe',
    );

    final word = result.words.single;
    expect(word.status, WordStatus.near);
    expect(word.score, greaterThanOrEqualTo(65));
    expect(word.score, lessThan(80));
  });

  test('frase idêntica pontua alto e usa fallback offline', () async {
    final result = await service.assessAudio(
      audioBytes: [0],
      referenceText: 'How much does this cost?',
      spokenTranscript: 'How much does this cost',
    );

    expect(result.provider, 'client-offline');
    expect(result.accuracyScore, greaterThanOrEqualTo(88));
    expect(result.overallScore, greaterThanOrEqualTo(85));
    expect(result.words.every((w) => w.status == WordStatus.mastered), isTrue);
  });

  test('transcript omitido usa a própria frase de referência', () async {
    final result = await service.assessAudio(
      audioBytes: [0],
      referenceText: 'Hello world',
    );

    expect(result.words.map((w) => w.spokenWord), ['hello', 'world']);
    expect(result.completenessScore, 100);
  });
}
