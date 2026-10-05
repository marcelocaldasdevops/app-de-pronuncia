#!/bin/bash
set -e

echo "=== Instalando Flutter SDK no ambiente Vercel ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== Versao do Flutter ==="
flutter --version

echo "=== Compilando Flutter Web ==="
flutter build web --release --no-wasm-dry-run

echo "=== Build concluido com sucesso! ==="
