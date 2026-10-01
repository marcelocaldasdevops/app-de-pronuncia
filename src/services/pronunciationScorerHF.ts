/**
 * Pronunciation scorer using word-level comparison (Levenshtein-inspired).
 *
 * Compares the transcript returned by the HF ASR model against the
 * reference text to produce word-level accuracy, fluency, and completeness scores.
 *
 * This replaces the Azure Pronunciation Assessment scoring logic.
 */

export interface WordComparisonResult {
  /** The reference word */
  referenceWord: string;
  /** What was spoken (or '—' if omitted) */
  spokenWord: string;
  /** Accuracy score 0–100 for this word */
  accuracyScore: number;
  /** Error type detected */
  errorType: 'None' | 'Omission' | 'Mispronunciation' | 'Insertion';
}

export interface PronunciationScoreResult {
  /** Overall pronunciation score 0–100 */
  overallScore: number;
  /** Accuracy score 0–100 */
  accuracyScore: number;
  /** Fluency score 0–100 (based on word order match and extra/missing words) */
  fluencyScore: number;
  /** Completeness score 0–100 (percentage of reference words spoken) */
  completenessScore: number;
  /** The transcript text */
  displayText: string;
  /** Word-level comparison results */
  words: WordComparisonResult[];
}

/**
 * Normalizes a word for comparison: lowercase, remove punctuation.
 */
function normalize(word: string): string {
  return word.toLowerCase().replace(/[^a-z0-9']/g, '');
}

/**
 * Levenshtein distance between two strings.
 */
function levenshteinDistance(a: string, b: string): number {
  const m = a.length;
  const n = b.length;

  if (m === 0) return n;
  if (n === 0) return m;

  const dp: number[][] = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0));

  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,      // deletion
        dp[i][j - 1] + 1,      // insertion
        dp[i - 1][j - 1] + cost // substitution
      );
    }
  }

  return dp[m][n];
}

/**
 * Calculates word-level similarity score (0–100).
 * Uses Levenshtein distance normalized by the longer word.
 */
function wordSimilarity(reference: string, spoken: string): number {
  const refNorm = normalize(reference);
  const spkNorm = normalize(spoken);

  if (refNorm === spkNorm) return 100;
  if (refNorm.length === 0 || spkNorm.length === 0) return 0;

  const maxLen = Math.max(refNorm.length, spkNorm.length);
  const dist = levenshteinDistance(refNorm, spkNorm);
  const similarity = Math.max(0, ((maxLen - dist) / maxLen) * 100);

  return Math.round(similarity);
}

/**
 * Aligns spoken words to reference words using a simple greedy forward-matching approach.
 * Handles omissions (reference word not spoken) and insertions (extra spoken words).
 */
function alignWords(
  referenceTokens: string[],
  spokenTokens: string[]
): WordComparisonResult[] {
  const results: WordComparisonResult[] = [];
  let spokenIdx = 0;

  for (let refIdx = 0; refIdx < referenceTokens.length; refIdx++) {
    const refWord = referenceTokens[refIdx];
    const refNorm = normalize(refWord);

    if (spokenIdx >= spokenTokens.length) {
      // Remaining reference words were not spoken
      results.push({
        referenceWord: refWord,
        spokenWord: '—',
        accuracyScore: 0,
        errorType: 'Omission',
      });
      continue;
    }

    // Look ahead in spoken tokens for the best match (window of 3)
    let bestMatchIdx = -1;
    let bestScore = -1;

    const windowEnd = Math.min(spokenTokens.length, spokenIdx + 3);
    for (let j = spokenIdx; j < windowEnd; j++) {
      const score = wordSimilarity(refNorm, normalize(spokenTokens[j]));
      if (score > bestScore) {
        bestScore = score;
        bestMatchIdx = j;
      }
    }

    // Threshold: if best match is too poor, treat as omission
    if (bestScore < 30) {
      results.push({
        referenceWord: refWord,
        spokenWord: '—',
        accuracyScore: 0,
        errorType: 'Omission',
      });
      // Don't advance spoken pointer - the spoken word might match a later reference word
      continue;
    }

    // Mark any skipped spoken words as insertions (not added to results since
    // we only track reference words, but we advance the pointer)
    spokenIdx = bestMatchIdx + 1;

    const spokenWord = spokenTokens[bestMatchIdx];
    const accuracy = bestScore;

    results.push({
      referenceWord: refWord,
      spokenWord,
      accuracyScore: accuracy,
      errorType: accuracy >= 85 ? 'None' : 'Mispronunciation',
    });
  }

  return results;
}

/**
 * Scores pronunciation by comparing ASR transcript against reference text.
 *
 * @param referenceText The expected sentence
 * @param transcript The STT-transcribed text from the user's audio
 */
export function scorePronunciation(
  referenceText: string,
  transcript: string
): PronunciationScoreResult {
  const referenceTokens = referenceText.trim().split(/\s+/).filter(Boolean);
  const spokenTokens = transcript.trim().split(/\s+/).filter(Boolean);

  if (referenceTokens.length === 0) {
    return {
      overallScore: 0,
      accuracyScore: 0,
      fluencyScore: 0,
      completenessScore: 0,
      displayText: transcript,
      words: [],
    };
  }

  if (spokenTokens.length === 0) {
    // Nothing was spoken
    return {
      overallScore: 0,
      accuracyScore: 0,
      fluencyScore: 0,
      completenessScore: 0,
      displayText: '',
      words: referenceTokens.map((w) => ({
        referenceWord: w,
        spokenWord: '—',
        accuracyScore: 0,
        errorType: 'Omission' as const,
      })),
    };
  }

  const wordResults = alignWords(referenceTokens, spokenTokens);

  // Calculate accuracy: average of word scores
  const totalAccuracy = wordResults.reduce((sum, w) => sum + w.accuracyScore, 0);
  const accuracyScore = Math.round(totalAccuracy / wordResults.length);

  // Calculate completeness: percentage of reference words that were spoken (not omitted)
  const spokenCount = wordResults.filter((w) => w.errorType !== 'Omission').length;
  const completenessScore = Math.round((spokenCount / referenceTokens.length) * 100);

  // Calculate fluency: based on completeness and how many extra words were inserted
  // Penalize for extra words (insertions) and for missing words
  const extraWordsPenalty = Math.max(0, spokenTokens.length - referenceTokens.length) * 5;
  const fluencyScore = Math.max(0, Math.min(100,
    Math.round((completenessScore * 0.5 + accuracyScore * 0.5) - extraWordsPenalty)
  ));

  // Overall score: weighted combination
  const overallScore = Math.round(
    accuracyScore * 0.5 + fluencyScore * 0.25 + completenessScore * 0.25
  );

  return {
    overallScore: Math.max(0, Math.min(100, overallScore)),
    accuracyScore: Math.max(0, Math.min(100, accuracyScore)),
    fluencyScore: Math.max(0, Math.min(100, fluencyScore)),
    completenessScore: Math.max(0, Math.min(100, completenessScore)),
    displayText: transcript,
    words: wordResults,
  };
}
