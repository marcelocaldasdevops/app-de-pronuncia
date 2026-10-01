# T04 — GuidedScreen usa Azure (remover score falso)

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M1 |
| Depende de | T03 |
| Estimativa | M |

## Objetivo

No caminho feliz do modo guiado, o score vem do Azure. Remover o fallback que pontua a frase alvo quando o transcript vem vazio.

## Context (ler antes)

- [src/components/guided/GuidedScreen.tsx](../../../src/components/guided/GuidedScreen.tsx) — hoje usa `evaluatePronunciation` + `liveTranscript || exercise.sentence`
- T02 / T03
- PRD RF-04, RF-14 e critério de aceite 1–2

## Escopo

1. Ao parar gravação: pegar `Blob` de `audioService.stopRecording()`.
2. Chamar `azureSpeech.assessPronunciation` + `toPronunciationResult`.
3. Passar resultado para `onFinishEvaluation`.
4. **Remover** `liveTranscript || exercise.sentence` do caminho de score.
5. Se Azure não configurado / erro: mostrar mensagem na UI; **não** abrir Feedback com score inventado.
6. Manter waveform, TTS Web Speech e preview STT opcional (preview não alimenta score).
7. Deprecar uso de `evaluatePronunciation` no Guided (pode deixar o arquivo Levenshtein no repo, mas fora do happy path).

## Fora de escopo

- Frase própria (T05)
- Persistência (T06)
- Capacitor (T07)

## Critérios de aceite

- [x] Com `.env` válido, gravar uma frase do catálogo abre Feedback com scores Azure
- [x] Sem `.env` / erro de rede: mensagem clara, sem modal de sucesso falso
- [x] Preview STT (se existir) não substitui o score
- [x] `npm run build` passa

## Arquivos esperados

- `src/components/guided/GuidedScreen.tsx` (editar)
- Possível ajuste fino em `audioService.ts` se o formato do Blob precisar alinhar ao SDK
