export type ScreenMode = 'dashboard' | 'guided' | 'feedback' | 'free-speaking' | 'custom-phrase';

export interface Exercise {
  id: string;
  sentence: string;
  phoneticIpa: string;
  difficulty: 'Básico' | 'Intermediário' | 'Avançado';
  category: string;
  keyPhonemes: string[];
  tip: string;
  accent: 'US' | 'UK';
}

export type WordStatus = 'mastered' | 'near' | 'needs_work';

export interface PhonemeEvaluation {
  phoneme: string;
  score: number;
  status: WordStatus;
  tip?: string;
}

export interface WordEvaluation {
  word: string;
  spokenWord: string;
  status: WordStatus;
  ipa: string;
  tip?: string;
  score: number;
  phonemes?: PhonemeEvaluation[];
}

export interface PronunciationResult {
  overallScore: number;
  fluencyScore: number;
  accuracyScore: number;
  completenessScore: number;
  transcript: string;
  targetSentence: string;
  words: WordEvaluation[];
  feedbackSummary: string;
  articulationTip?: string;
  provider?: 'azure' | 'huggingface' | 'fallback';
  prosodyScore?: number;
}

export interface ConversationMessage {
  id: string;
  sender: 'user' | 'ai';
  text: string;
  audioPlaying?: boolean;
  timestamp: string;
  suggestion?: string;
}

export interface UserStats {
  streakDays: number;
  sentencesToday: number;
  accuracyAvg: number;
  practiceMinutes: number;
  reviewWord: string;
  reviewPhoneme: string;
}

export interface AttemptRecord {
  exerciseId: string;
  timestamp: number;
  overallScore: number;
  weakWords: string[];
  weakPhonemes: string[];
}

export interface LocalProgress {
  version: number;
  stats: UserStats;
  attempts: AttemptRecord[];
  lastPracticeDate: string; // YYYY-MM-DD
  customPhrases: string[];  // max 20
}
