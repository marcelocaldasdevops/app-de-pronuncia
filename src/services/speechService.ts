// Speech recognition declaration for TypeScript
interface IWindow extends Window {
  SpeechRecognition?: any;
  webkitSpeechRecognition?: any;
}

class SpeechService {
  private recognition: any = null;

  speak(text: string, rate: number = 1.0, lang: string = 'en-US'): Promise<void> {
    return new Promise((resolve) => {
      if (!('speechSynthesis' in window)) {
        console.warn('Speech synthesis not supported in this browser.');
        resolve();
        return;
      }

      window.speechSynthesis.cancel();

      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = lang;
      utterance.rate = rate;
      utterance.pitch = 1.0;

      // Select natural sounding voice if available
      const voices = window.speechSynthesis.getVoices();
      const preferredVoice = voices.find(
        (v) => v.lang.startsWith(lang.split('-')[0]) && (v.name.includes('Natural') || v.name.includes('Google') || v.name.includes('Samantha') || v.name.includes('Daniel'))
      ) || voices.find((v) => v.lang.includes('en'));

      if (preferredVoice) {
        utterance.voice = preferredVoice;
      }

      utterance.onend = () => {
        resolve();
      };

      utterance.onerror = () => {
        resolve();
      };

      window.speechSynthesis.speak(utterance);
    });
  }

  stopSpeech(): void {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
  }

  isRecognitionSupported(): boolean {
    const win = window as unknown as IWindow;
    return !!(win.SpeechRecognition || win.webkitSpeechRecognition);
  }

  startRecognition(
    onResult: (transcript: string, isFinal: boolean) => void,
    onError: (error: string) => void,
    onEnd: () => void
  ): boolean {
    const win = window as unknown as IWindow;
    const SpeechRec = win.SpeechRecognition || win.webkitSpeechRecognition;

    if (!SpeechRec) {
      onError('O seu navegador não suporta a Web Speech Recognition API.');
      return false;
    }

    try {
      this.recognition = new SpeechRec();
      this.recognition.lang = 'en-US';
      this.recognition.continuous = true;
      this.recognition.interimResults = true;
      this.recognition.maxAlternatives = 3;

      this.recognition.onresult = (event: any) => {
        let finalTranscript = '';
        let interimTranscript = '';

        for (let i = event.resultIndex; i < event.results.length; ++i) {
          const trans = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            finalTranscript += trans;
          } else {
            interimTranscript += trans;
          }
        }

        const combined = finalTranscript || interimTranscript;
        onResult(combined.trim(), !!finalTranscript);
      };

      this.recognition.onerror = (event: any) => {
        console.warn('Speech recognition event error:', event.error);
        if (event.error !== 'no-speech') {
          onError(event.error);
        }
      };

      this.recognition.onend = () => {
        onEnd();
      };

      this.recognition.start();
      return true;
    } catch (err: any) {
      console.error('Failed to start speech recognition:', err);
      onError(err.message || 'Falha ao iniciar reconhecimento de fala');
      return false;
    }
  }

  stopRecognition(): void {
    if (this.recognition) {
      try {
        this.recognition.stop();
      } catch (e) {
        // ignore if already stopped
      }
      this.recognition = null;
    }
  }
}

export const speechService = new SpeechService();
