# OpenSpec: Multiplatform Pronunciation Trainer (Flutter)
**Status:** PROPOSED  
**Version:** 1.0.0  
**Stack:** Flutter 3.24+ (Dart 3.5+)  
**Target Platforms:** Android, iOS, Web, Linux, Windows  
**Audio Backbone:** `audioplayers` (Federated Audio) + `record` (Federated Audio Recording)  
**Voice Engine:** Hybrid Neural Speech (Edge-TTS Online Gratuito + Piper/Sherpa-ONNX Local + Fallback Nativo `flutter_tts`)  

---

## 1. Contexto e Objetivos

### 1.1 Problema
Estudantes e profissionais precisam treinar a pronúncia e ritmo de frases específicas (vocabulário técnico, entrevistas de emprego, apresentações ou frases do cotidiano). As ferramentas existentes oferecem apenas currículos fixos ou exigem assinaturas pagas em APIs de voz para ter qualidade aceitável.

### 1.2 Proposta de Valor
Uma aplicação multiplataforma leve, de código aberto e com custo de infraestrutura zero para o usuário final, onde qualquer frase digitada pode ser:
1. Sintetizada em voz neural natural de alta fidelidade com controle de velocidade (1.0x e 0.75x).
2. Gravada pelo microfone com medição em tempo real.
3. Comparada detalhadamente (palavra por palavra, transcrição e score de similaridade).
4. Autoavaliada com reprodução alternada ("Áudio Modelo" vs. "Minha Gravação").

---

## 2. Arquitetura do Sistema

Inspirada no modelo federado e desacoplado do `audioplayers`, a aplicação adota uma Arquitetura em Camadas (Clean / Hexagonal) com separação estrita de responsabilidades:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Camada de Apresentação (UI)                     │
│  - InputScreen (Digitação e Validação de Frases)                       │
│  - TrainingScreen (Player de Referência + Gravador + Waveform)         │
│  - ComparisonScreen (Feedback Palavra a Palavra + Player Duplo)        │
│  - HistoryScreen (Frases Recentes e Estatísticas Locais)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Riverpod (State Management)
┌───────────────────────────────────▼────────────────────────────────────┐
│                       Camada de Domínio / Negócio                      │
│  - Entities: Phrase, AudioAttempt, ComparisonResult, PhonemeMap        │
│  - Use Cases:                                                          │
│      * SynthesizeReferenceAudioUseCase                                 │
│      * RecordUserSpeechUseCase                                         │
│      * EvaluatePronunciationUseCase                                    │
│      * AlignTextSequencesUseCase (Needleman-Wunsch / Levenshtein)      │
│      * ConvertGraphemeToPhonemeUseCase (IPA G2P)                       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Contratos / Portas (Interfaces)
┌───────────────────────────────────▼────────────────────────────────────┐
│                    Camada de Infraestrutura / Adaptadores              │
│                                                                        │
│  ┌──────────────────────┐ ┌──────────────────────┐ ┌────────────────┐  │
│  │ IAudioPlayerService  │ │ IAudioRecorderService│ │  ITTSService   │  │
│  └──────────┬───────────┘ └──────────┬───────────┘ └────────┬───────┘  │
│             │                        │                      │          │
│      [audioplayers]              [record]           [edge-tts / nativo]│
│  - Android: MediaPlayer    - Android: AudioRecord  - Edge-TTS Neural   │
│  - iOS: AVPlayer           - iOS: AVAudioRecorder  - Fallback: Local   │
│  - Web: Web Audio / HTML5  - Web: MediaRecorder      flutter_tts       │
│  - Linux: GStreamer        - Linux: Pulse/PipeWire                     │
│  - Windows: Media Found.   - Windows: WASAPI                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Especificação do Subsistema de Áudio e Voz

### 3.1 Motor de Saída (Playback) — `audioplayers`
- **Contrato Comum:** `AudioPlayerService` expõe controle de ciclo de vida (`play`, `pause`, `stop`, `seek`), controle de taxa de reprodução (`setSpeed`), stream de eventos (`positionStream`, `playerStateStream`, `completeStream`).
- **Fontes Suportadas:**
  - `DeviceFileSource`: Áudio gravado pelo usuário e arquivos de voz em cache.
  - `BytesSource`: Áudio gerado em memória pelo sintetizador sem necessidade de I/O em disco.
- **Modulação de Velocidade:** Suporte obrigatório a `0.75x` (escuta detalhada de pronúncia) e `1.0x` (velocidade nativa natural).

### 3.2 Motor de Voz (TTS) Gratuito e Avançado
A síntese de voz utiliza uma abordagem híbrida inteligente sem necessidade de APIs pagas:
1. **Primário (Online Neural de Alta Definição): `edge-tts` (Microsoft Neural Voices Protocol)**
   - Conexão direta via WebSocket pública com o serviço de síntese neural.
   - Vozes padrão: `en-US-JennyNeural` (Feminina, EUA), `en-US-GuyNeural` (Masculino, EUA), `en-GB-SoniaNeural` (Britânico).
   - Saída: Buffer de áudio MP3/WAV cristalino com prosódia e entonação natural humana.
2. **Secundário (Offline Fallback): `flutter_tts`**
   - Utiliza o sintetizador nativo do sistema operacional (Android TTS, iOS AVSpeech, Windows OneCore/SAPI, Linux Speech Dispatcher, Web SpeechSynthesis).
   - Garante que a aplicação funcione mesmo sem internet.

### 3.3 Motor de Captura (Recording) — `record`
- Captura de áudio do microfone em formato padronizado: **WAV PCM 16 kHz, 16-bit Mono** (padrão ideal para processamento de fala e alinhamento acústico).
- Emissão de stream de amplitude para desenhar o gráfico de ondas sonoras (Waveform) enquanto o usuário fala.
- **Gestão de Sessão (iOS & Android):** Configuração automática do `audio_session` para `AVAudioSessionCategoryPlayAndRecord` com `defaultToSpeaker` ativo para evitar corte de áudio e conflito entre microfone e alto-falante.

---

## 4. Mecanismo de Comparação e Feedback

### 4.1 Pipeline de Avaliação
1. **Entrada:** Frase original digitada $T_{ref}$ e áudio gravado pelo usuário $A_{user}$.
2. **Reconhecimento de Fala (STT Multiplataforma):** Transcrição do áudio gravado para texto $T_{user}$ via Speech-to-Text nativo do dispositivo (`speech_to_text`) ou motor offline gratuito.
3. **Alinhamento Lexical (Needleman-Wunsch / Levenshtein Token-Level):**
   - Mapeamento entre as palavras esperadas $[w_1, w_2, ..., w_n]$ e as palavras pronunciadas $[s_1, s_2, ..., s_m]$.
   - Classificação de cada palavra em 3 estados:
     - `mastered` (Verde): Correspondência exata de fonética e texto.
     - `near` (Amarelo): Palavra reconhecida com pequenas variações ou acentuação divergente.
     - `needs_work` (Vermelho): Palavra omitida, trocada ou inaudível.
4. **Guia Fonético IPA:**
   - Dicionário CMU / Algoritmo G2P (Grapheme-to-Phoneme) que gera a representação IPA (International Phonetic Alphabet) da frase digitada para orientar a posição da língua e lábios.
5. **Cálculo do Score Global:**
   $$\text{Score} = \left(\frac{\sum \text{peso}(w_i)}{\text{total de palavras}}\right) \times 100$$
   Com penalidades suaves para pausas excessivas ou palavras extras.

---

## 5. Requisitos do Sistema

### 5.1 Requisitos Funcionais (FR)
- **FR-01:** O usuário pode digitar qualquer frase na tela inicial ou escolher frases do histórico recente.
- **FR-02:** O sistema sintetiza a frase digitada em voz neural e permite ouvi-la instantaneamente.
- **FR-03:** O sistema permite alternar a velocidade do áudio modelo entre 0.75x e 1.0x.
- **FR-04:** O usuário pode iniciar, visualizar a onda de som e interromper a gravação de sua própria pronúncia.
- **FR-05:** O sistema transcreve e compara a fala do usuário com a frase digitada.
- **FR-06:** O sistema apresenta um score global (0% a 100%) e destaca cada palavra com cores indicativas (Verde, Amarelo, Vermelho).
- **FR-07:** O sistema exibe a transcrição fonética IPA de cada palavra e dicas de articulação para palavras difíceis.
- **FR-08:** A tela de resultado disponibiliza dois botões de áudio para autoavaliação: "Ouvir Modelo" e "Ouvir Minha Gravação".
- **FR-09:** O sistema armazena localmente o histórico das últimas 50 frases praticadas, scores e palavras com maior taxa de erro.

### 5.2 Requisitos Não Funcionais (NFR)
- **NFR-01 (Multiplataforma):** Código compartilhado único em Flutter compilando nativamente para Android, iOS, Web, Linux e Windows.
- **NFR-02 (Custo Zero de Infraestrutura):** Nenhuma dependência de APIs pagas com tarifação por caractere ou minuto de áudio.
- **NFR-03 (Latência):** O início da reprodução do áudio de referência deve ocorrer em menos de 800ms após o clique.
- **NFR-04 (Resiliência Offline):** Se o dispositivo estiver desconectado, o sistema alterna automaticamente para o sintetizador e STT locais do sistema operacional.
- **NFR-05 (Privacidade):** Nenhuma gravação de voz é retida em servidores externos; os áudios gravados são temporários e mantidos apenas na memória/armazenamento local do aparelho.

---

## 6. Matriz de Compatibilidade e Riscos por Plataforma

| Plataforma | Suporte a Playback (`audioplayers`) | Suporte a Gravação (`record`) | Suporte a TTS Avançado (Edge-TTS) | Riscos Específicos & Mitigações |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | `MediaPlayer` / `ExoPlayer` | `AudioRecord` (WAV) | WebSocket Client / Cache Local | **Risco:** Permissão de microfone em runtime. <br>**Mitigação:** Tratamento via `permission_handler` com prompt explicativo antes da gravação. |
| **iOS** | `AVPlayer` | `AVAudioRecorder` | WebSocket Client / Cache Local | **Risco:** Áudio abafado ou saindo no receptor do fone. <br>**Mitigação:** Ativar `AVAudioSessionCategoryPlayAndRecord` com `defaultToSpeaker`. |
| **Web** | Web Audio API / HTML5 | `MediaRecorder` API | WebSocket com fallback CORS | **Risco:** Políticas de autoplay do navegador e bloqueio de microfone. <br>**Mitigação:** Disparar o som exclusivamente via gesto de clique e validar permissão HTTPS. |
| **Linux** | GStreamer (`playbin`) | PulseAudio / PipeWire | WebSocket Client | **Risco:** Ausência de bibliotecas GStreamer em distros mínimas. <br>**Mitigação:** Documentar pacotes `libgstreamer1.0-dev` e gerar áudios em WAV puro. |
| **Windows** | Media Foundation | WASAPI | WebSocket Client | **Risco:** Permissões de privacidade de microfone no Windows 10/11. <br>**Mitigação:** Capturar exceção HRESULT de acesso negado e exibir atalho para as Configurações de Privacidade do Windows. |
