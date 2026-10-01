import React, { useState } from 'react';
import { Exercise, PronunciationResult } from '../../types';
import { WaveformVisualizer } from './WaveformVisualizer';
import { audioService } from '../../services/audioService';
import { speechService } from '../../services/speechService';
import { pronunciationBackendService } from '../../services/pronunciationBackendService';

interface GuidedScreenProps {
  exercise: Exercise;
  exerciseIndex: number;
  totalExercises: number;
  onNextExercise: () => void;
  onFinishEvaluation: (result: PronunciationResult) => void;
  onBackToDashboard: () => void;
}

export const GuidedScreen: React.FC<GuidedScreenProps> = ({
  exercise,
  exerciseIndex,
  totalExercises,
  onNextExercise,
  onFinishEvaluation,
  onBackToDashboard,
}) => {
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const [playbackSpeed, setPlaybackSpeed] = useState<number>(1.0);
  const [isRecording, setIsRecording] = useState(false);
  const [liveTranscript, setLiveTranscript] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [recordingError, setRecordingError] = useState<string | null>(null);

  // Play reference native audio
  const handlePlayReference = async () => {
    if (isPlayingAudio) {
      speechService.stopSpeech();
      setIsPlayingAudio(false);
      return;
    }

    setIsPlayingAudio(true);
    await speechService.speak(exercise.sentence, playbackSpeed, exercise.accent === 'UK' ? 'en-GB' : 'en-US');
    setIsPlayingAudio(false);
  };

  const toggleSpeed = () => {
    setPlaybackSpeed((prev) => (prev === 1.0 ? 0.75 : 1.0));
  };

  // Start / Stop Microphone Recording
  const handleToggleRecording = async () => {
    if (isRecording) {
      // STOP recording
      setIsRecording(false);
      setIsAnalyzing(true);
      setRecordingError(null);
      speechService.stopRecognition();

      try {
        const audioBlob = await audioService.stopRecording();

        if (!audioBlob || audioBlob.size === 0) {
          setRecordingError('Nenhum áudio foi capturado. Tente falar mais próximo ao microfone.');
          setIsAnalyzing(false);
          return;
        }

        // Avalia via Backend Python (Wav2Vec2) ou fallback automático
        const evaluation = await pronunciationBackendService.assessPronunciation(
          audioBlob,
          exercise.sentence,
          liveTranscript.trim()
        );

        setIsAnalyzing(false);
        onFinishEvaluation(evaluation);
      } catch (err: unknown) {
        console.error('Error during pronunciation assessment:', err);
        setIsAnalyzing(false);
        const message =
          err instanceof Error
            ? err.message
            : 'Erro ao avaliar pronúncia. Verifique sua conexão e tente novamente.';
        setRecordingError(message);
      }
    } else {
      // START recording
      setRecordingError(null);
      setLiveTranscript('');
      
      const audioStarted = await audioService.startRecording();
      if (!audioStarted) {
        setRecordingError('Não foi possível acessar o microfone. Verifique as permissões do navegador.');
        return;
      }

      setIsRecording(true);

      // Start live speech recognition
      speechService.startRecognition(
        (transcript) => {
          setLiveTranscript(transcript);
        },
        (error) => {
          console.warn('Speech recognition warning:', error);
        },
        () => {
          // Finished recognition event
        }
      );
    }
  };

  return (
    <div className="flex flex-col min-h-[calc(100vh-8rem)] justify-between pb-24 pt-3 px-4 max-w-md mx-auto animate-fade-in">
      
      {/* Top Exercise Header & Progress */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <button
            onClick={onBackToDashboard}
            className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface hover:bg-surface-container-high transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
          </button>
          <div className="flex items-center gap-2">
            <span className="font-mono text-xs text-on-surface-variant font-medium">
              Exercício {exerciseIndex + 1} de {totalExercises}
            </span>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-surface-container font-semibold text-primary">
              {exercise.difficulty}
            </span>
          </div>
          <button
            onClick={onNextExercise}
            className="text-xs text-primary font-bold hover:underline"
          >
            Pular
          </button>
        </div>

        {/* Progress bar */}
        <div className="w-full bg-surface-container rounded-full h-1.5 overflow-hidden">
          <div
            className="bg-primary h-full transition-all duration-300"
            style={{ width: `${((exerciseIndex + 1) / totalExercises) * 100}%` }}
          />
        </div>
      </div>

      {/* Center Target Sentence Card */}
      <div className="my-auto flex flex-col gap-5 py-4">
        
        {/* Category Tag */}
        <div className="flex items-center justify-center gap-2">
          <span className="bg-primary-fixed text-primary font-mono text-[11px] font-bold px-3 py-1 rounded-full uppercase tracking-wider">
            {exercise.category}
          </span>
        </div>

        {/* Main Sentence Box */}
        <div className="bg-surface-container-lowest border border-surface-container-high rounded-3xl p-6 shadow-sm flex flex-col items-center text-center gap-3">
          
          <h2 className="font-headline font-extrabold text-2xl text-on-surface tracking-tight leading-snug">
            "{exercise.sentence}"
          </h2>

          {/* Phonetic IPA Notation */}
          <div className="font-mono text-xs text-primary bg-primary/5 px-3 py-1.5 rounded-xl border border-primary/10 tracking-wide">
            {exercise.phoneticIpa}
          </div>

          {/* Tip */}
          <p className="text-xs text-on-surface-variant leading-relaxed max-w-xs mt-1">
            💡 {exercise.tip}
          </p>

          {/* Native Audio Reference Controls */}
          <div className="flex items-center gap-2 mt-2 pt-3 border-t border-surface-container w-full justify-center">
            
            <button
              onClick={handlePlayReference}
              className={`px-4 py-2 rounded-full font-headline font-bold text-xs transition-all flex items-center gap-2 shadow-sm ${
                isPlayingAudio
                  ? 'bg-primary text-white animate-pulse'
                  : 'bg-surface-container hover:bg-surface-container-high text-primary'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]">
                {isPlayingAudio ? 'volume_up' : 'play_arrow'}
              </span>
              <span>{isPlayingAudio ? 'Ouvindo...' : 'Ouvir Referência'}</span>
            </button>

            <button
              onClick={toggleSpeed}
              className="px-2.5 py-1.5 rounded-full font-mono text-xs font-semibold bg-surface-container hover:bg-surface-container-high text-on-surface transition-colors"
              title="Velocidade de Reprodução"
            >
              {playbackSpeed}x
            </button>

          </div>
        </div>

        {/* Live Audio Waveform Deck */}
        <WaveformVisualizer isRecording={isRecording} />

        {/* Live Transcription Feedback */}
        {isRecording && (
          <div className="p-3 rounded-2xl bg-surface-container-low border border-primary/20 text-center animate-fade-in">
            <span className="text-[11px] font-mono text-primary font-bold uppercase tracking-wider block mb-1">
              O que a IA está ouvindo:
            </span>
            <p className="text-sm font-medium text-on-surface italic">
              {liveTranscript || 'Fale no microfone agora...'}
            </p>
          </div>
        )}

        {isAnalyzing && (
          <div className="p-4 rounded-2xl bg-indigo-50 border border-primary/30 text-center flex items-center justify-center gap-2 text-primary font-headline font-bold text-xs animate-pulse">
            <span className="material-symbols-outlined text-[20px] animate-spin">
              progress_activity
            </span>
            <span>Avaliando integridade acústica e fonemas...</span>
          </div>
        )}

        {recordingError && (
          <div className="p-3 rounded-xl bg-red-50 text-red-600 text-xs text-center border border-red-200">
            {recordingError}
          </div>
        )}

      </div>

      {/* Bottom Floating Stadium Microphone Button */}
      <div className="flex flex-col items-center gap-2">
        <span className="font-mono text-xs text-on-surface-variant font-medium">
          {isRecording
            ? 'Gravando... Toque novamente para concluir'
            : 'Toque para começar a falar'}
        </span>

        <button
          onClick={handleToggleRecording}
          disabled={isAnalyzing}
          className={`h-16 px-8 rounded-full font-headline font-bold text-sm flex items-center justify-center gap-3 transition-all duration-300 shadow-md ${
            isRecording
              ? 'bg-red-500 hover:bg-red-600 text-white shadow-mic animate-pulse scale-105'
              : 'bg-primary hover:bg-indigo-700 text-white hover:shadow-lg active:scale-95'
          }`}
        >
          <span
            className="material-symbols-outlined text-[26px]"
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
            {isRecording ? 'stop' : 'mic'}
          </span>
          <span className="tracking-wide">
            {isRecording ? 'Parar Gravação' : 'Pressione para Falar'}
          </span>
        </button>
      </div>

    </div>
  );
};
