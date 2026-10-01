import { LocalProgress, AttemptRecord, UserStats, Exercise, PronunciationResult } from '../types';

/**
 * Storage key versioned to v1 per RFC-001 §7.
 */
export const STORAGE_KEY = 'vocalis.progress.v1';
export const MAX_ATTEMPTS = 200;
export const MAX_CUSTOM_PHRASES = 20;

export const DEFAULT_STATS: UserStats = {
  streakDays: 0,
  sentencesToday: 0,
  accuracyAvg: 0,
  practiceMinutes: 0,
  reviewWord: '',
  reviewPhoneme: '',
};

export function getTodayDateString(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function getYesterdayDateString(): string {
  const date = new Date();
  date.setDate(date.getDate() - 1);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function createInitialProgress(): LocalProgress {
  return {
    version: 1,
    stats: { ...DEFAULT_STATS },
    attempts: [],
    lastPracticeDate: '',
    customPhrases: [],
  };
}

/**
 * Loads user progress from localStorage.
 * Handles daily reset of sentencesToday and streak validation.
 *
 * NOTE (Capacitor): If WebView localStorage proves inconsistent on iOS/Android,
 * migrate to @capacitor/preferences while preserving this store API.
 */
export function loadProgress(): LocalProgress {
  try {
    const raw = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null;
    if (!raw) {
      return createInitialProgress();
    }

    const parsed = JSON.parse(raw) as LocalProgress;

    // Validate schema
    if (!parsed || parsed.version !== 1 || !parsed.stats) {
      return createInitialProgress();
    }

    const today = getTodayDateString();
    const yesterday = getYesterdayDateString();

    // Check date change / rollover
    if (parsed.lastPracticeDate !== today) {
      // It's a new day: sentencesToday resets to 0
      parsed.stats.sentencesToday = 0;

      // If last practice was before yesterday, streak is broken (0)
      if (parsed.lastPracticeDate && parsed.lastPracticeDate !== yesterday) {
        parsed.stats.streakDays = 0;
      }
    }

    return parsed;
  } catch (err) {
    console.warn('Erro ao carregar progresso do localStorage:', err);
    return createInitialProgress();
  }
}

/**
 * Persists the entire LocalProgress state to localStorage.
 */
export function saveProgress(progress: LocalProgress): void {
  try {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
    }
  } catch (err) {
    console.warn('Erro ao salvar progresso no localStorage:', err);
  }
}

export interface RecordAttemptParams {
  exerciseId: string;
  result: PronunciationResult;
  exercise?: Exercise;
  customPhrase?: string;
}

/**
 * Records a completed pronunciation evaluation attempt, updating:
 * - streakDays (RFC rules)
 * - sentencesToday
 * - practiceMinutes
 * - accuracyAvg (true mathematical mean over attempts)
 * - attempt history (capped at 200)
 * - customPhrases (capped at 20, newest first)
 */
export function recordAttempt(params: RecordAttemptParams): LocalProgress {
  const current = loadProgress();
  const today = getTodayDateString();
  const yesterday = getYesterdayDateString();

  // Streak logic per RFC-001 §7:
  // - If lastPracticeDate is yesterday and practicing today: streakDays + 1
  // - If lastPracticeDate < yesterday: reset to 1 on practice
  // - If lastPracticeDate == today: maintain streakDays
  if (current.lastPracticeDate === today) {
    current.stats.streakDays = Math.max(1, current.stats.streakDays);
  } else if (current.lastPracticeDate === yesterday) {
    current.stats.streakDays = (current.stats.streakDays || 0) + 1;
  } else {
    current.stats.streakDays = 1;
  }

  current.lastPracticeDate = today;
  current.stats.sentencesToday += 1;
  current.stats.practiceMinutes += 1;

  // Extract weak words
  const weakWords = params.result.words
    .filter((w) => w.status === 'needs_work')
    .map((w) => w.word);

  // Extract weak phonemes (if exercise provides keyPhonemes)
  const weakPhonemes =
    params.exercise?.keyPhonemes && weakWords.length > 0
      ? params.exercise.keyPhonemes
      : [];

  const attempt: AttemptRecord = {
    exerciseId: params.exerciseId,
    timestamp: Date.now(),
    overallScore: params.result.overallScore,
    weakWords,
    weakPhonemes,
  };

  current.attempts = [attempt, ...current.attempts].slice(0, MAX_ATTEMPTS);

  // Recalculate average accuracy across all recorded attempts
  const allScores = current.attempts.map((a) => a.overallScore);
  current.stats.accuracyAvg = Math.round(
    allScores.reduce((sum, score) => sum + score, 0) / allScores.length
  );

  // Update custom phrases list if custom phrase was trained
  if (params.customPhrase && params.customPhrase.trim()) {
    const clean = params.customPhrase.trim();
    current.customPhrases = [
      clean,
      ...current.customPhrases.filter((p) => p.toLowerCase() !== clean.toLowerCase()),
    ].slice(0, MAX_CUSTOM_PHRASES);
  }

  saveProgress(current);
  return current;
}

/**
 * Gets the list of saved custom phrases.
 */
export function getCustomPhrases(): string[] {
  return loadProgress().customPhrases || [];
}

/**
 * Adds a custom phrase to the saved list without recording a score attempt.
 */
export function addCustomPhrase(phrase: string): string[] {
  const trimmed = phrase.trim();
  if (!trimmed) return getCustomPhrases();

  const current = loadProgress();
  current.customPhrases = [
    trimmed,
    ...current.customPhrases.filter((p) => p.toLowerCase() !== trimmed.toLowerCase()),
  ].slice(0, MAX_CUSTOM_PHRASES);

  saveProgress(current);
  return current.customPhrases;
}

/**
 * Removes a custom phrase from the saved list.
 */
export function deleteCustomPhrase(phrase: string): string[] {
  const trimmed = phrase.trim();
  if (!trimmed) return getCustomPhrases();

  const current = loadProgress();
  current.customPhrases = current.customPhrases.filter(
    (p) => p.toLowerCase() !== trimmed.toLowerCase()
  );

  saveProgress(current);
  return current.customPhrases;
}

/**
 * Clears local progress (useful for tests or user reset).
 */
export function resetProgress(): LocalProgress {
  const initial = createInitialProgress();
  saveProgress(initial);
  return initial;
}

export interface ReviewRecommendation {
  hasData: boolean;
  reviewWord?: string;
  reviewPhoneme?: string;
  count?: number;
  targetExerciseId?: string;
}

/**
 * Computes a smart review recommendation based on past attempts.
 * Analyzes the most frequently failed words and phonemes across history.
 */
export function getReviewRecommendation(): ReviewRecommendation {
  const progress = loadProgress();
  const attempts = progress.attempts || [];

  if (attempts.length === 0) {
    return { hasData: false };
  }

  const wordFrequency: Record<string, { count: number; exerciseId?: string }> = {};
  const phonemeFrequency: Record<string, number> = {};

  for (const attempt of attempts) {
    for (const rawWord of attempt.weakWords || []) {
      const clean = rawWord.toLowerCase().replace(/[^a-z0-9']/g, '');
      if (clean) {
        if (!wordFrequency[clean]) {
          wordFrequency[clean] = { count: 0, exerciseId: attempt.exerciseId };
        }
        wordFrequency[clean].count += 1;
      }
    }

    for (const phoneme of attempt.weakPhonemes || []) {
      if (phoneme) {
        phonemeFrequency[phoneme] = (phonemeFrequency[phoneme] || 0) + 1;
      }
    }
  }

  let topWord: string | undefined = undefined;
  let topWordCount = 0;
  let targetExerciseId: string | undefined = undefined;

  for (const [w, data] of Object.entries(wordFrequency)) {
    if (data.count > topWordCount) {
      topWordCount = data.count;
      topWord = w;
      targetExerciseId = data.exerciseId;
    }
  }

  let topPhoneme: string | undefined = undefined;
  let topPhonemeCount = 0;

  for (const [ph, count] of Object.entries(phonemeFrequency)) {
    if (count > topPhonemeCount) {
      topPhonemeCount = count;
      topPhoneme = ph;
    }
  }

  if (!topWord && !topPhoneme) {
    return {
      hasData: true,
      reviewWord: undefined,
      reviewPhoneme: undefined,
      count: 0,
    };
  }

  return {
    hasData: true,
    reviewWord: topWord,
    reviewPhoneme: topPhoneme,
    count: Math.max(topWordCount, topPhonemeCount),
    targetExerciseId,
  };
}

export const localStatsStore = {
  loadProgress,
  saveProgress,
  recordAttempt,
  getCustomPhrases,
  addCustomPhrase,
  deleteCustomPhrase,
  resetProgress,
  getReviewRecommendation,
  STORAGE_KEY,
};

export default localStatsStore;
