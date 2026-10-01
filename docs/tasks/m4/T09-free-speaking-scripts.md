# T09 — Free speaking v1.1 (scripts, sem texto fake)

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M4 |
| Depende de | T05 |
| Estimativa | M |

## Objetivo

Conversação com Emma sem inventar fala do usuário; respostas por script; STT real.

## Context (ler antes)

- PRD §4.2 e §5.5
- RFC-001 §5.5
- [src/components/free-speaking/FreeSpeakingScreen.tsx](../../../src/components/free-speaking/FreeSpeakingScreen.tsx)

## Escopo

1. Remover fallback `"Could I have a black coffee..."`.
2. Se transcript vazio ao parar: avisar e não postar bolha falsa.
3. Extrair diálogos para `src/data/dialogues/` (ex.: coffee-nyc) com ramificações simples por keyword.
4. Preferir Azure STT se T02 expuser API de recognition; senão Web Speech ok com aviso.
5. Manter TTS Web Speech nas respostas da IA.
6. Sem LLM.

## Fora de escopo

- Pronunciation Assessment em cada turno
- Gemini/Claude
- Multi-tópico completo (um tópico bem feito basta)

## Critérios de aceite

- [x] Sem mensagem de usuário inventada
- [x] Pelo menos 2–3 ramificações de resposta da Emma
- [x] Erro de mic tratado

## Arquivos esperados

- `FreeSpeakingScreen.tsx`
- `src/data/dialogues/*`
