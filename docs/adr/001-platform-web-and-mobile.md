# ADR-001 — Plataforma Web e Mobile (React + Vite + Capacitor)

| Campo | Valor |
|-------|-------|
| Status | Accepted |
| Data | 2026-09-24 |
| Decisores | Autor do projeto (MVP pessoal) |
| Relacionados | [PRD](../PRD.md), [ADR-002](002-azure-pronunciation-assessment.md), [RFC-001](../rfc/001-mvp-architecture.md) |

---

## Contexto

O mock **Vocalis AI** já existe como SPA React 18 + Vite 6 + TypeScript + Tailwind, com as quatro telas do MVP e serviços de áudio no browser.

O produto precisa rodar em:

1. **Web** (desktop e mobile browser)
2. **Mobile nativo** (Android prioritário; iOS quando houver ambiente de build)

Não há backend próprio no MVP. A avaliação de pronúncia será feita via **Azure Speech JS SDK** no cliente (ADR-002).

Precisamos de uma estratégia de plataforma que:

- Reaproveite o UI já construído.
- Entregue acesso confiável ao microfone no dispositivo.
- Minimize reescrita e tempo até o primeiro treino real no celular.

## Decisão

Adotar **um único codebase React + Vite**, publicado como:

| Alvo | Empacotamento |
|------|----------------|
| Web | Build estático Vite (`dist/`), servido em HTTPS |
| Android / iOS | **Capacitor** embutindo o mesmo `dist/` em WebView nativo |

Stack confirmada:

- Frontend: React + TypeScript + Tailwind (já no repo `vocalis-ai`)
- Shell mobile: `@capacitor/core`, `@capacitor/cli`, plataformas `android` / `ios`
- Permissões de mic: plugins Capacitor / configuração nativa (`AndroidManifest`, `Info.plist`)
- Speech: Azure Speech SDK para JavaScript no mesmo bundle (web e WebView)

## Alternativas consideradas

### A) Reescrever em React Native / Expo

- **Prós:** UX nativa; ecossistema mobile maduro.
- **Contras:** Reescreve praticamente todo o mock; Azure Speech exige bridges nativos ou HTTP; custo alto para MVP pessoal.
- **Rejeitada** neste momento.

### B) Flutter (Dart)

- **Prós:** Um código para mobile; bom desempenho.
- **Contras:** Descarta o investimento React atual; curva e duplicação de UI.
- **Rejeitada.**

### C) PWA apenas (sem Capacitor)

- **Prós:** Zero shell nativo; installability no Android.
- **Contras:** Limitações de mic/background, descoberta fraca no iOS, menos controle de permissões; não atende bem o requisito “app mobile”.
- **Rejeitada como solução única**; PWA pode coexistir depois como bônus da build web.

### D) Dois frontends (web React + app nativo separado)

- **Prós:** Otimização por plataforma.
- **Contras:** Duplicação de features e bugs; inviável para um mantenedor solo no MVP.
- **Rejeitada.**

## Consequências

### Positivas

- 100% das telas do mock (`Dashboard`, `Guided`, `Feedback`, `FreeSpeaking`) seguem válidas.
- Um fluxo de Feature → Web e mobile ao mesmo tempo.
- Azure Speech JS SDK funciona no browser e, com permissões corretas, no WebView Capacitor.
- Builds Android de debug são suficientes no M2; stores ficam para depois.

### Negativas / trade-offs

- Performance e gestos ficam limitados ao WebView (aceitável para este produto).
- É preciso cuidar de **origem segura** (HTTPS ou `capacitor://`) para `getUserMedia` / Speech SDK.
- Plugins e configs nativas (mic, rede cleartext se necessário em dev) aumentam um pouco a superfície de build.
- iOS exige Mac + Xcode para builds reais.

### Implicações de implementação (não neste entregável de docs)

1. `npm create` / `npx cap init` apontando `webDir` para `dist`.
2. Script de pipeline: `vite build` → `cap sync`.
3. Declarar permissão `RECORD_AUDIO` (Android) e `NSMicrophoneUsageDescription` (iOS).
4. Testar Guided end-to-end no emulador/dispositivo antes de considerar M2 fechado.
5. Preferências locais: `localStorage` na web; avaliar `@capacitor/preferences` para paridade mobile se o WebView limpar storage.

## Conformidade com o PRD

- Atende RF-13 (web + Capacitor Android/iOS).
- Mantém mobile-first do mock (max-width ~ `md`).
- Alinha com escopo 1A: sem backend, sem contas.

## Notas

Publicação nas lojas **não** é critério de aceite do MVP. Critério é: build local/sideload Android com Guided + Feedback usáveis.
