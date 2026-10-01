import { useState } from 'react';
import { ScreenMode, PronunciationResult, UserStats, Exercise } from './types';
import { exercises } from './data/exercises';
import { localStatsStore } from './storage/localStatsStore';
import { Header } from './components/layout/Header';
import { BottomNav } from './components/layout/BottomNav';
import { DashboardScreen } from './components/dashboard/DashboardScreen';
import { GuidedScreen } from './components/guided/GuidedScreen';
import { FeedbackModal } from './components/feedback/FeedbackModal';
import { FreeSpeakingScreen } from './components/free-speaking/FreeSpeakingScreen';
import { CustomPhraseScreen } from './components/custom-phrase/CustomPhraseScreen';
import { pronunciationBackendService } from './services/pronunciationBackendService';

export function App() {
  const [currentMode, setCurrentMode] = useState<ScreenMode>('dashboard');
  const [exerciseIndex, setExerciseIndex] = useState<number>(0);
  const [customExercise, setCustomExercise] = useState<Exercise | null>(null);
  const [evaluationResult, setEvaluationResult] = useState<PronunciationResult | null>(null);

  // Load persisted progress from localStatsStore (vocalis.progress.v1)
  const [stats, setStats] = useState<UserStats>(() => localStatsStore.loadProgress().stats);
  const [recentPhrases, setRecentPhrases] = useState<string[]>(() => localStatsStore.getCustomPhrases());

  const isCustom = Boolean(customExercise && (currentMode === 'guided' || currentMode === 'feedback'));
  const currentCatalogExercise = exercises[exerciseIndex % exercises.length];
  const activeExercise = isCustom && customExercise ? customExercise : currentCatalogExercise;

  const handleFinishEvaluation = (result: PronunciationResult) => {
    setEvaluationResult(result);
    setCurrentMode('feedback');

    // Persist attempt record and update statistics
    const updated = localStatsStore.recordAttempt({
      exerciseId: activeExercise.id,
      result,
      exercise: activeExercise,
      customPhrase: isCustom ? activeExercise.sentence : undefined,
    });

    setStats(updated.stats);
    setRecentPhrases(updated.customPhrases);
  };

  const handleRetry = () => {
    setEvaluationResult(null);
    setCurrentMode('guided');
  };

  const handleNextExercise = () => {
    setEvaluationResult(null);
    if (isCustom) {
      // In custom phrase mode, "Nova Frase" returns to the custom phrase editor
      setCurrentMode('custom-phrase');
    } else {
      // In catalog mode, advance to next exercise in catalog
      setExerciseIndex((prev) => (prev + 1) % exercises.length);
      setCurrentMode('guided');
    }
  };

  const handleStartGuided = () => {
    setCustomExercise(null);
    setEvaluationResult(null);
    setCurrentMode('guided');
  };

  const handleStartReview = (exerciseId?: string) => {
    setCustomExercise(null);
    setEvaluationResult(null);
    if (exerciseId) {
      const idx = exercises.findIndex((e) => e.id === exerciseId);
      if (idx !== -1) {
        setExerciseIndex(idx);
      }
    }
    setCurrentMode('guided');
  };

  const handleStartCustomPhrase = () => {
    setEvaluationResult(null);
    setCurrentMode('custom-phrase');
  };

  const handleStartCustomTraining = async (phrase: string) => {
    const trimmed = phrase.trim();

    // Obter transcrição fonética IPA para a frase própria
    let ipa = '';
    try {
      const phonetics = await pronunciationBackendService.getPhonetics(trimmed);
      ipa = phonetics.phoneticIpa;
    } catch {
      ipa = '';
    }

    const newExercise: Exercise = {
      id: `custom-${Date.now()}`,
      sentence: trimmed,
      phoneticIpa: ipa,
      difficulty: 'Intermediário',
      category: 'Frase própria',
      keyPhonemes: [],
      tip: 'Pratique articulando cada palavra de forma nítida e natural.',
      accent: 'US',
    };

    setCustomExercise(newExercise);
    const updatedPhrases = localStatsStore.addCustomPhrase(trimmed);
    setRecentPhrases(updatedPhrases);

    setEvaluationResult(null);
    setCurrentMode('guided');
  };

  const getHeaderTitle = () => {
    switch (currentMode) {
      case 'dashboard':
        return 'Início';
      case 'guided':
      case 'feedback':
        return isCustom ? 'Frase Própria' : 'Repetição Guiada';
      case 'custom-phrase':
        return 'Treinar Minha Frase';
      case 'free-speaking':
        return 'Conversação Livre';
      default:
        return 'Vocalis AI';
    }
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col justify-between selection:bg-primary-fixed selection:text-primary">
      {/* Header */}
      <Header
        stats={stats}
        currentTitle={getHeaderTitle()}
        onProfileClick={() => {
          setEvaluationResult(null);
          setCurrentMode('dashboard');
        }}
      />

      {/* Main Viewport */}
      <main className="flex-1 w-full max-w-md mx-auto">
        {currentMode === 'dashboard' && (
          <DashboardScreen
            stats={stats}
            currentExercise={currentCatalogExercise}
            onStartGuided={handleStartGuided}
            onStartCustomPhrase={handleStartCustomPhrase}
            onStartReview={handleStartReview}
            onStartFreeSpeaking={() => {
              setEvaluationResult(null);
              setCurrentMode('free-speaking');
            }}
          />
        )}

        {currentMode === 'custom-phrase' && (
          <CustomPhraseScreen
            onBackToDashboard={() => setCurrentMode('dashboard')}
            onStartTraining={handleStartCustomTraining}
            recentPhrases={recentPhrases}
          />
        )}

        {(currentMode === 'guided' || currentMode === 'feedback') && (
          <GuidedScreen
            exercise={activeExercise}
            exerciseIndex={isCustom ? 0 : exerciseIndex % exercises.length}
            totalExercises={isCustom ? 1 : exercises.length}
            onNextExercise={handleNextExercise}
            onFinishEvaluation={handleFinishEvaluation}
            onBackToDashboard={() => {
              if (isCustom) {
                setCurrentMode('custom-phrase');
              } else {
                setCurrentMode('dashboard');
              }
            }}
          />
        )}

        {currentMode === 'free-speaking' && (
          <FreeSpeakingScreen
            onBackToDashboard={() => setCurrentMode('dashboard')}
          />
        )}
      </main>

      {/* Feedback Modal Overlay (Screen 3) */}
      {currentMode === 'feedback' && evaluationResult && (
        <FeedbackModal
          result={evaluationResult}
          onRetry={handleRetry}
          onNext={handleNextExercise}
          onClose={() => setCurrentMode(isCustom ? 'custom-phrase' : 'guided')}
          isCustomPhrase={isCustom}
        />
      )}

      {/* Persistent Bottom Tabs */}
      <BottomNav
        currentMode={currentMode}
        onSelectMode={(mode) => {
          if (mode === 'feedback') return;
          setEvaluationResult(null);
          if (mode === 'guided') {
            setCustomExercise(null);
          }
          setCurrentMode(mode);
        }}
      />
    </div>
  );
}

export default App;
