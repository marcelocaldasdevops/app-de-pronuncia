import React from 'react';
import { UserStats, Exercise } from '../../types';
import { localStatsStore, ReviewRecommendation } from '../../storage/localStatsStore';

interface DashboardScreenProps {
  stats: UserStats;
  currentExercise: Exercise;
  onStartGuided: () => void;
  onStartCustomPhrase: () => void;
  onStartFreeSpeaking: () => void;
  onStartReview?: (exerciseId?: string) => void;
  reviewRecommendation?: ReviewRecommendation;
}

export const DashboardScreen: React.FC<DashboardScreenProps> = ({
  stats,
  currentExercise,
  onStartGuided,
  onStartCustomPhrase,
  onStartFreeSpeaking,
  onStartReview,
  reviewRecommendation,
}) => {
  const recommendation = reviewRecommendation || localStatsStore.getReviewRecommendation();
  return (
    <div className="flex flex-col gap-5 pb-24 pt-4 px-4 max-w-md mx-auto animate-fade-in">
      
      {/* Greeting & Header */}
      <section className="flex items-center justify-between">
        <div className="flex flex-col">
          <span className="font-mono text-xs text-primary font-bold tracking-wider uppercase">
            Painel de Voz
          </span>
          <h1 className="font-headline font-extrabold text-2xl text-on-surface tracking-tight">
            Olá!
          </h1>
          <p className="text-xs text-on-surface-variant mt-0.5">
            Pronto para calibrar sua dicção e falar hoje?
          </p>
        </div>
        <div className="w-12 h-12 rounded-full bg-surface-container-high flex items-center justify-center shadow-sm">
          <span
            className="material-symbols-outlined text-primary text-[28px]"
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
            mic_double
          </span>
        </div>
      </section>

      {/* Streak & Daily Goal Bento Card */}
      <section className="w-full bg-surface-container-lowest border border-surface-container-high rounded-2xl p-4 shadow-sm flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-tertiary-fixed flex items-center justify-center text-on-tertiary-fixed shadow-sm">
              <span className="text-xl leading-none">🔥</span>
            </div>
            <div>
              <div className="font-headline font-bold text-sm text-on-surface">
                Ofensiva de {stats.streakDays} dias
              </div>
              <div className="font-mono text-[11px] text-tertiary font-semibold">
                Meta: 20 frases por dia
              </div>
            </div>
          </div>
          <div className="text-right">
            <span className="font-headline font-extrabold text-lg text-primary">
              {stats.sentencesToday}
            </span>
            <span className="font-mono text-xs text-on-surface-variant">/20</span>
          </div>
        </div>

        {/* Progress bar */}
        <div className="w-full bg-surface-container rounded-full h-2 overflow-hidden">
          <div
            className="bg-primary h-full rounded-full transition-all duration-500"
            style={{ width: `${Math.min(100, (stats.sentencesToday / 20) * 100)}%` }}
          />
        </div>

        {/* Stats mini grid */}
        <div className="grid grid-cols-2 gap-2 pt-2 border-t border-surface-container">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px] text-emerald-500">
              verified
            </span>
            <div className="text-[11px]">
              <span className="text-on-surface-variant">Precisão Média: </span>
              <strong className="text-on-surface font-mono">{stats.accuracyAvg}%</strong>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px] text-indigo-500">
              timer
            </span>
            <div className="text-[11px]">
              <span className="text-on-surface-variant">Tempo de Treino: </span>
              <strong className="text-on-surface font-mono">{stats.practiceMinutes} min</strong>
            </div>
          </div>
        </div>
      </section>

      {/* Mode 1: Repetição Guiada (Featured Card) */}
      <section className="w-full bg-gradient-to-br from-primary to-indigo-700 text-white rounded-2xl p-5 shadow-md flex flex-col justify-between relative overflow-hidden group">
        <div className="absolute right-0 top-0 translate-x-4 -translate-y-4 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none" />

        <div className="flex items-start justify-between relative z-10">
          <div>
            <span className="bg-white/20 text-white font-mono text-[10px] uppercase font-bold tracking-wider px-2.5 py-0.5 rounded-full backdrop-blur-sm">
              Modo Core
            </span>
            <h3 className="font-headline font-bold text-lg mt-2">
              Repetição Guiada
            </h3>
            <p className="text-xs text-indigo-100 max-w-[240px] mt-1 leading-relaxed">
              Shadowing e leitura em voz alta com análise fonética detalhada palavra por palavra.
            </p>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-white/15 backdrop-blur-sm flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-white text-[28px]">
              record_voice_over
            </span>
          </div>
        </div>

        {/* Current sentence teaser */}
        <div className="mt-4 p-3 rounded-xl bg-black/20 backdrop-blur-sm border border-white/10 flex flex-col gap-1 relative z-10">
          <span className="text-[10px] font-mono text-indigo-200 uppercase tracking-wider">
            Frase Sugerida ({currentExercise.difficulty}):
          </span>
          <p className="text-xs font-medium text-white italic truncate">
            "{currentExercise.sentence}"
          </p>
        </div>

        <button
          onClick={onStartGuided}
          className="mt-4 w-full bg-white text-primary font-headline font-bold text-xs py-3 rounded-xl shadow-sm hover:bg-indigo-50 transition-all flex items-center justify-center gap-1.5 active:scale-[0.98]"
        >
          <span>Iniciar Treino de Pronúncia</span>
          <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
        </button>
      </section>

      {/* Mode: Treinar Minha Frase */}
      <section className="w-full bg-surface-container-lowest border border-surface-container-high rounded-2xl p-4 shadow-sm flex items-center justify-between hover:border-primary/40 transition-colors">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-[24px]">edit_note</span>
          </div>
          <div>
            <div className="font-headline font-bold text-sm text-on-surface">
              Treinar Minha Frase
            </div>
            <p className="text-xs text-on-surface-variant">
              Digite ou cole qualquer frase em inglês para avaliar com IA.
            </p>
          </div>
        </div>
        <button
          onClick={onStartCustomPhrase}
          className="bg-primary hover:bg-indigo-700 text-white font-headline font-bold text-xs py-2 px-3.5 rounded-xl transition-all flex items-center gap-1 shrink-0 active:scale-95 shadow-sm"
        >
          <span>Digitar</span>
          <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
        </button>
      </section>

      {/* Mode 2: Conversação Livre */}
      <section className="w-full bg-surface-container-lowest border border-surface-container-high rounded-2xl p-4 shadow-sm flex flex-col gap-3">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <img
              src="/partner_icon_emma.jpg"
              alt="Emma Avatar"
              className="w-11 h-11 rounded-full object-cover border-2 border-primary/20 shrink-0"
              onError={(e) => {
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
            <div>
              <span className="bg-secondary-container text-secondary font-mono text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full">
                Conversação com IA
              </span>
              <h3 className="font-headline font-bold text-sm text-on-surface mt-1">
                Diálogo Livre com Emma
              </h3>
              <p className="text-xs text-on-surface-variant">
                Pratique fala espontânea e receba correções suaves.
              </p>
            </div>
          </div>
        </div>

        <div className="p-2.5 rounded-xl bg-surface-container-low text-xs text-on-surface-variant flex items-center gap-2">
          <span className="material-symbols-outlined text-amber-500 text-[18px]">
            lightbulb
          </span>
          <span>Tópico de hoje: Pedindo café em um bistrô de Nova York.</span>
        </div>

        <button
          onClick={onStartFreeSpeaking}
          className="w-full bg-surface-container hover:bg-surface-container-high text-on-surface font-headline font-bold text-xs py-2.5 rounded-xl transition-all flex items-center justify-center gap-1.5 active:scale-[0.98]"
        >
          <span>Conversar Agora</span>
          <span className="material-symbols-outlined text-[16px]">chat</span>
        </button>
      </section>

      {/* Review Card: Smart Revision */}
      {!recommendation.hasData ? (
        <section className="w-full bg-surface-container-lowest border border-dashed border-surface-container-high rounded-2xl p-4 shadow-sm flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-surface-container text-on-surface-variant flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-[24px]">spellcheck</span>
            </div>
            <div>
              <div className="font-headline font-bold text-xs text-on-surface">
                Revisão de Dificuldades
              </div>
              <p className="text-[11px] text-on-surface-variant mt-0.5">
                Pratique para ver suas dificuldades e fonemas a calibrar.
              </p>
            </div>
          </div>
          <button
            onClick={onStartGuided}
            className="text-xs text-primary font-bold hover:underline shrink-0 flex items-center gap-0.5"
          >
            Praticar <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          </button>
        </section>
      ) : recommendation.reviewWord || recommendation.reviewPhoneme ? (
        <section className="w-full bg-surface-container-lowest border border-amber-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-[24px]">spellcheck</span>
            </div>
            <div>
              <div className="font-headline font-bold text-xs text-on-surface">
                Revisão de Dificuldades
              </div>
              <div className="text-[11px] text-on-surface-variant mt-0.5 flex flex-col gap-0.5">
                {recommendation.reviewWord && (
                  <span>
                    Palavra: <strong className="font-mono text-primary font-bold">"{recommendation.reviewWord}"</strong>
                    {recommendation.count && recommendation.count > 1 ? ` (${recommendation.count}x)` : ''}
                  </span>
                )}
                {recommendation.reviewPhoneme && (
                  <span>
                    Som focado: <span className="font-mono font-bold text-tertiary">{recommendation.reviewPhoneme}</span>
                  </span>
                )}
              </div>
            </div>
          </div>
          <button
            onClick={() => (onStartReview ? onStartReview(recommendation.targetExerciseId) : onStartGuided())}
            className="text-xs text-primary font-bold hover:underline shrink-0 flex items-center gap-0.5"
          >
            Treinar <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          </button>
        </section>
      ) : (
        <section className="w-full bg-surface-container-lowest border border-emerald-200/80 rounded-2xl p-4 shadow-sm flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-[24px]">verified</span>
            </div>
            <div>
              <div className="font-headline font-bold text-xs text-on-surface">
                Revisão de Dificuldades
              </div>
              <p className="text-[11px] text-emerald-700 mt-0.5">
                Nenhuma dificuldade recente! Dicção excelente em todas as tentativas.
              </p>
            </div>
          </div>
          <button
            onClick={onStartGuided}
            className="text-xs text-primary font-bold hover:underline shrink-0 flex items-center gap-0.5"
          >
            Treinar <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          </button>
        </section>
      )}

    </div>
  );
};
