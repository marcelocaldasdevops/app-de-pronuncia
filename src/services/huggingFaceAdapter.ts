/**
 * Adapter that converts Hugging Face transcription + scoring results
 * into the UI-compatible PronunciationResult contract.
 *
 * Replaces pronunciationAdapter.ts (Azure-specific) for the HF pipeline.
 */

import { PronunciationResult, WordEvaluation, WordStatus } from '../types';
import { ipaDictionary } from '../data/exercises';
import { PronunciationScoreResult, WordComparisonResult } from './pronunciationScorerHF';

/**
 * Centralized score thresholds for pronunciation classification.
 * Same values as the Azure adapter for consistency.
 */
export const SCORE_THRESHOLDS = {
  MASTERED: 85,
  NEAR: 60,
} as const;

/**
 * Determines WordStatus based on accuracy score and omission flag.
 */
export function getWordStatus(score: number, isOmission = false): WordStatus {
  if (isOmission || score < SCORE_THRESHOLDS.NEAR) {
    return 'needs_work';
  }
  if (score >= SCORE_THRESHOLDS.MASTERED) {
    return 'mastered';
  }
  return 'near';
}

function normalizeWord(word: string): string {
  return word.toLowerCase().replace(/[^a-z0-9']/g, '');
}

function generateFeedbackSummary(overallScore: number, words: WordEvaluation[]): string {
  const needsWorkCount = words.filter((w) => w.status === 'needs_work').length;

  if (overallScore >= SCORE_THRESHOLDS.MASTERED && needsWorkCount === 0) {
    return 'Excelente articulação e precisão acústica! Pronúncia de alto nível.';
  }
  if (overallScore >= SCORE_THRESHOLDS.NEAR) {
    return 'Muito bom! Boa clareza geral, com pequenos ajustes em fonemas pontuais.';
  }
  return 'Bom esforço! Pratique as palavras destacadas em vermelho para ganhar clareza.';
}

function generateArticulationTip(words: WordEvaluation[]): string {
  const weakWord =
    words.find((w) => w.status === 'needs_work') ||
    words.find((w) => w.status === 'near');

  if (weakWord && weakWord.tip) {
    return `Dica para "${weakWord.word}": ${weakWord.tip}`;
  }
  return 'Dica: Conecte as palavras adjacentes (connected speech) sem pausar entre cada vocábulo.';
}

/**
 * Converts HF pronunciation scoring result into the UI-compatible PronunciationResult.
 *
 * @param scoreResult The scoring result from pronunciationScorerHF
 * @param targetSentence The expected reference sentence
 */
export function toPronunciationResult(
  scoreResult: PronunciationScoreResult,
  targetSentence: string
): PronunciationResult {
  const wordEvaluations: WordEvaluation[] = scoreResult.words.map(
    (w: WordComparisonResult) => {
      const isOmission = w.errorType === 'Omission';
      const cleanTarget = normalizeWord(w.referenceWord);

      // Dictionary lookup with Portuguese generic fallback
      const dictEntry = ipaDictionary[cleanTarget];
      const ipa = dictEntry?.ipa || `/${cleanTarget}/`;
      const tip =
        dictEntry?.tip ||
        (isOmission
          ? 'Palavra não detectada na fala. Pratique articulando-a pausadamente.'
          : 'Concentre-se na articulação e clareza acústica desta palavra.');

      return {
        word: w.referenceWord,
        spokenWord: w.spokenWord,
        status: getWordStatus(w.accuracyScore, isOmission),
        ipa,
        tip,
        score: w.accuracyScore,
      };
    }
  );

  return {
    overallScore: scoreResult.overallScore,
    accuracyScore: scoreResult.accuracyScore,
    fluencyScore: scoreResult.fluencyScore,
    completenessScore: scoreResult.completenessScore,
    transcript: scoreResult.displayText,
    targetSentence,
    words: wordEvaluations,
    feedbackSummary: generateFeedbackSummary(scoreResult.overallScore, wordEvaluations),
    articulationTip: generateArticulationTip(wordEvaluations),
    provider: 'huggingface',
  };
}
