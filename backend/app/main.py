"""
Vocalis AI - Pronunciation Assessment Backend (FastAPI).
Provides endpoints for phoneme-level forced alignment acoustic scoring and G2P.
"""

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Query
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any
import edge_tts

from .engine.aligner import aligner
from .engine.phonetics import sentence_to_ipa

app = FastAPI(
    title="Vocalis AI - Pronunciation Engine",
    description="Backend de avaliação fonética e alinhamento forçado acústico para treino de pronúncia em inglês.",
    version="1.0.0"
)

# Configuração de CORS para permitir acesso do Vite e do Capacitor
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class G2PRequest(BaseModel):
    text: str

@app.get("/")
def root():
    return {
        "app": "Vocalis AI - Pronunciation Engine",
        "status": "online",
        "docs": "/docs"
    }

@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "engine": "wav2vec2" if aligner.is_ready() else "cloud-lightweight",
        "model_loaded": aligner.is_ready()
    }

@app.get("/api/tts")
async def text_to_speech(
    text: str = Query(..., description="Texto em inglês a sintetizar"),
    voice: str = Query("en-US-JennyNeural", description="Voz neural (ex: en-US-JennyNeural, en-GB-SoniaNeural, en-US-GuyNeural)"),
    rate: str = Query("+0%", description="Ajuste de velocidade (ex: +0%, -20%, +15%)")
):
    """
    Síntese neural de altíssima fidelidade e naturalidade para inglês nativo.
    Funciona diretamente no navegador Web e mobile sem depender do Web Speech API ou do SO local.
    """
    if not text or not text.strip():
        raise HTTPException(status_code=400, detail="Texto não pode ser vazio.")

    try:
        communicate = edge_tts.Communicate(text.strip(), voice, rate=rate)
        mp3_buffer = bytearray()
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                mp3_buffer.extend(chunk["data"])

        return Response(content=bytes(mp3_buffer), media_type="audio/mpeg")
    except Exception as e:
        print(f"[API Error] TTS failed: {e}")
        raise HTTPException(status_code=500, detail=f"Erro na síntese neural de áudio: {str(e)}")

@app.post("/api/g2p")
def grapheme_to_phoneme(req: G2PRequest):
    """
    Recebe um texto em inglês e retorna a transcrição fonética IPA
    completa com decomposição em palavras e fonemas individuais.
    """
    if not req.text or not req.text.strip():
        raise HTTPException(status_code=400, detail="Texto de entrada não pode ser vazio.")

    result = sentence_to_ipa(req.text.strip())
    return {
        "sentence": result["sentence"],
        "phoneticIpa": result["phonetic_ipa"],
        "friendlyPhonetic": result.get("friendly_phonetic", ""),
        "words": result["words"]
    }

@app.post("/api/assess")
async def assess_pronunciation(
    audio_file: UploadFile = File(...),
    reference_text: str = Form(...)
):
    """
    Recebe um arquivo de áudio gravado e o texto de referência.
    Executa alinhamento forçado e avaliação fonética acústica.
    """
    if not reference_text or not reference_text.strip():
        raise HTTPException(status_code=400, detail="Texto de referência é obrigatório.")

    try:
        audio_bytes = await audio_file.read()
        if len(audio_bytes) == 0:
            raise HTTPException(status_code=400, detail="Arquivo de áudio enviado está vazio.")

        result = aligner.assess(audio_bytes, reference_text.strip())
        return result
    except Exception as e:
        print(f"[API Error] assess_pronunciation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno no processamento acústico: {str(e)}")

@app.on_event("startup")
def startup_event():
    print("[Startup] Vocalis AI Backend inicializado em modo nuvem leve (FastAPI + G2P + EdgeTTS).")
