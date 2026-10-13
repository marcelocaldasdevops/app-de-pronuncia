FROM python:3.11-slim

# Dependências de sistema para decodificação de áudio
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsndfile1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Variáveis de ambiente para execução do backend e faster-whisper
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    WHISPER_MODEL=base.en \
    WHISPER_DEVICE=cpu \
    WHISPER_COMPUTE_TYPE=int8 \
    PORT=8000

# Copia e instala dependências do Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Pré-download dos dados do NLTK para conversão fonética (G2P)
RUN python -c "import nltk; nltk.download('averaged_perceptron_tagger', download_dir='/usr/share/nltk_data'); nltk.download('cmudict', download_dir='/usr/share/nltk_data')"
ENV NLTK_DATA=/usr/share/nltk_data

# Pré-download dos pesos do modelo Faster-Whisper para startup imediato
RUN python -c "from faster_whisper import WhisperModel; WhisperModel('base.en', device='cpu', compute_type='int8')"

# Copia código do backend
COPY app/ /app/app/

EXPOSE 8000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
