import React, { useState, useEffect, useRef } from 'react';
import { ConversationMessage } from '../../types';
import { speechService } from '../../services/speechService';
import { audioService } from '../../services/audioService';
import { huggingFaceSpeech } from '../../services/huggingFaceSpeech';
import { coffeeNycScenario, matchDialogueResponse } from '../../data/dialogues';

interface FreeSpeakingScreenProps {
  onBackToDashboard: () => void;
}

export const FreeSpeakingScreen: React.FC<FreeSpeakingScreenProps> = ({ onBackToDashboard }) => {
  const [messages, setMessages] = useState<ConversationMessage[]>([
    {
      id: 'm1',
      sender: 'ai',
      text: coffeeNycScenario.initialMessage.text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      suggestion: coffeeNycScenario.initialMessage.suggestion,
    },
  ]);

  const [isRecording, setIsRecording] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [interimText, setInterimText] = useState('');
  const [playingMessageId, setPlayingMessageId] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [infoMessage, setInfoMessage] = useState<string | null>(null);

  const messagesEndRef = useRef<HTMLDivElement | null>(null);
  const isHfConfigured = huggingFaceSpeech.isConfigured();

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, interimText, isProcessing]);

  const handlePlayAudio = async (msg: ConversationMessage) => {
    if (playingMessageId === msg.id) {
      speechService.stopSpeech();
      setPlayingMessageId(null);
      return;
    }

    setPlayingMessageId(msg.id);
    await speechService.speak(msg.text, 1.0, 'en-US');
    setPlayingMessageId(null);
  };

  const handleToggleRecord = async () => {
    if (isRecording) {
      // STOP recording
      setIsRecording(false);
      speechService.stopRecognition();

      setIsProcessing(true);
      const audioBlob = await audioService.stopRecording();

      let finalText = '';

      // Prefer HF STT if configured; otherwise use Web Speech interimText
      if (isHfConfigured && audioBlob && audioBlob.size > 0) {
        try {
          const hfText = await huggingFaceSpeech.recognizeSpeech(audioBlob);
          finalText = hfText.trim();
        } catch (err: any) {
          console.warn('HF STT falhou, tentando transcript Web Speech:', err);
          finalText = interimText.trim();
        }
      } else {
        finalText = interimText.trim();
      }

      setInterimText('');
      setIsProcessing(false);

      // Acceptance criterion: No fake user messages. If empty, warn and do not post.
      const cleanedText = finalText.replace(/^[\s.,!?;:'"]+|[\s.,!?;:'"]+$/g, '');
      if (!cleanedText) {
        setInfoMessage('Nenhuma fala detectada. Pressione o microfone e tente falar novamente.');
        return;
      }

      setInfoMessage(null);
      setErrorMessage(null);

      const newUserMsg: ConversationMessage = {
        id: `user-${Date.now()}`,
        sender: 'user',
        text: finalText,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };

      setMessages((prev) => [...prev, newUserMsg]);

      // Generate scripted dialogue response based on keywords
      setTimeout(() => {
        const matched = matchDialogueResponse(finalText, coffeeNycScenario);

        const newAiMsg: ConversationMessage = {
          id: `ai-${Date.now()}`,
          sender: 'ai',
          text: matched.text,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          suggestion: matched.suggestion,
        };

        setMessages((prev) => [...prev, newAiMsg]);
        speechService.speak(matched.text, 1.0, 'en-US');
      }, 700);

    } else {
      // START recording
      setErrorMessage(null);
      setInfoMessage(null);
      setInterimText('');

      try {
        const ok = await audioService.startRecording();
        if (!ok) {
          setErrorMessage('Não foi possível acessar o microfone. Verifique as permissões de áudio do dispositivo.');
          return;
        }

        setIsRecording(true);

        // Start Web Speech for interim preview if supported
        if (speechService.isRecognitionSupported()) {
          speechService.startRecognition(
            (transcript) => {
              setInterimText(transcript);
            },
            (err) => {
              console.warn('Speech recognition warning:', err);
            },
            () => {}
          );
        }
      } catch (err: any) {
        console.error('Erro ao iniciar gravação:', err);
        setErrorMessage('Erro ao iniciar o microfone. Tente novamente.');
        setIsRecording(false);
      }
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)] max-w-md mx-auto bg-surface pb-16 animate-fade-in">
      
      {/* Top Bar with AI Partner Header */}
      <div className="p-4 bg-surface/90 backdrop-blur-md border-b border-surface-container-high flex items-center justify-between shrink-0">
        <div className="flex items-center gap-3">
          <button
            onClick={onBackToDashboard}
            className="w-8 h-8 rounded-full bg-surface-container flex items-center justify-center text-on-surface hover:bg-surface-container-high transition-colors"
            title="Voltar ao início"
          >
            <span className="material-symbols-outlined text-[18px]">arrow_back</span>
          </button>
          <div className="relative">
            <img
              src={coffeeNycScenario.avatarUrl}
              alt={coffeeNycScenario.partnerName}
              className="w-10 h-10 rounded-full object-cover border-2 border-primary/20 shadow-sm"
              onError={(e) => {
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
            <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-emerald-500 border-2 border-white"></span>
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <h3 className="font-headline font-bold text-sm text-on-surface">
                {coffeeNycScenario.partnerName}
              </h3>
              <span className="text-[10px] font-mono bg-primary-fixed text-primary px-1.5 py-0.2 rounded font-semibold">
                {coffeeNycScenario.partnerBadge}
              </span>
            </div>
            <p className="text-[11px] text-on-surface-variant">{coffeeNycScenario.title}</p>
          </div>
        </div>

        {/* STT Engine Badge */}
        <div className="flex items-center">
          {isHfConfigured ? (
            <span
              className="text-[10px] font-mono bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded-full flex items-center gap-1"
              title="Reconhecimento via Hugging Face Wav2Vec2 STT"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
              HF STT
            </span>
          ) : (
            <span
              className="text-[10px] font-mono bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded-full flex items-center gap-1"
              title="Hugging Face não configurado no .env. Usando Web Speech API do navegador."
            >
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
              Web Speech
            </span>
          )}
        </div>
      </div>

      {/* Warning/Error Notice Banners */}
      {errorMessage && (
        <div className="m-3 p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-800 flex items-start justify-between gap-2 shadow-sm animate-fade-in">
          <div className="flex items-start gap-2">
            <span className="material-symbols-outlined text-red-600 text-[18px] shrink-0 mt-0.5">
              mic_off
            </span>
            <span>{errorMessage}</span>
          </div>
          <button
            onClick={() => setErrorMessage(null)}
            className="text-red-500 hover:text-red-700 text-xs"
          >
            ✕
          </button>
        </div>
      )}

      {infoMessage && (
        <div className="m-3 p-3 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-900 flex items-start justify-between gap-2 shadow-sm animate-fade-in">
          <div className="flex items-start gap-2">
            <span className="material-symbols-outlined text-amber-600 text-[18px] shrink-0 mt-0.5">
              info
            </span>
            <span>{infoMessage}</span>
          </div>
          <button
            onClick={() => setInfoMessage(null)}
            className="text-amber-600 hover:text-amber-800 text-xs"
          >
            ✕
          </button>
        </div>
      )}

      {/* Messages Timeline */}
      <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-4">
        {messages.map((m) => {
          const isAi = m.sender === 'ai';
          const isPlaying = playingMessageId === m.id;

          return (
            <div
              key={m.id}
              className={`flex flex-col max-w-[85%] ${isAi ? 'self-start items-start' : 'self-end items-end'}`}
            >
              <div
                className={`p-3.5 rounded-2xl shadow-sm text-sm relative ${
                  isAi
                    ? 'bg-surface-container-lowest border border-surface-container-high text-on-surface rounded-tl-sm'
                    : 'bg-primary text-white rounded-tr-sm'
                }`}
              >
                <p className="leading-relaxed">{m.text}</p>

                {/* Audio button for AI */}
                {isAi && (
                  <button
                    onClick={() => handlePlayAudio(m)}
                    className={`mt-2 flex items-center gap-1 text-[11px] font-mono font-semibold px-2.5 py-1 rounded-full transition-all ${
                      isPlaying
                        ? 'bg-primary text-white shadow-sm'
                        : 'bg-surface-container hover:bg-surface-container-high text-primary'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[15px]">
                      {isPlaying ? 'volume_up' : 'play_arrow'}
                    </span>
                    <span>{isPlaying ? 'Ouvindo...' : 'Ouvir resposta'}</span>
                  </button>
                )}
              </div>

              {/* Timestamp */}
              <span className="text-[10px] font-mono text-on-surface-variant mt-1 px-1">
                {m.timestamp}
              </span>

              {/* Learning / Naturalness Suggestion */}
              {m.suggestion && (
                <div className="mt-1 p-2 rounded-xl bg-amber-50/80 border border-amber-200/60 text-[11px] text-amber-900 flex items-start gap-1.5">
                  <span className="material-symbols-outlined text-amber-600 text-[14px] shrink-0 mt-0.5">
                    lightbulb
                  </span>
                  <span>{m.suggestion}</span>
                </div>
              )}
            </div>
          );
        })}

        {/* Live Interim Speech Bubble */}
        {isRecording && (
          <div className="self-end max-w-[85%] flex flex-col items-end animate-fade-in">
            <div className="p-3.5 rounded-2xl bg-primary/80 text-white rounded-tr-sm italic text-sm border border-primary/50 shadow-sm flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-white animate-ping"></span>
              <span>{interimText || 'Ouvindo sua resposta...'}</span>
            </div>
          </div>
        )}

        {/* Processing Indicator */}
        {isProcessing && (
          <div className="self-end max-w-[85%] flex flex-col items-end animate-fade-in">
            <div className="p-3 rounded-2xl bg-surface-container text-on-surface-variant text-xs flex items-center gap-2 border border-surface-container-high">
              <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
              <span>Transcrevendo fala...</span>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Bottom Microphone Bar */}
      <div className="p-3 bg-surface/95 backdrop-blur-md border-t border-surface-container-high shrink-0 flex items-center gap-3">
        <div className="flex-1 bg-surface-container rounded-full px-4 py-2.5 text-xs text-on-surface-variant truncate">
          {isRecording
            ? 'Gravando resposta de voz... Toque no botão para parar'
            : isProcessing
            ? 'Transcrevendo áudio...'
            : 'Pressione o microfone para falar com a Emma'}
        </div>

        <button
          onClick={handleToggleRecord}
          disabled={isProcessing}
          className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-300 shadow-md ${
            isProcessing
              ? 'bg-slate-300 text-slate-500 cursor-not-allowed'
              : isRecording
              ? 'bg-red-500 text-white animate-pulse shadow-mic scale-110'
              : 'bg-primary hover:bg-indigo-700 text-white active:scale-95'
          }`}
          title={isRecording ? 'Parar gravação' : 'Falar'}
        >
          <span
            className="material-symbols-outlined text-[24px]"
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
            {isRecording ? 'stop' : 'mic'}
          </span>
        </button>
      </div>

    </div>
  );
};
