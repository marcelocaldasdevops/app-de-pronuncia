# T01 — Env, gitignore e tipos base

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M1 |
| Depende de | — |
| Estimativa | S (pequena) |

## Objetivo

Preparar o projeto para receber a key Azure com segurança e estender tipos para o provider de score.

## Context (ler antes)

- [docs/adr/002-azure-pronunciation-assessment.md](../../adr/002-azure-pronunciation-assessment.md)
- [docs/rfc/001-mvp-architecture.md](../../rfc/001-mvp-architecture.md) §6 e §8
- [src/types/index.ts](../../../src/types/index.ts)

## Escopo

1. Criar `.gitignore` na raiz incluindo pelo menos: `node_modules/`, `dist/`, `.env`, `.env.local`, `.env.*.local`, Android/iOS Capacitor build noise se já existir depois.
2. Criar `.env.example` com:
   ```
   VITE_AZURE_SPEECH_KEY=
   VITE_AZURE_SPEECH_REGION=eastus
   ```
3. Em `PronunciationResult`, adicionar campos opcionais/compatíveis:
   - `provider: 'azure' | 'fallback'`
   - `prosodyScore?: number`
4. Não implementar chamada Azure nesta task.

## Fora de escopo

- Instalar SDK Azure
- Alterar GuidedScreen / scorer

## Critérios de aceite

- [x] `.env` está no `.gitignore`
- [x] `.env.example` existe e documenta as duas variáveis
- [x] `tsc` / tipos de `PronunciationResult` compilam com os novos campos
- [x] Nenhuma key real commitada

## Arquivos esperados

- `.gitignore` (criar)
- `.env.example` (criar)
- `src/types/index.ts` (editar)
