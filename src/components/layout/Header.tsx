import React from 'react';
import { UserStats } from '../../types';

interface HeaderProps {
  stats: UserStats;
  currentTitle?: string;
  onProfileClick?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ stats, currentTitle = 'Início', onProfileClick }) => {
  return (
    <header className="sticky top-0 inset-x-0 z-40 bg-surface/85 backdrop-blur-xl border-b border-surface-container-high/60 shadow-sm">
      <div className="max-w-md mx-auto px-4 h-16 flex items-center justify-between">
        
        {/* Logo & Title */}
        <div className="flex items-center gap-2.5 min-w-0">
          <img
            src="/logo.svg"
            alt="Vocalis AI Logo"
            className="h-8 w-8 object-contain shrink-0 drop-shadow-sm"
          />
          <div className="flex flex-col min-w-0">
            <span className="font-headline font-bold text-sm text-on-surface tracking-tight truncate">
              Vocalis AI
            </span>
            <span className="font-mono text-[11px] text-on-surface-variant truncate">
              {currentTitle}
            </span>
          </div>
        </div>

        {/* Streak & Profile */}
        <div className="flex items-center gap-2.5 shrink-0">
          {/* Streak pill */}
          <div className="flex items-center gap-1.5 bg-surface-container px-3 py-1 rounded-full shadow-sm border border-surface-container-high/80">
            <span className="text-sm leading-none">🔥</span>
            <span className="font-mono text-xs text-tertiary font-bold">
              {stats.streakDays} dias
            </span>
          </div>

          {/* Profile Avatar Button */}
          <button
            onClick={onProfileClick}
            className="relative p-0.5 rounded-full ring-2 ring-primary/20 hover:ring-primary/50 transition-all flex items-center justify-center overflow-hidden"
            title="Perfil do Estudante"
          >
            <img
              src="/avatar.jpg"
              alt="Carlos Avatar"
              className="w-8 h-8 rounded-full object-cover"
              onError={(e) => {
                // Fallback to initials if image doesn't load
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
          </button>
        </div>

      </div>
    </header>
  );
};
