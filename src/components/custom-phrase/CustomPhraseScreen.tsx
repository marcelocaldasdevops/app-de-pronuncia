import React, { useState, useEffect, useRef } from 'react';
import { pronunciationBackendService, PhoneticsResponse } from '../../services/pronunciationBackendService';
import { speechService } from '../../services/speechService';
import { localStatsStore } from '../../storage/localStatsStore';

interface CustomPhraseScreenProps {
  onBackToDashboard: () => void;
  onStartTraining: (phrase: string) => void;
  recentPhrases?: string[];
}

const EXAMPLE_SUGGESTIONS = [
  'I would like an iced americano with oat milk, please.',
  'Could we schedule a quick sync tomorrow morning?',
  'I truly appreciate your feedback and continuous support.',
  'Let me double-check the details and get back to you shortly.',
];

export const CustomPhraseScreen: React.FC<CustomPhraseScreenProps> = ({
  onBackToDashboard,
  onStartTraining,
  recentPhrases = [],
}) => {
  const [phrase, setPhrase] = useState('');
  const [validationError, setValidationError] = useState<string | null>(null);
  const [phonetics, setPhonetics] = useState<PhoneticsResponse | null>(null);
  const [isLoadingPhonetics, setIsLoadingPhonetics] = useState(false);
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const [isBackendOnline, setIsBackendOnline] = useState<boolean | null>(null);
  const [savedList, setSavedList] = useState<string[]>(recentPhrases);
  const [isSaved, setIsSaved] = useState(false);

  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);
  const maxLength = 200;

  // Check backend status on mount
  useEffect(() => {
    let mounted = true;
    pronunciationBackendService.isBackendAvailable().then((available) => {
      if (mounted) setIsBackendOnline(available);
    });
    return () => {
      mounted = false;
    };
  }, []);

  // Update saved state when phrase changes
  useEffect(() => {
    const trimmed = phrase.trim().toLowerCase();
    setIsSaved(savedList.some((p) => p.toLowerCase() === trimmed));
  }, [phrase, savedList]);

  // Debounced IPA phonetics retrieval
  useEffect(() => {
    const trimmed = phrase.trim();
    if (!trimmed || trimmed.length < 2) {
      setPhonetics(null);
      setIsLoadingPhonetics(false);
      return;
    }

    if (debounceTimerRef.current) clearTimeout(debounceTimerRef.current);

    setIsLoadingPhonetics(true);
    debounceTimerRef.current = setTimeout(async () => {
      try {
        const result = await pronunciationBackendService.getPhonetics(trimmed);
        setPhonetics(result);
      } catch (err) {
        console.warn('Erro ao carregar IPA:', err);
      } finally {
        setIsLoadingPhonetics(false);
      }
    }, 450);

    return () => {
      if (debounceTimerRef.current) clearTimeout(debounceTimerRef.current);
    };
  }, [phrase]);

  const handleTextChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const text = e.target.value;
    if (text.length <= maxLength) {
      setPhrase(text);
      if (validationError) setValidationError(null);
    }
  };

  const handleSelectExample = (example: string) => {
    setPhrase(example);
    setValidationError(null);
  };

  const handlePlayAudio = async (textToPlay: string) => {
    if (isPlayingAudio) {
      speechService.stopSpeech();
      setIsPlayingAudio(false);
      return;
    }

    setIsPlayingAudio(true);
    await speechService.speak(textToPlay, 0.9, 'en-US');
    setIsPlayingAudio(false);
  };

  const handleToggleSave = () => {
    const trimmed = phrase.trim();
    if (!trimmed) return;

    if (isSaved) {
      const updated = localStatsStore.deleteCustomPhrase(trimmed);
      setSavedList(updated);
      setIsSaved(false);
    } else {
      const updated = localStatsStore.addCustomPhrase(trimmed);
      setSavedList(updated);
      setIsSaved(true);
    }
  };

  const handleDeleteSaved = (target: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const updated = localStatsStore.deleteCustomPhrase(target);
    setSavedList(updated);
  };

  const handleSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();

    const trimmed = phrase.trim();

    if (!trimmed) {
      setValidationError('Por favor, digite ou cole uma frase em inglês antes de treinar.');
      return;
    }

    if (trimmed.length < 2) {
      setValidationError('A frase deve ter pelo menos 2 caracteres.');
      return;
    }

    const hasLetters = /[a-zA-Z]/.test(trimmed);
    if (!hasLetters) {
      setValidationError('A frase deve conter palavras em inglês legíveis.');
      return;
    }

    setValidationError(null);
    onStartTraining(trimmed);
  };

  return (
    <div className="flex flex-col min-h-[calc(100vh-8rem)] pb-24 pt-3 px-4 max-w-md mx-auto animate-fade-in gap-4">
      {/* Top Header */}
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <button
            onClick={onBackToDashboard}
            className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface hover:bg-surface-container-high transition-colors"
            title="Voltar ao início"
          >
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
          </button>

          {/* Motor Status Badge */}
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-mono font-bold tracking-wide border">
            {isBackendOnline ? (
              <span className="flex items-center gap-1 text-emerald-600 bg-emerald-50 border-emerald-200">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                Motor Python Wav2Vec2
              </span>
            ) : (
              <span className="flex items-center gap-1 text-on-surface-variant bg-surface-container border-surface-container-high">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                Modo Local / WebSpeech
              </span>
            )}
          </div>

          <div className="w-9" />
        </div>

        <div className="flex flex-col gap-0.5">
          <h1 className="font-headline font-extrabold text-2xl text-on-surface tracking-tight">
            Minhas Frases
          </h1>
          <p className="text-xs text-on-surface-variant leading-relaxed">
            Digite qualquer texto em inglês para receber transcrição fonética e treino com IA.
          </p>
        </div>
      </div>

      {/* Text Input Card */}
      <div className="bg-surface-container-lowest border border-surface-container-high rounded-3xl p-4 shadow-sm flex flex-col gap-3 focus-within:border-primary/50 transition-colors">
        <div className="flex items-center justify-between">
          <label
            htmlFor="custom-phrase-input"
            className="text-xs font-mono font-bold text-on-surface-variant uppercase tracking-wider flex items-center gap-1.5"
          >
            <span className="material-symbols-outlined text-[16px] text-primary">edit</span>
            Digite sua frase:
          </label>
          <div className="flex items-center gap-2">
            {phrase.trim().length > 0 && (
              <>
                <button
                  type="button"
                  onClick={() => handlePlayAudio(phrase)}
                  disabled={isPlayingAudio}
                  className="text-[11px] font-mono text-primary hover:text-indigo-700 flex items-center gap-0.5 transition-colors"
                  title="Ouvir referência TTS"
                >
                  <span className="material-symbols-outlined text-[14px]">
                    {isPlayingAudio ? 'volume_off' : 'volume_up'}
                  </span>
                  <span>Ouvir</span>
                </button>
                <button
                  type="button"
                  onClick={handleToggleSave}
                  className={`text-[11px] font-mono flex items-center gap-0.5 transition-colors ${
                    isSaved ? 'text-amber-500 font-bold' : 'text-on-surface-variant hover:text-amber-500'
                  }`}
                  title={isSaved ? 'Remover dos favoritos' : 'Salvar frase'}
                >
                  <span
                    className="material-symbols-outlined text-[14px]"
                    style={{ fontVariationSettings: isSaved ? "'FILL' 1" : "'FILL' 0" }}
                  >
                    bookmark
                  </span>
                  <span>{isSaved ? 'Salva' : 'Salvar'}</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPhrase('')}
                  className="text-[11px] font-mono text-on-surface-variant hover:text-red-500 transition-colors"
                >
                  Limpar
                </button>
              </>
            )}
          </div>
        </div>

        <textarea
          id="custom-phrase-input"
          rows={3}
          value={phrase}
          onChange={handleTextChange}
          placeholder="Ex: I would like an iced americano with oat milk, please."
          className="w-full bg-surface-container-low border border-surface-container rounded-2xl p-3 text-sm text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none focus:ring-2 focus:ring-primary/20 resize-none font-medium leading-relaxed"
          maxLength={maxLength}
        />

        {/* Char Counter & Validation */}
        <div className="flex items-center justify-between text-[11px] font-mono">
          {validationError ? (
            <span className="text-red-500 font-medium flex items-center gap-1">
              <span className="material-symbols-outlined text-[14px]">error</span>
              {validationError}
            </span>
          ) : (
            <span className="text-on-surface-variant/70">Máx. 200 caracteres</span>
          )}
          <span
            className={`font-semibold ${
              phrase.length >= maxLength ? 'text-red-500' : 'text-on-surface-variant'
            }`}
          >
            {phrase.length}/{maxLength}
          </span>
        </div>

        {/* Live IPA Phonetics Preview */}
        {phrase.trim().length > 1 && (
          <div className="mt-1 pt-2.5 border-t border-surface-container flex flex-col gap-1.5">
            <div className="flex items-center justify-between text-[10px] font-mono uppercase font-bold text-primary tracking-wider">
              <span className="flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px]">graphic_eq</span>
                Transcrição Fonética (IPA):
              </span>
              {isLoadingPhonetics && (
                <span className="text-on-surface-variant/60 font-normal lowercase animate-pulse">
                  calculando fonemas...
                </span>
              )}
            </div>

            {phonetics?.phoneticIpa ? (
              <div className="bg-surface-container-low rounded-xl p-2.5 border border-surface-container">
                <span className="font-mono text-xs text-on-surface font-semibold tracking-wide block">
                  {phonetics.phoneticIpa}
                </span>
              </div>
            ) : null}
          </div>
        )}
      </div>

      {/* Action Button: Treinar */}
      <button
        onClick={() => handleSubmit()}
        disabled={!phrase.trim()}
        className={`h-13 w-full rounded-2xl font-headline font-bold text-sm flex items-center justify-center gap-2 transition-all duration-300 shadow-md ${
          phrase.trim()
            ? 'bg-primary hover:bg-indigo-700 text-white hover:shadow-lg active:scale-[0.98]'
            : 'bg-surface-container text-on-surface-variant/50 cursor-not-allowed'
        }`}
      >
        <span className="material-symbols-outlined text-[20px]">record_voice_over</span>
        <span>Treinar Esta Frase</span>
      </button>

      {/* Saved Phrases Section */}
      {savedList.length > 0 && (
        <div className="flex flex-col gap-2 mt-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-mono font-bold text-on-surface-variant uppercase tracking-wider flex items-center gap-1">
              <span className="material-symbols-outlined text-[16px] text-amber-500">bookmark</span>
              Biblioteca de Frases ({savedList.length})
            </span>
          </div>

          <div className="flex flex-col gap-1.5 max-h-48 overflow-y-auto pr-0.5">
            {savedList.map((saved, idx) => (
              <div
                key={idx}
                onClick={() => handleSelectExample(saved)}
                className="p-2.5 rounded-xl bg-surface-container-lowest hover:bg-surface-container border border-surface-container-high text-left text-xs text-on-surface transition-all flex items-center justify-between group cursor-pointer"
              >
                <span className="truncate italic pr-2 flex-1">"{saved}"</span>
                <div className="flex items-center gap-1 shrink-0">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      handlePlayAudio(saved);
                    }}
                    className="w-7 h-7 rounded-lg hover:bg-surface-container-high flex items-center justify-center text-on-surface-variant hover:text-primary transition-colors"
                    title="Ouvir"
                  >
                    <span className="material-symbols-outlined text-[16px]">volume_up</span>
                  </button>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      onStartTraining(saved);
                    }}
                    className="w-7 h-7 rounded-lg hover:bg-primary/10 flex items-center justify-center text-primary transition-colors"
                    title="Treinar direto"
                  >
                    <span className="material-symbols-outlined text-[16px]">record_voice_over</span>
                  </button>
                  <button
                    type="button"
                    onClick={(e) => handleDeleteSaved(saved, e)}
                    className="w-7 h-7 rounded-lg hover:bg-red-50 flex items-center justify-center text-on-surface-variant hover:text-red-500 transition-colors"
                    title="Remover"
                  >
                    <span className="material-symbols-outlined text-[16px]">delete</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Quick Suggestions / Inspiration */}
      <div className="flex flex-col gap-2 mt-1">
        <span className="text-xs font-mono font-bold text-on-surface-variant uppercase tracking-wider flex items-center gap-1">
          <span className="material-symbols-outlined text-[16px] text-amber-500">lightbulb</span>
          Sugestões Prontas
        </span>
        <div className="grid grid-cols-1 gap-1.5">
          {EXAMPLE_SUGGESTIONS.map((ex, idx) => (
            <button
              key={idx}
              type="button"
              onClick={() => handleSelectExample(ex)}
              className="p-2.5 rounded-xl bg-surface-container-lowest hover:bg-surface-container border border-surface-container text-left text-xs text-on-surface transition-all flex items-center justify-between group active:scale-[0.99]"
            >
              <span className="italic pr-2 leading-relaxed">"{ex}"</span>
              <span className="material-symbols-outlined text-[14px] text-primary shrink-0 opacity-60 group-hover:opacity-100">
                north_west
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
