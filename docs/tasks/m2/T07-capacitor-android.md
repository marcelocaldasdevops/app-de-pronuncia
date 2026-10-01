# T07 — Capacitor Android + microfone

| Campo | Valor |
|-------|-------|
| Status | done |
| Marco | M2 |
| Depende de | T04 |
| Estimativa | L |

## Objetivo

Empacotar o app React com Capacitor e garantir microfone no Android (debug build).

## Context (ler antes)

- ADR-001
- RFC-001 §11 passo Capacitor
- PRD RF-13

## Escopo

1. Inicializar Capacitor (`webDir: dist`).
2. Scripts: `build` → `cap sync`.
3. Adicionar plataforma Android.
4. Declarar permissão `RECORD_AUDIO` e fluxo de runtime permission se necessário.
5. Documentar no README do projeto (ou `docs/tasks` note) como abrir no Android Studio / emulador.
6. Validar que Guided + Azure ainda funcionam no WebView (HTTPS/`capacitor` origin).

## Fora de escopo

- Publicação Play Store
- iOS (mentionar como follow-up se não houver Mac)
- Trocar UI

## Critérios de aceite

- [x] `npx cap sync` ok após `vite build`
- [x] App Android abre e pede/usa microfone
- [x] Fluxo Guided funcional em device/emulador **ou** bloqueio documentado com causa

## Arquivos esperados

- `capacitor.config.ts`
- `android/` (gerado)
- `package.json` scripts
- Breve nota em `docs/tasks/m2/` ou README raiz
