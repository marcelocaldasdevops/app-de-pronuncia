import React, { useState } from 'react';
import { PronunciationResult, WordEvaluation, PhonemeEvaluation } from '../../types';
import { speechService } from '../../services/speechService';

interface FeedbackModalProps {
  result: PronunciationResult;
  onRetry: () => void;
  onNext: () => void;
  onClose: () => void;
  isCustomPhrase?: boolean;
}

export const FeedbackModal: React.FC<FeedbackModalProps> = ({
  result,
  onRetry,
  onNext,
  onClose,
  isCustomPhrase = false,
}) => {
  const [selectedWord, setSelectedWord] = useState<WordEvaluation | null>(
    result.words.find((w) => w.status === 'needs_work') ||
    result.words.find((w) => w.status === 'near') ||
    result.words[0] ||
    null
  );

  const [selectedPhoneme, setSelectedPhoneme] = useState<PhonemeEvaluation | null>(null);

  const handleSelectWord = (word: WordEvaluation) => {
    setSelectedWord(word);
    setSelectedPhoneme(null);
  };

  const handlePlayWord = (word: string) => {
    speechService.speak(word, 0.8, 'en-US');
  };

  const getScoreColor = (score: number) => {
    if (score >= 85) return 'text-emerald-500 bg-emerald-50 border-emerald-200';
    if (score >= 65) return 'text-amber-500 bg-amber-50 border-amber-200';
    return 'text-red-500 bg-red-50 border-red-200';
  };

  const getPhonemeBadge = (p: PhonemeEvaluation) => {
    if (p.status === 'mastered') {
      return 'bg-emerald-100/80 text-emerald-800 border-emerald-300';
    }
    if (p.status === 'near') {
      return 'bg-amber-100/80 text-amber-800 border-amber-300';
    }
    return 'bg-red-100/80 text-red-800 border-red-300';
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex flex-col justify-end animate-fade-in">
      
      {/* Click outside to close */}
      <div className="flex-1" onClick={onClose} />

      {/* Slide-up Container (snapping modal) */}
      <div className="bg-surface rounded-t-3xl border-t border-surface-container-high shadow-2xl p-5 max-w-md mx-auto w-full max-h-[90vh] overflow-y-auto flex flex-col gap-4 animate-slide-up">
        
        {/* Grab Handle */}
        <div className="w-12 h-1.5 bg-surface-container-highest rounded-full mx-auto" />

        {/* Header & Overall Score */}
        <div className="flex items-center justify-between pt-1">
          <div className="flex flex-col">
            <span className="font-mono text-xs text-primary font-bold uppercase tracking-wider">
              Diagnóstico Acústico
            </span>
            <h2 className="font-headline font-bold text-xl text-on-surface">
              Avaliação de Pronúncia
            </h2>
          </div>

          {/* Overall score badge */}
          <div
            className={`px-3 py-1.5 rounded-2xl border flex items-center gap-1 font-mono font-extrabold text-lg shadow-sm ${getScoreColor(
              result.overallScore
            )}`}
          >
            <span>{result.overallScore}%</span>
            <span className="text-xs font-normal">score</span>
          </div>
        </div>

        {/* Sub-Metrics Cards */}
        <div className="grid grid-cols-3 gap-2 py-1">
          <div className="bg-surface-container-lowest border border-surface-container-high rounded-xl p-2.5 text-center">
            <span className="text-[10px] font-mono text-on-surface-variant uppercase">Precisão</span>
            <div className="font-mono font-bold text-sm text-on-surface mt-0.5">{result.accuracyScore}%</div>
          </div>
          <div className="bg-surface-container-lowest border border-surface-container-high rounded-xl p-2.5 text-center">
            <span className="text-[10px] font-mono text-on-surface-variant uppercase">Fluência</span>
            <div className="font-mono font-bold text-sm text-on-surface mt-0.5">{result.fluencyScore}%</div>
          </div>
          <div className="bg-surface-container-lowest border border-surface-container-high rounded-xl p-2.5 text-center">
            <span className="text-[10px] font-mono text-on-surface-variant uppercase">Completude</span>
            <div className="font-mono font-bold text-sm text-on-surface mt-0.5">{result.completenessScore}%</div>
          </div>
        </div>

        {/* Color-Coded Word Spans */}
        <div className="bg-surface-container-lowest border border-surface-container-high rounded-2xl p-4 shadow-sm flex flex-col gap-2.5">
          <span className="font-mono text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">
            Toque nas palavras para inspecionar fonemas:
          </span>

          <div className="flex flex-wrap gap-2 pt-1">
            {result.words.map((w, i) => {
              const isSelected = selectedWord?.word === w.word;
              let badgeColor = '';
              let textColor = '';
              let borderColor = '';

              if (w.status === 'mastered') {
                badgeColor = 'bg-emerald-50';
                textColor = 'text-emerald-700';
                borderColor = 'border-emerald-300';
              } else if (w.status === 'near') {
                badgeColor = 'bg-amber-50';
                textColor = 'text-amber-800';
                borderColor = 'border-amber-300';
              } else {
                badgeColor = 'bg-red-50';
                textColor = 'text-red-700';
                borderColor = 'border-red-300';
              }

              return (
                <button
                  key={i}
                  onClick={() => handleSelectWord(w)}
                  className={`px-3 py-1.5 rounded-full font-headline font-semibold text-sm transition-all border ${badgeColor} ${textColor} ${borderColor} ${
                    isSelected ? 'ring-2 ring-primary ring-offset-2 scale-105' : 'hover:scale-102'
                  }`}
                >
                  {w.word}
                </button>
              );
            })}
          </div>

          {/* Color legend */}
          <div className="flex items-center gap-3 pt-2 text-[10px] font-mono text-on-surface-variant border-t border-surface-container">
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span> Correto
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-amber-500"></span> Aceitável
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-red-500"></span> Precisa de Atenção
            </span>
          </div>
        </div>

        {/* Selected Word Detail Box with Phoneme Breakdown */}
        {selectedWord && (
          <div className="bg-gradient-to-r from-surface-container to-surface-container-high rounded-2xl p-4 border border-surface-container-high/80 flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="font-headline font-bold text-base text-on-surface">
                  "{selectedWord.word}"
                </span>
                <span className="font-mono text-xs bg-white/70 px-2 py-0.5 rounded-md font-bold text-primary border border-primary/20">
                  {selectedWord.ipa}
                </span>
              </div>
              <button
                onClick={() => handlePlayWord(selectedWord.word)}
                className="w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center hover:bg-indigo-700 shadow-sm active:scale-95"
                title="Ouvir palavra isolada"
              >
                <span className="material-symbols-outlined text-[18px]">volume_up</span>
              </button>
            </div>

            {/* Individual Phonemes Breakdown (ELSA Speak style) */}
            {selectedWord.phonemes && selectedWord.phonemes.length > 0 && (
              <div className="bg-surface-container-lowest/80 rounded-xl p-2.5 border border-surface-container flex flex-col gap-1.5">
                <div className="flex items-center justify-between text-[10px] font-mono uppercase font-bold text-on-surface-variant tracking-wider">
                  <span>Detalhamento Acústico por Fonema:</span>
                  <span className="text-[9px] text-primary lowercase font-normal">toque para dica</span>
                </div>
                <div className="flex flex-wrap gap-1.5 pt-0.5">
                  {selectedWord.phonemes.map((ph, phIdx) => {
                    const isPhSelected = selectedPhoneme?.phoneme === ph.phoneme;
                    return (
                      <button
                        key={phIdx}
                        type="button"
                        onClick={() => setSelectedPhoneme(ph)}
                        className={`px-2.5 py-1 rounded-lg border text-xs font-mono font-bold flex items-center gap-1 transition-all ${getPhonemeBadge(
                          ph
                        )} ${isPhSelected ? 'ring-2 ring-primary scale-105 shadow-xs' : 'hover:scale-102'}`}
                      >
                        <span>/{ph.phoneme}/</span>
                        <span className="text-[10px] opacity-80">{ph.score}%</span>
                      </button>
                    );
                  })}
                </div>

                {/* Specific Phoneme Tip */}
                {selectedPhoneme?.tip && (
                  <div className="mt-1 p-2 rounded-lg bg-primary/5 border border-primary/15 text-[11px] text-primary flex items-start gap-1.5 animate-fade-in">
                    <span className="material-symbols-outlined text-[14px] shrink-0 mt-0.5">info</span>
                    <span>
                      <strong>Fonema /{selectedPhoneme.phoneme}/:</strong> {selectedPhoneme.tip}
                    </span>
                  </div>
                )}
              </div>
            )}

            <p className="text-xs text-on-surface-variant leading-relaxed">
              💡 {selectedWord.tip}
            </p>

            <div className="text-[11px] font-mono text-on-surface-variant flex items-center justify-between pt-1 border-t border-surface-container">
              <span>Sua fala detectada: <strong className="text-on-surface">{selectedWord.spokenWord}</strong></span>
              <span>Acurácia: <strong className="text-primary">{selectedWord.score}%</strong></span>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="grid grid-cols-2 gap-3 pt-2">
          <button
            onClick={onRetry}
            className="py-3 px-4 rounded-xl border border-surface-container-high bg-surface-container hover:bg-surface-container-high text-on-surface font-headline font-bold text-xs transition-all flex items-center justify-center gap-1.5 active:scale-95"
          >
            <span className="material-symbols-outlined text-[18px]">replay</span>
            <span>Tentar Novamente</span>
          </button>

          <button
            onClick={onNext}
            className="py-3 px-4 rounded-xl bg-primary hover:bg-indigo-700 text-white font-headline font-bold text-xs shadow-md transition-all flex items-center justify-center gap-1.5 active:scale-95"
          >
            <span>{isCustomPhrase ? 'Nova Frase' : 'Próxima Frase'}</span>
            <span className="material-symbols-outlined text-[18px]">
              {isCustomPhrase ? 'edit_note' : 'arrow_forward'}
            </span>
          </button>
        </div>

      </div>
    </div>
  );
};
