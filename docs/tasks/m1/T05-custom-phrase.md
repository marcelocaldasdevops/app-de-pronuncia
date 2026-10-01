# T05 — Treinar frase livre (frase própria)

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M1 |
| Depende de | T04 |
| Estimativa | M |

## Objetivo

Permitir digitar/colar uma frase em inglês e treinar com o mesmo pipeline Azure + Feedback.

## Context (ler antes)

- PRD §4.1 item 6, §5.3, RF-15–17
- RFC-001 §5.3
- [src/App.tsx](../../../src/App.tsx)
- [src/components/dashboard/DashboardScreen.tsx](../../../src/components/dashboard/DashboardScreen.tsx)
- [src/types/index.ts](../../../src/types/index.ts)

## Escopo

1. Novo modo de tela ou fluxo: editor de frase (`CustomPhraseScreen` ou equivalente em `src/components/custom-phrase/`).
2. Campo texto (limite ~200 chars), validação não-vazio.
3. Botão “Treinar esta frase” cria `Exercise` ad-hoc:
   - `category: 'Frase própria'`
   - IPA/tip opcionais / genéricos
   - `accent: 'US'` default
4. Reutilizar `GuidedScreen` + `FeedbackModal`.
5. No feedback em modo custom: ação **Nova frase** volta ao editor (não avança catálogo).
6. Atalho no Dashboard: “Treinar minha frase”.
7. Lista de recentes pode ser in-memory nesta task; persistência real fica para T06 (ou stub `sessionStorage` ok).

## Fora de escopo

- Capacitor
- Free speaking / Emma
- Geração automática de IPA com LLM

## Critérios de aceite

- [x] Dá para digitar frase, ouvir TTS, gravar e ver Feedback Azure
- [x] “Nova frase” volta ao editor
- [x] Catálogo guiado continua funcionando independente
- [x] RF-15 e RF-17 cobertos

## Arquivos esperados

- `src/components/custom-phrase/*` (criar)
- `src/App.tsx`, `DashboardScreen.tsx`, possivelmente `FeedbackModal.tsx` / tipos de `ScreenMode`
