#!/usr/bin/env bash
set -euo pipefail

# Stitch Project Details
PROJECT_ID="17171229454186438520"
API_KEY="${STITCH_API_KEY:-AQ.Ab8RN6KXCnHNpMJITYObE3knWJE4YwJYh1CWODfYnogyr1SkBg}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${SCRIPT_DIR}"

echo "=========================================================="
echo "Iniciando download dos ativos do Stitch (Vocalis AI)"
echo "Projeto ID: ${PROJECT_ID}"
echo "Destino: ${BASE_DIR}"
echo "=========================================================="

mkdir -p "${BASE_DIR}/design-system"
mkdir -p "${BASE_DIR}/assets"
mkdir -p "${BASE_DIR}/screens/html"
mkdir -p "${BASE_DIR}/screens/screenshots"

# 1. Download do Avatar do Estudante (fa8ba48dfca547859e6d597ec16841f0)
echo "📥 [1/7] Baixando Avatar do Estudante..."
curl -s -L "https://lh3.googleusercontent.com/aida/AEtjO1Wb25CcOuLRzG9YyoFUTDwlsJ448orDjzZX2SXnLbiG-Zl121FGNozka7A-CzVavhPmbSFmpx5ZZRx5QWntZc22aImiOsmW7LawIY7pFA9Y-YXf6FEJbXBj8UHYygFywxzmeWF5Qnu7xK9DttbMa9A1vbyLijAnmYDMCznvtr7L8IDGUsFWjc4qzN7Js9QMwv1srEpl0T_lHX25XI2C8P78JO6hxaTNrmfqTcuzamHN-DpNW6r8iG2W5RWJ" -o "${BASE_DIR}/assets/avatar.jpg"

# 2. Download do Logo Vocalis AI (e85b1abaf864464385d7a312d378cbf0)
echo "📥 [2/7] Baixando Logo Vocalis AI (SVG & Preview)..."
curl -s -L -H "X-Goog-Api-Key: ${API_KEY}" "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YzI1OTQzMWYxYWUwMjJkNmFkMGU0MjI4NmM4EgsSBxD918S8tg0YAZIBJAoKcHJvamVjdF9pZBIWQhQxNzE3MTIyOTQ1NDE4NjQzODUyMA&filename=&opi=89354086" -o "${BASE_DIR}/assets/logo.svg"
curl -s -L "https://lh3.googleusercontent.com/aida/AEtjO1WKBvik2uwgRzKjTHnyhtinIS-W-7cjKOYJlFBFnYXXYOnhnOgJgSUav3pyMzKXS4pY-e63nucpNoSLJGZ8i9UwBtvlkmKG2DE9Q2Sg0kVgEr9J5qd155toVVokBRtM38gEhZQbvfFLPcePaMD1bBkn_Hc1Xi4xuukWLa7ak3MXAg7XZ3B2P64S6pwyVtL9DQ56H21cAJVSPCSZWrLrE40Z9zdvQpWu0jo0Cus54C7XfsTxj3M8TNflyw" -o "${BASE_DIR}/assets/logo-preview.png"

# 3. Tela 1 - Dashboard (7f299882443447b2bb47d192972b54a6)
echo "📥 [3/7] Baixando Tela 1: Dashboard..."
curl -s -L -H "X-Goog-Api-Key: ${API_KEY}" "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YzI1OThiODFiMjEwNTIyOTU1ZDliM2M3NDhhEgsSBxD918S8tg0YAZIBJAoKcHJvamVjdF9pZBIWQhQxNzE3MTIyOTQ1NDE4NjQzODUyMA&filename=&opi=89354086" -o "${BASE_DIR}/screens/html/01_dashboard.html"
curl -s -L "https://lh3.googleusercontent.com/aida/AEtjO1XDtYA6G4M9zRKHPiFiM604J0slIc6BeAYhkZADcM4ij5fVqNqGMHL3Y7UV9460OKld4521eQki-kFaphBISgsvdo_MkWGmazj247VMybGj6uZ-zLVuhhdMLIuZKhQYIoK-WrvvbP19bUm4qckhd6ytRsARgS3uhErE8iEh8tskyfcFlqJxnp1tyx5dJY9uZZgN4qkjYjNwUoWh9V9BisYnIOIBB7CxUpbKQeXOEhoSOXbUtr8Mq91-1W-L" -o "${BASE_DIR}/screens/screenshots/01_dashboard.png"

# 4. Tela 2 - Repetição Guiada (a06053eaf5e0433a95dc4b2db52be76b)
echo "📥 [4/7] Baixando Tela 2: Repetição Guiada..."
curl -s -L -H "X-Goog-Api-Key: ${API_KEY}" "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YzI1OTdjZTJiZmIwODlhZjVhNGIzMDBiZWQ5EgsSBxD918S8tg0YAZIBJAoKcHJvamVjdF9pZBIWQhQxNzE3MTIyOTQ1NDE4NjQzODUyMA&filename=&opi=89354086" -o "${BASE_DIR}/screens/html/02_repeticao_guiada.html"
curl -s -L "https://lh3.googleusercontent.com/aida/AEtjO1UWfeAk5FhwPPNpVsEVIwGyhynrgsT-bWc0YveOeyICHfeacA4vD-mEGqpYnEHg2aMb4dO-5hxkmodD49EwN-WtZo6SqKSILbkGCNH5sGvfztWVCUmWkFR9-6MUpWyhefuKX22M-aHARpBKcD3zEAP-Ybs43uqjxo2AyFULDnAIX69p0TsxfgnSNDNiOx-QXKChBd-NLBiNLPO6FHXSbBpb7HFAY6lv_RRurQmW7E3KjRIoPbC0pUg4GcPC" -o "${BASE_DIR}/screens/screenshots/02_repeticao_guiada.png"

# 5. Tela 3 - Feedback de Pronúncia (038f297e5fee4d46bda084e5c28ca310)
echo "📥 [5/7] Baixando Tela 3: Feedback de Pronúncia..."
curl -s -L -H "X-Goog-Api-Key: ${API_KEY}" "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YzI1OTc3ZTRjOGQwMWVlNDk5ZmJhMzMyOTc2EgsSBxD918S8tg0YAZIBJAoKcHJvamVjdF9pZBIWQhQxNzE3MTIyOTQ1NDE4NjQzODUyMA&filename=&opi=89354086" -o "${BASE_DIR}/screens/html/03_feedback_pronuncia.html"
curl -s -L "https://lh3.googleusercontent.com/aida/AEtjO1XNnGOw_kjS-I3LFMdnM5VB2iNAz439N30HPvVN48Dmv3DIxuxU0GQJOci6f2PkNDNjovy7qgsb3t1MZOFvpL1wceVCu2IEdsVCfc6VJ6VcbFoGvF3PIOueCCGr39WKG0bnIbE7QKICEIWVj-FJ1y4tZ9HEfZJIXbDdhY_4EM81iCPXSKlIRrbju97V5K7oOo0nSIqQ6z2lsAkjbSHH2nDBrs_I_FIAf86g9OC6JPTkDjGVGgPk-dJUh7Y" -o "${BASE_DIR}/screens/screenshots/03_feedback_pronuncia.png"

# 6. Tela 4 - Conversação Livre (c1e40a27257e47848d8d4bd8f6df2f82)
echo "📥 [6/7] Baixando Tela 4: Conversação Livre..."
curl -s -L -H "X-Goog-Api-Key: ${API_KEY}" "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YzI1OTgzMWVhZjMwN2M0ZWRhOGY3MzZmZGZmEgsSBxD918S8tg0YAZIBJAoKcHJvamVjdF9pZBIWQhQxNzE3MTIyOTQ1NDE4NjQzODUyMA&filename=&opi=89354086" -o "${BASE_DIR}/screens/html/04_conversacao_livre.html"
curl -s -L "https://lh3.googleusercontent.com/aida/AEtjO1XY4oawX62cQBJD_Nkp2YEvNTit4g26pcR_CafHU3CmAUt7e9sAm_ybSUYaJmwbG7sNDo5r6dru9LGfajBlE3FXHFUJizBkOkf-ULxadiFc5Aljpnq6mcRWZcafWfIg_DosvwyS7gluNC9OQonRt2ikEU8TNXpD1xff2Cteg1jGip3FcAhd5MoReRifoxgikgq45gFoVDuP7PJJFu1Hyk5cBWnfC9sdmr4uqHPEetPdHm3JMYV3fz18FT3Y" -o "${BASE_DIR}/screens/screenshots/04_conversacao_livre.png"

echo "✅ [7/7] Todos os downloads do Stitch foram concluídos com sucesso!"
