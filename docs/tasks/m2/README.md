# Marco M2 — Capacitor Android

Este documento descreve como compilar, sincronizar e executar o Vocalis AI em dispositivos Android ou emuladores via Capacitor.

## Requisitos

- **Node.js**: v18+ (recomendado v20+)
- **Android Studio**: com Android SDK (API 34+ recomendada) e Command-line Tools instalados.
- **Java**: OpenJDK 17 ou 21 configurado no ambiente (`JAVA_HOME`).
- **Variáveis de Ambiente**: `.env` configurado na raiz com `VITE_AZURE_SPEECH_KEY` e `VITE_AZURE_SPEECH_REGION` antes de gerar a build web.

## Como compilar e sincronizar

1. Gere o build de produção do Vite e sincronize os assets nativos do Android:
   ```bash
   npm run build:android
   ```
   *(Ou execute separadamente `npm run build` seguido de `npx cap sync android`)*

2. Para abrir o projeto diretamente no Android Studio:
   ```bash
   npm run cap:open:android
   # ou
   npx cap open android
   ```
   *(Ou abra a pasta `/android` manualmente no Android Studio)*

## Execução no Emulador ou Dispositivo

1. No Android Studio, aguarde a sincronização do Gradle terminar.
2. Selecione o dispositivo físico (com Depuração USB ativada) ou um Virtual Device (AVD).
3. Clique em **Run 'app'** (Shift + F10).

## Permissão de Microfone e WebView

- **Permissão nativa**: Declarada em `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
  ```
- **Fluxo no app**: Ao tocar no microfone pela primeira vez (modo Guided ou Treinar Frase), o Capacitor intercepta a chamada de `navigator.mediaDevices.getUserMedia` via WebView (`WebChromeClient`) e exibe o diálogo nativo do sistema operacional Android solicitando autorização para gravar áudio.
- **Origem Segura**: O `capacitor.config.ts` utiliza `server: { androidScheme: 'https' }`, garantindo o contexto seguro (`https://localhost`) exigido pela Web Audio API / `getUserMedia`.
