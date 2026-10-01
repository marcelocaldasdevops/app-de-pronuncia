# T06 — Persistência local (stats, attempts, customPhrases)

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M3 |
| Depende de | T04 |
| Estimativa | M |

## Objetivo

Persistir progresso entre sessões com `localStatsStore` (`vocalis.progress.v1`).

## Context (ler antes)

- RFC-001 §4.2 e §7
- [src/App.tsx](../../../src/App.tsx) (stats em `useState` + `initialUserStats`)
- [src/data/exercises.ts](../../../src/data/exercises.ts)

## Escopo

1. Criar `src/storage/localStatsStore.ts` com load/save de `LocalProgress`.
2. Regras de streak e `sentencesToday` conforme RFC.
3. Registrar `AttemptRecord` após cada avaliação bem-sucedida (catálogo ou custom).
4. Persistir `customPhrases` (máx. 20) se T05 já existir; senão preparar o campo vazio.
5. Remover dependência de stats hardcoded “Carlos” / valores fake de demo no load inicial (saudação genérica ok).
6. Usar `localStorage` (Preferences Capacitor fica nota TODO se WebView falhar).

## Fora de escopo

- Card de revisão inteligente (T08)
- Sync cloud

## Critérios de aceite

- [x] Reload da página mantém streak / frases do dia / média
- [x] Nova tentativa incrementa e persiste
- [x] Schema versionado (`v1`) fácil de migrar depois

## Arquivos esperados

- `src/storage/localStatsStore.ts`
- `src/App.tsx` (+ possivelmente types)
