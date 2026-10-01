class AudioService {
  private audioCtx: AudioContext | null = null;
  private analyser: AnalyserNode | null = null;
  private mediaStream: MediaStream | null = null;
  private mediaRecorder: MediaRecorder | null = null;
  private audioChunks: Blob[] = [];
  private animationFrameId: number | null = null;

  async startRecording(onVolumeChange?: (volume: number) => void): Promise<boolean> {
    try {
      this.mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.audioCtx = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
      
      const source = this.audioCtx.createMediaStreamSource(this.mediaStream);
      this.analyser = this.audioCtx.createAnalyser();
      this.analyser.fftSize = 64;
      source.connect(this.analyser);

      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(this.mediaStream);
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data);
        }
      };
      this.mediaRecorder.start(100);

      if (onVolumeChange) {
        const dataArray = new Uint8Array(this.analyser.frequencyBinCount);
        const update = () => {
          if (!this.analyser) return;
          this.analyser.getByteFrequencyData(dataArray);
          let sum = 0;
          for (let i = 0; i < dataArray.length; i++) {
            sum += dataArray[i];
          }
          const avg = sum / dataArray.length;
          onVolumeChange(Math.min(1, avg / 128));
          this.animationFrameId = requestAnimationFrame(update);
        };
        update();
      }

      return true;
    } catch (err) {
      console.error('Error accessing microphone:', err);
      return false;
    }
  }

  getFrequencyData(targetArray: Uint8Array): void {
    if (this.analyser) {
      this.analyser.getByteFrequencyData(targetArray as any);
    }
  }

  getAnalyser(): AnalyserNode | null {
    return this.analyser;
  }

  async stopRecording(): Promise<Blob | null> {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }

    return new Promise((resolve) => {
      if (!this.mediaRecorder || this.mediaRecorder.state === 'inactive') {
        this.cleanup();
        resolve(null);
        return;
      }

      this.mediaRecorder.onstop = () => {
        const mimeType = this.mediaRecorder?.mimeType || 'audio/webm';
        const blob = new Blob(this.audioChunks, { type: mimeType });
        this.cleanup();
        resolve(blob);
      };

      this.mediaRecorder.stop();
    });
  }

  private cleanup(): void {
    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach((track) => track.stop());
      this.mediaStream = null;
    }
    if (this.audioCtx && this.audioCtx.state !== 'closed') {
      this.audioCtx.close();
      this.audioCtx = null;
    }
    this.analyser = null;
    this.mediaRecorder = null;
  }
}

export const audioService = new AudioService();
