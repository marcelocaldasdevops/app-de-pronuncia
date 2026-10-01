import { PronunciationResult, WordEvaluation } from '../types';
import { ipaDictionary } from '../data/exercises';
import { huggingFaceSpeech } from './huggingFaceSpeech';
import { scorePronunciation } from './pronunciationScorerHF';
import { toPronunciationResult } from './huggingFaceAdapter';

const BACKEND_BASE_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8000';

export interface PhoneticsResponse {
  sentence: string;
  phoneticIpa: string;
  words: Array<{
    word: string;
    ipa: string;
    tip?: string;
  }>;
}

class PronunciationBackendService {
  private backendAlive: boolean | null = null;
  private lastCheckTime = 0;
  private readonly CHECK_CACHE_MS = 10_000;

  /**
   * Verifica se o backend Python/FastAPI está online
   */
  async isBackendAvailable(): Promise<boolean> {
    const now = Date.now();
    if (this.backendAlive !== null && now - this.lastCheckTime < this.CHECK_CACHE_MS) {
      return this.backendAlive;
    }

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2000);
      const res = await fetch(`${BACKEND_BASE_URL}/api/health`, {
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      this.backendAlive = res.ok;
      this.lastCheckTime = now;
      return res.ok;
    } catch {
      this.backendAlive = false;
      this.lastCheckTime = now;
      return false;
    }
  }

  /**
   * Obtém a transcrição fonética IPA e detalhes de uma frase em inglês.
   * Se o backend estiver offline, gera uma transcrição fonética aproximada com o dicionário local.
   */
  async getPhonetics(text: string): Promise<PhoneticsResponse> {
    const trimmed = text.trim();
    if (!trimmed) {
      return { sentence: '', phoneticIpa: '', words: [] };
    }

    const isAvailable = await this.isBackendAvailable();
    if (isAvailable) {
      try {
        const res = await fetch(`${BACKEND_BASE_URL}/api/g2p`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ text: trimmed }),
        });
        if (res.ok) {
          const data = await res.json();
          return data;
        }
      } catch (err) {
        console.warn('Erro ao chamar backend /api/g2p, usando fallback local:', err);
      }
    }

    // Fallback local usando ipaDictionary
    const wordsList = trimmed.match(/[a-zA-Z0-9']+/g) || [];
    const wordResults = wordsList.map((rawWord) => {
      const clean = rawWord.toLowerCase();
      const entry = ipaDictionary[clean];
      return {
        word: rawWord,
        ipa: entry ? entry.ipa : `/${clean}/`,
        tip: entry?.tip,
      };
    });

    const combinedIpa = wordResults.map((w) => w.ipa.replace(/^\/|\/$/g, '')).join(' ');

    return {
      sentence: trimmed,
      phoneticIpa: combinedIpa ? `/${combinedIpa}/` : '',
      words: wordResults,
    };
  }

  /**
   * Avalia a pronúncia de um áudio gravado contra a frase de referência.
   * Prioriza o backend Python (Wav2Vec2 Forced Alignment).
   * Se o backend estiver indisponível, faz fallback automático para o Hugging Face Whisper + Levenshtein.
   */
  async assessPronunciation(
    audioBlob: Blob,
    referenceText: string,
    liveTranscriptFallback = ''
  ): Promise<PronunciationResult> {
    const isAvailable = await this.isBackendAvailable();

    if (isAvailable) {
      try {
        const formData = new FormData();
        const audioFile = new File([audioBlob], 'recording.wav', { type: 'audio/wav' });
        formData.append('audio_file', audioFile);
        formData.append('reference_text', referenceText);

        const res = await fetch(`${BACKEND_BASE_URL}/api/assess`, {
          method: 'POST',
          body: formData,
        });

        if (res.ok) {
          const data = await res.json();
          return {
            overallScore: Math.round(data.overall_score ?? data.overallScore ?? 0),
            accuracyScore: Math.round(data.accuracy_score ?? data.accuracyScore ?? 0),
            fluencyScore: Math.round(data.fluency_score ?? data.fluencyScore ?? 0),
            completenessScore: Math.round(data.completeness_score ?? data.completenessScore ?? 0),
            transcript: data.transcript || referenceText,
            targetSentence: referenceText,
            words: (data.words || []).map((w: any): WordEvaluation => {
              const localEntry = ipaDictionary[w.word.toLowerCase()];
              return {
                word: w.word,
                spokenWord: w.spoken_word ?? w.spokenWord ?? w.word,
                status: w.status,
                score: Math.round(w.score),
                ipa: w.ipa || localEntry?.ipa || `/${w.word.toLowerCase()}/`,
                tip: w.tip || localEntry?.tip,
                phonemes: w.phonemes?.map((p: any) => ({
                  phoneme: p.phoneme,
                  score: Math.round(p.score),
                  status: p.status,
                  tip: p.tip,
                })),
              };
            }),
            feedbackSummary: data.feedback_summary || data.feedbackSummary || 'Avaliação fonética concluída com sucesso.',
            articulationTip: data.articulation_tip || data.articulationTip,
            provider: 'azure', // Usado como indicador de motor avançado
          };
        } else {
          console.warn('Backend retornou erro:', res.status, await res.text());
        }
      } catch (err) {
        console.warn('Falha na requisição ao backend Python, executando fallback local:', err);
      }
    }

    // ── Fallback Resiliente (HF Whisper ou WebSpeech) ─────────────────────
    let transcript = liveTranscriptFallback.trim();
    if (huggingFaceSpeech.isConfigured() && audioBlob.size > 0) {
      try {
        const hfResult = await huggingFaceSpeech.transcribeAudio(audioBlob);
        if (hfResult.text) transcript = hfResult.text;
      } catch (hfErr) {
        console.warn('Hugging Face STT falhou, usando transcrição ao vivo:', hfErr);
      }
    }

    const scoreResult = scorePronunciation(referenceText, transcript);
    return toPronunciationResult(scoreResult, referenceText);
  }
}

export const pronunciationBackendService = new PronunciationBackendService();
