# T08 — Card de revisão com dados reais

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M3 |
| Depende de | T06 |
| Estimativa | S |

## Objetivo

O card “Revisão de Dificuldades” no Dashboard usa histórico real de `weakWords` / `weakPhonemes`, não o mock fixo `/θ/ e /ð/`.

## Context (ler antes)

- PRD RF-11
- RFC-001 §5.4
- [src/components/dashboard/DashboardScreen.tsx](../../../src/components/dashboard/DashboardScreen.tsx)

## Escopo

1. Derivar da lista de `attempts` a palavra/fonema mais frequente em `needs_work`.
2. Exibir no card; CTA “Treinar” abre Guided (filtro por fonema é nice-to-have; deep-link genérico ok).
3. Empty state se ainda não houver tentativas (“Pratique para ver suas dificuldades”).

## Fora de escopo

- Algoritmo SRS completo
- Backend

## Critérios de aceite

- [x] Após erros repetidos na mesma palavra, o card reflete isso
- [x] Empty state sem dados
- [x] Não quebra Dashboard sem attempts

## Arquivos esperados

- `DashboardScreen.tsx` / helpers em `storage` ou `services`
