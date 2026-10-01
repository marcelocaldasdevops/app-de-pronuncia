# Documentação — Vocalis AI

Índice da documentação de produto e arquitetura do app de treino de pronúncia em inglês.

## Como ler

1. **Produto e escopo** → [PRD.md](PRD.md)
2. **Decisões arquiteturais** → ADRs abaixo
3. **Desenho técnico do MVP** → [rfc/001-mvp-architecture.md](rfc/001-mvp-architecture.md)

## Documentos

| Documento | Descrição |
|-----------|-----------|
| [PRD.md](PRD.md) | Visão, persona, RF/RNF, telas, inventário do mock, roadmap e critérios de aceite |
| [adr/001-platform-web-and-mobile.md](adr/001-platform-web-and-mobile.md) | React + Vite + Capacitor para Web e mobile |
| [adr/002-azure-pronunciation-assessment.md](adr/002-azure-pronunciation-assessment.md) | Azure Pronunciation Assessment como motor de score |
| [rfc/001-mvp-architecture.md](rfc/001-mvp-architecture.md) | Arquitetura, fluxos, contratos de dados, persistência e migração do mock |
| [tasks/README.md](tasks/README.md) | Backlog de tasks atômicas para agentes/modelos executarem |

## Decisões fixadas

| Tema | Escolha |
|------|---------|
| Escopo | MVP pessoal — sem login e sem backend próprio |
| Score | Azure Speech Pronunciation Assessment |
| Plataformas | Web + Android/iOS via Capacitor sobre o app React atual |
| Frases | Catálogo guiado **e** frase própria digitada pelo usuário (M1) |

## Estado do código vs docs

O repositório ainda contém o **mock/protótipo** (Web Speech + Levenshtein, stats em memória, free speaking scriptado). A implementação das decisões acima segue o roadmap do PRD (M1–M4), orientada pelo RFC-001.

## Fontes de ideação

- `Desenvolvimento de App de Pronúncia.pdf` (raiz do projeto)
- Mock em `src/`
- Referências visuais em `stitch/` e screenshots `app_*_live.png`
