"""
Faster-Whisper STT Engine for local/self-hosted Speech-to-Text.
Operates without Hugging Face API tokens, using open-source Whisper weights.
Configurable via environment variables:
  - WHISPER_MODEL (default: "base.en")
  - WHISPER_DEVICE (default: "auto", options: "cpu", "cuda", "auto")
  - WHISPER_COMPUTE_TYPE (default: "int8" for CPU, "float16" for GPU)
"""

import io
import os
import threading
from typing import Dict, Any, Optional
import numpy as np
import soundfile as sf

try:
    import torch
    TORCH_AVAILABLE = True
except ImportError:
    torch = None
    TORCH_AVAILABLE = False

try:
    from faster_whisper import WhisperModel
    FASTER_WHISPER_AVAILABLE = True
except ImportError:
    WhisperModel = None
    FASTER_WHISPER_AVAILABLE = False


class WhisperSTTEngine:
    def __init__(self):
        self.model_name = os.getenv("WHISPER_MODEL", "base.en")
        # Default para cpu para máxima portabilidade em ambientes locais/containers sem GPU configurada
        device_env = os.getenv("WHISPER_DEVICE", "cpu").lower()

        if device_env == "auto":
            if TORCH_AVAILABLE and torch.cuda.is_available():
                self.device = "cuda"
            else:
                self.device = "cpu"
        else:
            self.device = device_env

        compute_env = os.getenv("WHISPER_COMPUTE_TYPE")
        if compute_env:
            self.compute_type = compute_env
        else:
            self.compute_type = "float16" if self.device == "cuda" else "int8"

        self.model: Optional[WhisperModel] = None
        self._lock = threading.Lock()
        self._loaded = False

    def is_ready(self) -> bool:
        return FASTER_WHISPER_AVAILABLE and self._loaded

    def load_model(self):
        """Loads the Faster-Whisper model into memory (lazy loaded)."""
        if not FASTER_WHISPER_AVAILABLE:
            raise RuntimeError("faster-whisper não está instalado no ambiente.")

        if self._loaded and self.model is not None:
            return

        with self._lock:
            if self._loaded and self.model is not None:
                return

            print(f"[WhisperSTT] Carregando modelo '{self.model_name}' (device={self.device}, compute_type={self.compute_type})...")
            self.model = WhisperModel(
                self.model_name,
                device=self.device,
                compute_type=self.compute_type
            )
            self._loaded = True
            print(f"[WhisperSTT] Modelo '{self.model_name}' carregado com sucesso.")

    def preprocess_audio(self, audio_bytes: bytes) -> np.ndarray:
        """
        Reads audio bytes (WAV 16kHz mono preferred) and returns a 1D float32 numpy array.
        """
        try:
            data, sample_rate = sf.read(io.BytesIO(audio_bytes), dtype="float32")
        except Exception:
            # Fallback para torchaudio se soundfile falhar
            if TORCH_AVAILABLE:
                import torchaudio
                waveform, sample_rate = torchaudio.load(io.BytesIO(audio_bytes))
                data = waveform.numpy().T
            else:
                raise ValueError("Não foi possível decodificar o arquivo de áudio.")

        # Converte para mono se necessário
        if data.ndim > 1:
            data = data.mean(axis=1)

        # Se a taxa de amostragem for diferente de 16000, faz resample simples
        target_sr = 16000
        if sample_rate != target_sr:
            if TORCH_AVAILABLE:
                import torchaudio
                tensor_wave = torch.from_numpy(data).unsqueeze(0)
                resampler = torchaudio.transforms.Resample(orig_freq=sample_rate, new_freq=target_sr)
                data = resampler(tensor_wave).squeeze(0).numpy()
            else:
                num_target_samples = int(len(data) * float(target_sr) / sample_rate)
                indices = np.linspace(0, len(data) - 1, num_target_samples)
                data = np.interp(indices, np.arange(len(data)), data).astype(np.float32)

        return data.astype(np.float32)

    def transcribe(self, audio_bytes: bytes, language: str = "en") -> Dict[str, Any]:
        """
        Transcribes the given audio bytes into text using faster-whisper.
        """
        if not FASTER_WHISPER_AVAILABLE:
            raise RuntimeError("faster-whisper não está disponível.")

        self.load_model()

        audio_array = self.preprocess_audio(audio_bytes)
        if len(audio_array) == 0:
            return {"text": "", "language": language, "duration": 0.0}

        try:
            segments, info = self.model.transcribe(
                audio_array,
                beam_size=5,
                language=language or "en",
                task="transcribe",
                vad_filter=False
            )
            texts = [seg.text.strip() for seg in segments if seg.text and seg.text.strip()]
            full_text = " ".join(texts).strip()
            return {
                "text": full_text,
                "language": info.language if info else language,
                "duration": getattr(info, "duration", float(len(audio_array) / 16000))
            }
        except RuntimeError as e:
            if "libcublas" in str(e) or "cuda" in str(e).lower():
                print(f"[WhisperSTT] Erro CUDA ({e}). Fazendo fallback automático para CPU int8...")
                with self._lock:
                    self.device = "cpu"
                    self.compute_type = "int8"
                    self._loaded = False
                    self.model = None
                self.load_model()
                segments, info = self.model.transcribe(
                    audio_array,
                    beam_size=5,
                    language=language or "en",
                    task="transcribe",
                    vad_filter=False
                )
                texts = [seg.text.strip() for seg in segments if seg.text and seg.text.strip()]
                full_text = " ".join(texts).strip()
                return {
                    "text": full_text,
                    "language": info.language if info else language,
                    "duration": getattr(info, "duration", float(len(audio_array) / 16000))
                }
            raise


# Instância global reutilizável
whisper_engine = WhisperSTTEngine()
