#!/usr/bin/env bash
# Vocalis AI - Script para inicializar o backend Python
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "=== Vocalis AI - Backend de Avaliação Fonética ==="

# Verifica se o venv existe, se não, cria
if [ ! -d "venv" ]; then
    echo "Criando ambiente virtual Python (venv)..."
    python3 -m venv venv
fi

# Ativa o venv
source venv/bin/activate

# Instala dependências se necessário
echo "Verificando dependências em requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt

# Inicia o servidor FastAPI na porta 8000
echo "Iniciando servidor FastAPI na porta 8000 (http://localhost:8000)..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
