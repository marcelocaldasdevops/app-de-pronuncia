# ADR-002 — Azure Speech Pronunciation Assessment como motor de score

| Campo | Valor |
|-------|-------|
| Status | Accepted |
| Data | 2026-09-24 |
| Decisores | Autor do projeto (MVP pessoal) |
| Relacionados | [PRD](../PRD.md), [ADR-001](001-platform-web-and-mobile.md), [RFC-001](../rfc/001-mvp-architecture.md) |

---

## Contexto

O mock avalia pronúncia em `src/services/pronunciationScorer.ts` comparando a transcrição do **Web Speech API** com a frase alvo via **Levenshtein** palavra a palavra.

Isso gera um score “plausível” na UI, mas:

- Não mede fonemas de verdade (ex.: `/θ/` vs `/s/`).
- Depende da qualidade inconsistente do STT do navegador.
- Fluência/completude são derivadas heurísticas, não sinais acústicos.
- Há fallback perigoso no Guided: se o transcript vier vazio, o código usa a própria frase alvo (score artificialmente alto).

O PRD exige feedback confiável palavra a palavra. A ideação original (PDF) já apontava a **Azure Speech Pronunciation Assessment** como opção especializada.

## Decisão

Usar **Azure AI Speech — Pronunciation Assessment** como **única fonte de verdade** dos scores de:

- Overall / Accuracy
- Fluency
- Completeness
- Prosody (quando habilitado e retornado)
- Avaliação **por palavra** (e fonemas quando disponíveis na resposta)

O serviço cliente será encapsulado (ex.: `src/services/azureSpeech.ts`) e um **adapter** converterá a resposta Azure para o contrato já usado pela UI:

- `PronunciationResult`
- `WordEvaluation` (`mastered` | `near` | `needs_work`)

em `src/types/index.ts`.

### Configuração de avaliação (MVP)

| Parâmetro | Valor inicial |
|-----------|----------------|
| Idioma | `en-US` (exercícios UK usam `en-GB` quando `exercise.accent === 'UK'`) |
| Reference text | `exercise.sentence` (catálogo **ou** frase digitada pelo usuário no modo frase livre) |
| Grading system | HundredMark |
| Granularity | Phoneme (ou Word se Phoneme aumentar custo/latência demais — validar no M1) |
| Enable miscue | true |
| Enable prosody | true se disponível na região |

### TTS

- **Curto prazo:** manter `speechSynthesis` via `speechService.ts` (já integrado).
- **Upgrade documentado:** Azure Neural TTS para referência mais natural — não bloqueia M1.

### Conversação Livre

- STT: preferir Azure Speech Recognition; Web Speech permanece fallback de preview.
- Diálogo LLM **fora** do hard-MVP (scripts/templates).
- Pronunciation Assessment **não** é obrigatório em cada turno do free speaking no MVP (custo + UX); foco do PA é o modo Guided.

### Segredos

- `VITE_AZURE_SPEECH_KEY` e `VITE_AZURE_SPEECH_REGION` (ou nomes equivalentes) em `.env` local.
- `.env` no `.gitignore`; chave nunca commitada.
- Risco de chave no cliente é **aceitável apenas porque o MVP é pessoal**. Se o app for distribuído a terceiros, exigir proxy backend (pós-MVP).

## Alternativas consideradas

### A) Manter Web Speech + Levenshtein

- **Prós:** Zero custo cloud; já funciona no mock.
- **Contras:** Não resolve a dor real de feedback fonético.
- **Rejeitada** como motor principal (pode restar só como fallback offline explícito, desligado por padrão).

### B) Whisper (STT) + Gemini (julgamento)

- **Prós:** Flexível; bom para free speaking + dicas em PT.
- **Contras:** Score de pronúncia não é specialty; custo e latência variáveis; mais peças.
- **Adiada** para pós-MVP (diálogo inteligente), não para o score Guided.

### C) Somente Web Speech Recognition “accuracy”

- **Prós:** Simples.
- **Contras:** Não há pronunciation assessment padronizado no browser.
- **Rejeitada.**

## Mapeamento Azure → UI

| Campo UI (`PronunciationResult`) | Origem Azure (conceitual) |
|----------------------------------|---------------------------|
| `overallScore` | PronunciationScore / AccuracyScore (definir no adapter; preferir PronunciationScore se existir) |
| `accuracyScore` | AccuracyScore |
| `fluencyScore` | FluencyScore |
| `completenessScore` | CompletenessScore |
| `transcript` | DisplayText / Words reconhecidas |
| `words[].score` | Word.AccuracyScore |
| `words[].status` | Limiares: ≥85 `mastered`; ≥60 `near`; else `needs_work` (ajustáveis) |
| `words[].spokenWord` | Word.Word reconhecida / erro de omissão |
| `words[].ipa` / `tip` | Catálogo local `ipaDictionary` + tips do exercício (Azure não substitui as dicas pedagógicas em PT) |

Fonemas Azure (se retornados) podem enriquecer o tip no futuro; no MVP, tips em português do mock continuam suficientes.

## Consequências

### Positivas

- Feedback alinhado a um produto maduro de pronunciation assessment.
- Submétricas do FeedbackModal passam a ser significativas.
- Remove o incentivo a “hackear” o score com transcript vazio → frase alvo.

### Negativas / trade-offs

- Dependência de rede e de cotas Azure.
- Custo por uso (mitigar com frases curtas e sessão pessoal).
- Chave no cliente (restrito ao uso pessoal).
- Latência de round-trip; meta RNF-01 ≤ 3 s p95.

### O que acontece com o código atual

| Arquivo | Destino |
|---------|---------|
| `pronunciationScorer.ts` | Substituído por adapter Azure; Levenshtein removido do caminho feliz ou isolado como `fallbackScorer` desligado |
| `GuidedScreen.tsx` | Parar gravação → blob/PCM → Azure PA → `onFinishEvaluation` |
| `speechService.ts` | Continua TTS; STT opcional só para “O que a IA está ouvindo” |
| `audioService.ts` | Continua captura/waveform; formato de áudio alinhado ao que o SDK Azure espera |

## Conformidade com o PRD

- Atende RF-04, RF-05, RF-06 e critérios de aceite 1–2.
- Alinha decisão de produto **2B** (Azure PA).
