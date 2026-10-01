# PRD — Vocalis AI

| Campo | Valor |
|-------|-------|
| Produto | Vocalis AI |
| Versão do documento | 1.0 |
| Status | Draft aprovado para implementação |
| Data | 2026-09-24 |
| Escopo | MVP pessoal (Web + mobile), sem conta e sem backend próprio |
| Relacionados | [ADR-001](adr/001-platform-web-and-mobile.md), [ADR-002](adr/002-azure-pronunciation-assessment.md), [RFC-001](rfc/001-mvp-architecture.md) |

---

## 1. Visão

**Vocalis AI** é um aplicativo de treino de pronúncia em inglês que permite falar frases (ou dialogar) e receber feedback confiável palavra a palavra, com scores de precisão, fluência e completude.

O usuário fala; a IA avalia o que foi dito e indica o que acertar da próxima vez — sem precisar de professor ao vivo.

## 2. Problema

Quem estuda inglês sozinho:

- Não sabe se a pronúncia está compreensível.
- Apps genéricos de idioma dão pouco feedback fonético.
- Gravar e “achar que está certo” não fecha o ciclo de aprendizado.

Há duas necessidades distintas no mesmo produto:

1. **Repetir uma frase alvo** e saber exatamente quais palavras/fonemas falharam.
2. **Falar espontaneamente** em um cenário (ex.: café) e receber correções leves + continuidade de diálogo.

## 3. Persona e contexto de uso

| Aspecto | Descrição |
|---------|-----------|
| Persona | Aprendiz adulto de inglês (uso pessoal do autor) |
| Frequência | Sessões diárias curtas (meta: 20 frases/dia) |
| Ambiente | Casa / transporte; fone ou microfone do dispositivo |
| Dispositivos | Browser desktop/mobile e apps Android/iOS (via Capacitor) |
| Idioma da UI | Português (Brasil) |
| Idioma do treino | Inglês (ênfase US no MVP; UK preparado nos dados) |

## 4. Objetivos do MVP

### 4.1 Em escopo (Must)

1. **Modo Repetição Guiada (core)**  
   Exibir frase + IPA + áudio de referência → gravar → avaliar com **Azure Speech Pronunciation Assessment** → feedback color-coded por palavra → tentar de novo / próxima frase.

2. **Dashboard**  
   Ofensiva (streak), progresso diário, atalho para treino e card de revisão de dificuldades (fonemas/palavras com pior histórico local).

3. **Persistência local**  
   Streak, contagem do dia, média de score e histórico de erros em `localStorage` / Preferences do Capacitor — sem conta.

4. **Web e mobile**  
   Mesmo app React; mobile via encapsulamento Capacitor (ver ADR-001).

5. **Permissão de microfone** tratada com mensagens claras em web e nativo.

6. **Treinar frase livre (frase própria)**  
   O usuário digita (ou cola) a frase em inglês que quer treinar → ouve TTS de referência → grava → recebe o mesmo FeedbackModal via Azure PA. IPA/tips detalhados do catálogo são opcionais (genéricos ou omitidos se a palavra não estiver no dicionário local). Frases recentes ficam salvas localmente para repetir.

### 4.2 Em escopo leve (Should / v1.1 próximo)

**Modo Conversação Livre** com:

- Tópico fixo (ex.: café em Manhattan).
- STT (Azure ou Web Speech) para capturar a fala.
- Respostas da parceira “Emma” por script ramificado ou templates (não LLM completo no hard-MVP).
- Sugestões de naturalidade abaixo das mensagens do usuário.

### 4.3 Fora de escopo (Won’t no MVP)

- Contas, login, sync em nuvem, multi-dispositivo autenticado.
- Backend próprio / API Vocalis.
- Social, ranking público, gamificação avançada.
- Avaliação fonética via Levenshtein como fonte de verdade (fica só como fallback de emergência, se documentado no RFC).
- LLM completo no diálogo livre (Gemini/Claude) — pós-MVP.
- Publicação obrigatória nas stores no M0–M1 (builds locais/sideload primeiro).

## 5. Experiência e telas

As quatro superfícies do mock (`src/`) permanecem como contrato de UX; o fluxo de **frase própria** é adição ao MVP.

### 5.1 Dashboard (`DashboardScreen`)

- Saudação e “Painel de Voz”.
- Card de ofensiva + meta 20 frases + precisão média + minutos.
- Card destacado **Repetição Guiada** com frase sugerida.
- Card / atalho **Treinar minha frase** (abre entrada de frase própria).
- Card **Diálogo Livre com Emma** + tópico do dia.
- Card **Revisão de Dificuldades** (fonema/palavra focada).

### 5.2 Repetição Guiada (`GuidedScreen`)

- Progresso N/M, dificuldade, pular (modo catálogo).
- Frase grande, IPA (se houver), dica, ouvir referência (velocidade 1x / 0.75x).
- Waveform durante gravação.
- Transcrição ao vivo (quando disponível).
- Estado “Analisando…”.
- Botão central de microfone (iniciar/parar).

### 5.3 Frase livre (entrada + treino)

Fluxo novo reutilizando Guided/Feedback:

1. Campo de texto: usuário digita/cola a frase em inglês (limite razoável, ex.: 200 caracteres).
2. Validação básica: não vazio; preferencialmente caracteres latinos e pontuação comum.
3. Ação “Treinar esta frase” monta um `Exercise` ad-hoc (`id` local, `category: 'Frase própria'`, IPA/tip opcionais).
4. Segue o mesmo caminho: gravar → Azure → FeedbackModal.
5. No feedback: “Tentar novamente” reusa a mesma frase; ação secundária volta ao editor (“Nova frase”) ou ao dashboard — não avança o catálogo.
6. Lista curta de “Frases recentes” (persistida local) para retomar.

### 5.4 Feedback (`FeedbackModal`)

- Score geral + precisão / fluência / completude (e prosody se Azure retornar).
- Palavras verde / amarelo / vermelho (toque para detalhe).
- IPA + tip + “você disse X” + ouvir palavra isolada (tips genéricos se a palavra não estiver no `ipaDictionary`).
- Ações: Tentar novamente / Próxima frase (ou “Nova frase” no modo frase livre).

### 5.5 Conversação Livre (`FreeSpeakingScreen`)

- Header Emma + cenário.
- Timeline de balões (IA e usuário) com TTS nas falas da IA.
- Sugestões sob as mensagens.
- Barra inferior com microfone.

## 6. Requisitos funcionais

| ID | Requisito | Prioridade | Tela |
|----|-----------|------------|------|
| RF-01 | Listar e navegar exercícios guiados (frase, IPA, tip, dificuldade, categoria) | Must | Guided |
| RF-02 | Reproduzir áudio de referência da frase (TTS) com controle de velocidade | Must | Guided |
| RF-03 | Capturar áudio do microfone com feedback visual (waveform) | Must | Guided |
| RF-04 | Enviar áudio + texto de referência ao Azure Pronunciation Assessment | Must | Guided |
| RF-05 | Exibir score overall e submétricas accuracy / fluency / completeness | Must | Feedback |
| RF-06 | Destacar cada palavra por status (mastered / near / needs_work) | Must | Feedback |
| RF-07 | Ao selecionar palavra, mostrar IPA, tip, palavra detectada e ouvir isolada | Must | Feedback |
| RF-08 | Permitir retry da mesma frase e avançar para a próxima | Must | Feedback |
| RF-09 | Atualizar frases do dia, streak e média de acurácia após avaliação | Must | Dashboard |
| RF-10 | Persistir estatísticas e erros localmente entre sessões | Must | App |
| RF-11 | Card de revisão apontando fonema/palavra com pior desempenho recente | Should | Dashboard |
| RF-12 | Modo free-speaking: gravar, transcrever, exibir no chat e responder (script) | Should | Free |
| RF-13 | Funcionar em browser e em build Capacitor Android/iOS | Must | Plataforma |
| RF-14 | Tratar falha de mic / rede / Azure com mensagem acionável | Must | Guided |
| RF-15 | Permitir digitar/colar frase própria em inglês e treinar com o mesmo pipeline Azure + Feedback | Must | Frase livre |
| RF-16 | Persistir lista curta de frases próprias recentes e permitir retomar | Should | Frase livre / Dashboard |
| RF-17 | No modo frase livre, feedback oferece “Nova frase” (voltar ao editor) em vez de avançar o catálogo | Must | Feedback |

## 7. Requisitos não-funcionais

| ID | Requisito | Meta |
|----|-----------|------|
| RNF-01 | Latência percepível do feedback após parar a gravação | ≤ 3 s em rede normal (p95) |
| RNF-02 | UI responsiva mobile-first (viewport ~360–430 px) | Paridade com mock atual |
| RNF-03 | Offline | UI + catálogo de exercícios disponíveis; avaliação exige rede |
| RNF-04 | Segredo Azure | Via `.env` / variáveis de build; nunca commitado |
| RNF-05 | Acessibilidade básica | Contraste dos badges; botões com área de toque ≥ 44 px |
| RNF-06 | Privacidade | Áudio enviado só à Azure Speech; sem servidor Vocalis no MVP |

## 8. Métricas de sucesso (MVP pessoal)

| Métrica | Critério de sucesso |
|---------|---------------------|
| Uso diário | Completar meta de 20 frases em ≥ 4 dias na primeira semana de uso real |
| Qualidade do score | Correlação percebida: erros claros de TH / vogais caem em `needs_work` de forma consistente |
| Estabilidade | ≤ 5% de falhas de sessão (mic/Azure) em uso diário |
| Mobile | Guided + Feedback usáveis em Android (build Capacitor) sem regressão crítica vs web |

## 9. Inventário do mock atual

### Aproveitar (UI e fluxo)

- Telas e navegação em `src/App.tsx` + componentes em `src/components/`.
- Tipos em `src/types/index.ts` (`Exercise`, `PronunciationResult`, `WordEvaluation`, `UserStats`).
- Catálogo inicial e dicas IPA em `src/data/exercises.ts`.
- `audioService.ts` (captura + analyser para waveform).
- `WaveformVisualizer`, layout Header/BottomNav, design tokens Tailwind.

### Substituir / evoluir

| Atual | Destino MVP |
|-------|-------------|
| `pronunciationScorer.ts` (Levenshtein) | Adapter Azure → `PronunciationResult` (ADR-002) |
| Web Speech Recognition como score | Azure PA; STT nativo só para preview ao vivo opcional |
| Stats em memória / hardcoded (“Carlos”) | Persistência local + nome configurável opcional |
| Free speaking com replies fixas + fallback de texto fake | Script ramificado + STT real; sem inventar frase se mic falhar |
| TTS só Web Speech | Manter no curto prazo; Azure Neural TTS como upgrade |
| Só catálogo fixo de frases | + entrada de frase própria (Exercise ad-hoc) + recentes locais |

## 10. Roadmap

| Marco | Entrega | Notas |
|-------|---------|-------|
| **M0** | Documentação (este PRD, ADRs, RFC) | Feito neste entregável |
| **M1** | Integração Azure no Guided + Feedback **e** Treinar frase livre | Substitui scorer heurístico; `.env` local; editor de frase própria no mesmo pipeline |
| **M2** | Capacitor Android (e iOS se disponível) | Mic permissions, build de debug |
| **M3** | Persistência local de streak/erros + card de revisão real + frases recentes | Fecha o loop de repetição espaçada simples |
| **M4** | Free speaking v1.1 (scripts + STT estável) | LLM fica para pós-MVP |

## 11. Dependências e riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Custo Azure por minuto de áudio | Médio | Conta free tier / cotas; gravações curtas; monitorar usage |
| Chave no cliente | Alto se o app for público | MVP pessoal only; rotacionar chave; no futuro proxy |
| Web Speech inconsistente entre browsers | Médio | Não usar para score final; só preview |
| Capacitor + mic no WebView | Médio | Validar cedo no M2; plugins oficiais de permissão |
| Qualidade TTS do navegador | Baixo | Upgrade para Azure Neural TTS depois |

## 12. Critérios de aceite do MVP (definição de pronto)

1. Em Guided, após falar uma frase do catálogo, o FeedbackModal mostra scores vindos do Azure (não Levenshtein).
2. Palavras com baixo AccuracyScore Azure aparecem em vermelho/amarelo de forma alinhada ao retorno da API.
3. Retry e próxima frase funcionam sem perder o estado de progresso do dia (persistido).
4. App abre no browser e em build Android Capacitor com microfone funcional.
5. Free speaking (mesmo que scriptado) não bloqueia o lançamento do core Guided.
6. Usuário consegue digitar uma frase própria, ouvir referência, gravar e receber feedback Azure; “Nova frase” volta ao editor.

## 13. Glossário

| Termo | Significado |
|-------|-------------|
| PA | Pronunciation Assessment (Azure) |
| IPA | Alfabeto Fonético Internacional |
| Shadowing | Ouvir e repetir imediatamente a fala nativa |
| STT / TTS | Speech-to-Text / Text-to-Speech |
| Capacitor | Runtime que embute o web app em shell nativo |
