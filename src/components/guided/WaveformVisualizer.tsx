import React, { useEffect, useRef } from 'react';
import { audioService } from '../../services/audioService';

interface WaveformVisualizerProps {
  isRecording: boolean;
  accentColor?: string;
  barCount?: number;
}

export const WaveformVisualizer: React.FC<WaveformVisualizerProps> = ({
  isRecording,
  accentColor = '#4648d4',
  barCount = 36,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animId: number;
    const dataArray = new Uint8Array(32);

    // Static target wave pattern (representing native target model)
    const targetHeights = [
      0.15, 0.25, 0.45, 0.7, 0.85, 0.95, 0.8, 0.6, 0.4, 0.5, 0.75, 0.9, 1.0, 0.85, 0.65, 0.4,
      0.3, 0.45, 0.65, 0.85, 0.9, 0.75, 0.6, 0.4, 0.55, 0.7, 0.85, 0.65, 0.45, 0.3, 0.2, 0.15,
      0.25, 0.35, 0.2, 0.1
    ];

    const render = () => {
      const width = canvas.width;
      const height = canvas.height;
      ctx.clearRect(0, 0, width, height);

      const analyser = audioService.getAnalyser();
      if (analyser && isRecording) {
        audioService.getFrequencyData(dataArray);
      }

      const totalBars = barCount;
      const barWidth = 3;
      const gap = 2;
      const totalWidth = totalBars * (barWidth + gap) - gap;
      const startX = (width - totalWidth) / 2;

      for (let i = 0; i < totalBars; i++) {
        const x = startX + i * (barWidth + gap);
        
        // Target Ghost Track (Background)
        const targetH = (targetHeights[i % targetHeights.length] || 0.3) * (height * 0.7);
        const targetY = (height - targetH) / 2;

        ctx.fillStyle = '#cbd5e1'; // Muted reference model track
        ctx.beginPath();
        ctx.roundRect(x, targetY, barWidth, targetH, 999);
        ctx.fill();

        // Live Learner Track (Overlay)
        if (isRecording) {
          const freqVal = dataArray[i % dataArray.length] || 0;
          const liveScale = Math.max(0.12, freqVal / 255);
          const liveH = liveScale * height * 0.95;
          const liveY = (height - liveH) / 2;

          ctx.fillStyle = accentColor;
          ctx.beginPath();
          ctx.roundRect(x, liveY, barWidth, liveH, 999);
          ctx.fill();
        }
      }

      animId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animId);
    };
  }, [isRecording, accentColor, barCount]);

  return (
    <div className="w-full bg-surface-container-lowest border border-surface-container-high rounded-2xl p-4 shadow-sm flex flex-col items-center justify-center">
      <div className="flex items-center justify-between w-full mb-2 px-1 text-[11px] font-mono text-on-surface-variant">
        <span className="flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full bg-slate-300"></span>
          Referência Nativa
        </span>
        <span className="flex items-center gap-1.5">
          <span className={`w-2 h-2 rounded-full ${isRecording ? 'bg-primary animate-ping' : 'bg-slate-400'}`}></span>
          {isRecording ? 'Captando sua voz' : 'Aguardando gravação'}
        </span>
      </div>

      <canvas
        ref={canvasRef}
        width={340}
        height={72}
        className="w-full h-18 rounded-lg"
      />
    </div>
  );
};
