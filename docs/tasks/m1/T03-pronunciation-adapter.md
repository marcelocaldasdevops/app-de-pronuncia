# T03 — Adapter Azure → PronunciationResult

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M1 |
| Depende de | T02 |
| Estimativa | M |

## Objetivo

Converter a resposta bruta do Azure no contrato já usado pela UI (`PronunciationResult` / `WordEvaluation`).

## Context (ler antes)

- ADR-002 seção “Mapeamento Azure → UI”
- RFC-001 §4 (limiares)
- [src/services/pronunciationScorer.ts](../../../src/services/pronunciationScorer.ts) (referência do shape atual)
- [src/data/exercises.ts](../../../src/data/exercises.ts) (`ipaDictionary`)
- [src/components/feedback/FeedbackModal.tsx](../../../src/components/feedback/FeedbackModal.tsx)

## Escopo

1. Criar `src/services/pronunciationAdapter.ts` com `toPronunciationResult(azureRaw, targetSentence): PronunciationResult`.
2. Limiares (constante única `SCORE_THRESHOLDS`):
   - ≥ 85 → `mastered`
   - ≥ 60 → `near`
   - < 60 / omissão → `needs_work`
3. Preencher `ipa` / `tip` via `ipaDictionary` quando existir; senão tip genérico em PT.
4. Setar `provider: 'azure'`.
5. Cobrir palavras omitidas / não reconhecidas sem quebrar o modal.
6. (Opcional mas desejável) testes unitários simples dos limiares se o projeto já tiver runner; senão deixar função pura testável e documentar exemplos no comentário do arquivo.

## Fora de escopo

- Chamar a rede
- Mudar FeedbackModal visualmente

## Critérios de aceite

- [x] Saída compatível com `FeedbackModal` atual
- [x] `provider === 'azure'`
- [x] Limiares centralizados (sem magic numbers espalhados)
- [x] Omissão de palavra não crasha

## Arquivos esperados

- `src/services/pronunciationAdapter.ts` (criar)
