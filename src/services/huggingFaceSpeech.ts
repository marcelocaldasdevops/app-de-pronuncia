/**
 * Hugging Face Inference API service for speech recognition (STT).
 *
 * Uses the free serverless Whisper model endpoint to transcribe audio.
 * No GPU or self-hosting required — just a free HF token.
 *
 * Primary Model: openai/whisper-large-v3 (supported by HF Inference Providers)
 */

const HF_MODELS = [
  'openai/whisper-large-v3',
  'openai/whisper-large-v3-turbo',
];

function getHfApiUrl(model: string): string {
  return `https://router.huggingface.co/hf-inference/models/${model}`;
}

// Retry config for model cold starts (503 "Model is loading")
const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 5_000;

/**
 * Checks if Hugging Face token is configured in environment variables.
 */
export function isConfigured(): boolean {
  const token = import.meta.env.VITE_HF_TOKEN;
  return Boolean(token && token.trim().length > 0);
}

function getHfToken(): string {
  const token = import.meta.env.VITE_HF_TOKEN?.trim();
  if (!token) {
    throw new Error(
      'Hugging Face token não configurado. Defina VITE_HF_TOKEN no arquivo .env. ' +
      'Crie um token gratuito em https://huggingface.co/settings/tokens'
    );
  }
  return token;
}

// ──────────────────── Audio conversion helpers ────────────────────

function floatTo16BitPCM(samples: Float32Array): Int16Array {
  const output = new Int16Array(samples.length);
  for (let i = 0; i < samples.length; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    output[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
  }
  return output;
}

function encodeWav(pcmData: Int16Array, sampleRate: number): ArrayBuffer {
  const buffer = new ArrayBuffer(44 + pcmData.byteLength);
  const view = new DataView(buffer);

  view.setUint32(0, 0x52494646, false);  // RIFF
  view.setUint32(4, 36 + pcmData.byteLength, true);
  view.setUint32(8, 0x57415645, false);  // WAVE
  view.setUint32(12, 0x666d7420, false); // fmt
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);           // PCM
  view.setUint16(22, 1, true);           // mono
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  view.setUint32(36, 0x64617461, false); // data
  view.setUint32(40, pcmData.byteLength, true);

  const pcmView = new Int16Array(buffer, 44);
  pcmView.set(pcmData);

  return buffer;
}

/**
 * Converts any audio Blob to WAV (16kHz mono 16-bit PCM) for the HF API.
 */
async function convertBlobToWav(audioBlob: Blob): Promise<Blob> {
  const buffer = await audioBlob.arrayBuffer();

  // If already a valid WAV, return as-is
  if (buffer.byteLength >= 12) {
    const view = new DataView(buffer);
    const isRiff =
      view.getUint8(0) === 0x52 &&
      view.getUint8(1) === 0x49 &&
      view.getUint8(2) === 0x46 &&
      view.getUint8(3) === 0x46;
    const isWave =
      view.getUint8(8) === 0x57 &&
      view.getUint8(9) === 0x41 &&
      view.getUint8(10) === 0x56 &&
      view.getUint8(11) === 0x45;
    if (isRiff && isWave) {
      return new Blob([audioBlob], { type: 'audio/wav' });
    }
  }

  const AudioCtx =
    typeof window !== 'undefined'
      ? window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext
      : null;

  if (!AudioCtx) {
    throw new Error('Navegador não suporta Web Audio API para decodificação de áudio.');
  }

  const audioCtx = new AudioCtx();
  try {
    const audioBuffer = await audioCtx.decodeAudioData(buffer.slice(0));
    const targetSampleRate = 16000;

    const OfflineCtx =
      typeof window !== 'undefined'
        ? window.OfflineAudioContext ||
          (window as unknown as { webkitOfflineAudioContext: typeof OfflineAudioContext }).webkitOfflineAudioContext
        : null;

    let pcmSamples: Float32Array;

    if (OfflineCtx) {
      const lengthInSamples = Math.ceil(audioBuffer.duration * targetSampleRate);
      const offlineCtx = new OfflineCtx(1, lengthInSamples, targetSampleRate);
      const source = offlineCtx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(offlineCtx.destination);
      source.start(0);
      const renderedBuffer = await offlineCtx.startRendering();
      pcmSamples = renderedBuffer.getChannelData(0);
    } else {
      pcmSamples = audioBuffer.getChannelData(0);
    }

    const pcm16 = floatTo16BitPCM(pcmSamples);
    const wavBuffer = encodeWav(pcm16, OfflineCtx ? targetSampleRate : audioBuffer.sampleRate);
    return new Blob([wavBuffer], { type: 'audio/wav' });
  } finally {
    if (audioCtx.state !== 'closed') {
      await audioCtx.close();
    }
  }
}

// ──────────────────── Public API ────────────────────

export interface HfTranscriptionResult {
  /** Transcribed text from the audio */
  text: string;
}

/**
 * Transcribes an audio blob using Hugging Face Whisper models.
 * Automatically tries candidate models if one is not supported or loading.
 */
export async function transcribeAudio(audioBlob: Blob): Promise<HfTranscriptionResult> {
  if (!audioBlob || audioBlob.size === 0) {
    throw new Error('Áudio gravado inválido ou vazio.');
  }

  const token = getHfToken();
  const wavBlob = await convertBlobToWav(audioBlob);

  let lastError: Error | null = null;

  for (const model of HF_MODELS) {
    const apiUrl = getHfApiUrl(model);

    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        const response = await fetch(apiUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'audio/wav',
          },
          body: wavBlob,
        });

        if (response.status === 503) {
          // Model is loading — wait and retry
          const body = await response.json().catch(() => ({}));
          const waitTime = (body as { estimated_time?: number }).estimated_time
            ? Math.min(((body as { estimated_time: number }).estimated_time * 1000), 15_000)
            : RETRY_DELAY_MS;
          console.warn(`HF model ${model} loading, retrying in ${Math.round(waitTime / 1000)}s`);
          await new Promise((resolve) => setTimeout(resolve, waitTime));
          continue;
        }

        if (!response.ok) {
          const errorText = await response.text().catch(() => 'Unknown error');
          // If model not supported or 404/400, break to try next model in HF_MODELS
          if (response.status === 400 || response.status === 404) {
            lastError = new Error(`Erro na API (${response.status}) com modelo ${model}: ${errorText}`);
            break;
          }
          throw new Error(`Erro na API Hugging Face (${response.status}): ${errorText}`);
        }

        const data = await response.json();

        // Whisper returns { text: "transcription" }
        const text = typeof data === 'object' && data !== null && 'text' in data
          ? (data as { text: string }).text.trim()
          : '';

        return { text };
      } catch (err) {
        lastError = err instanceof Error ? err : new Error(String(err));
        if (attempt < MAX_RETRIES - 1 && lastError.message.includes('503')) {
          await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY_MS));
          continue;
        }
      }
    }
  }

  throw lastError || new Error('Falha ao transcrever áudio via Hugging Face após tentar os modelos disponíveis.');
}

/**
 * Simple speech recognition (STT) using HF — returns just the text.
 */
export async function recognizeSpeech(audioBlob: Blob): Promise<string> {
  const result = await transcribeAudio(audioBlob);
  return result.text;
}

export const huggingFaceSpeech = {
  isConfigured,
  transcribeAudio,
  recognizeSpeech,
};

export default huggingFaceSpeech;
