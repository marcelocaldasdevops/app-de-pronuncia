# T02 — Serviço Azure Speech (Pronunciation Assessment)

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M1 |
| Depende de | T01 |
| Estimativa | M |

## Objetivo

Criar `src/services/azureSpeech.ts` que avalia áudio + texto de referência via Azure PA (scripted), **sem Prosody**.

## Context (ler antes)

- ADR-002 e RFC-001 §3–§5
- [src/services/audioService.ts](../../../src/services/audioService.ts)
- Docs Microsoft: Pronunciation Assessment JS SDK

## Escopo

1. Adicionar dependency `microsoft-cognitiveservices-speech-sdk`.
2. Implementar algo na linha de:
   - `isConfigured(): boolean` (key + region presentes)
   - `assessPronunciation(params: { referenceText: string; audioBlob: Blob; locale?: string }): Promise<AzureRawResult>`
3. Locale default `en-US`; aceitar `en-GB` quando o exercício for UK.
4. **Não** chamar `enableProsodyAssessment` (custo add-on).
5. Erros claros se key ausente, rede falhar ou áudio inválido (throw / Result tipado com erro).
6. Não ligar ainda no GuidedScreen (isso é T04).

## Fora de escopo

- Adapter para `PronunciationResult` (T03)
- UI
- TTS Azure

## Critérios de aceite

- [x] Pacote SDK no `package.json`
- [x] Função exportada usável com Blob + referenceText
- [x] Prosody desabilitado
- [x] Sem key hardcoded; lê de `import.meta.env.VITE_*`
- [x] Build TypeScript passa

## Arquivos esperados

- `package.json` / lockfile
- `src/services/azureSpeech.ts` (criar)
- Tipagem interna do resultado bruto Azure (no mesmo arquivo ou `src/types/azure.ts`)
