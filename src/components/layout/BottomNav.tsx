import React from 'react';
import { ScreenMode } from '../../types';

interface BottomNavProps {
  currentMode: ScreenMode;
  onSelectMode: (mode: ScreenMode) => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ currentMode, onSelectMode }) => {
  return (
    <nav className="fixed bottom-0 inset-x-0 z-40 bg-surface/90 backdrop-blur-xl border-t border-surface-container-high/80">
      <div className="max-w-md mx-auto px-4 h-16 flex items-center justify-around">
        
        {/* Dashboard */}
        <button
          onClick={() => onSelectMode('dashboard')}
          className={`flex flex-col items-center justify-center w-16 py-1 transition-all rounded-xl ${
            currentMode === 'dashboard'
              ? 'text-primary font-bold'
              : 'text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <span
            className="material-symbols-outlined text-[24px]"
            style={{ fontVariationSettings: currentMode === 'dashboard' ? "'FILL' 1" : "'FILL' 0" }}
          >
            grid_view
          </span>
          <span className="text-[11px] font-medium tracking-tight mt-0.5">Painel</span>
        </button>

        {/* Guided Practice */}
        <button
          onClick={() => onSelectMode('guided')}
          className={`flex flex-col items-center justify-center w-16 py-1 transition-all rounded-xl relative ${
            currentMode === 'guided' || currentMode === 'feedback'
              ? 'text-primary font-bold'
              : 'text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <div className="relative">
            <span
              className="material-symbols-outlined text-[24px]"
              style={{
                fontVariationSettings:
                  currentMode === 'guided' || currentMode === 'feedback'
                    ? "'FILL' 1"
                    : "'FILL' 0",
              }}
            >
              record_voice_over
            </span>
            <span className="absolute -top-0.5 -right-0.5 w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          </div>
          <span className="text-[11px] font-medium tracking-tight mt-0.5">Treinar</span>
        </button>

        {/* Minhas Frases */}
        <button
          onClick={() => onSelectMode('custom-phrase')}
          className={`flex flex-col items-center justify-center w-16 py-1 transition-all rounded-xl ${
            currentMode === 'custom-phrase'
              ? 'text-primary font-bold'
              : 'text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <span
            className="material-symbols-outlined text-[24px]"
            style={{ fontVariationSettings: currentMode === 'custom-phrase' ? "'FILL' 1" : "'FILL' 0" }}
          >
            edit_note
          </span>
          <span className="text-[11px] font-medium tracking-tight mt-0.5">Minhas Frases</span>
        </button>

        {/* Free Speaking */}
        <button
          onClick={() => onSelectMode('free-speaking')}
          className={`flex flex-col items-center justify-center w-16 py-1 transition-all rounded-xl ${
            currentMode === 'free-speaking'
              ? 'text-primary font-bold'
              : 'text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <span
            className="material-symbols-outlined text-[24px]"
            style={{ fontVariationSettings: currentMode === 'free-speaking' ? "'FILL' 1" : "'FILL' 0" }}
          >
            forum
          </span>
          <span className="text-[11px] font-medium tracking-tight mt-0.5">Diálogo</span>
        </button>

      </div>
    </nav>
  );
};
