# Vocalis AI

---
name: Vocalis AI
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#464554'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#767586'
  outline-variant: '#c7c4d7'
  surface-tint: '#494bd6'
  primary: '#4648d4'
  on-primary: '#ffffff'
  primary-container: '#6063ee'
  on-primary-container: '#fffbff'
  inverse-primary: '#c0c1ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#825100'
  on-tertiary: '#ffffff'
  tertiary-container: '#a36700'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 21px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.875rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style
The design system embodies an energetic, scientifically grounded, and high-precision language training companion. It bridges academic acoustic phonetics with the gamified feedback loops modern learners expect. 

The aesthetic is clean, tactile, and highly legible, prioritizing clarity in audio-visual biofeedback. Built around a crisp, high-contrast light default mode with dark elevation surfaces for waveform recording sessions, the UI evokes confidence, precision, and encouraging progression. It pairs high-energy micro-interactions with calm, analytical breakdowns to reduce performance anxiety during speech evaluation.

## Colors
The color palette relies on an electric Indigo (`#6366F1`) as the primary brand engine for primary navigation, user milestones, and primary action controls. 

Semantic accuracy states are critical for immediate acoustic feedback:
- **Mastered / Correct Phoneme:** Emerald Green (`#10B981`) paired with soft emerald tint containers (`#ECFDF5`).
- **Accent Refinement / Near-Target:** Amber Gold (`#F59E0B`) with subtle gold highlights (`#FFFBEB`).
- **Phonemic Misalignment / Needs Attention:** Rose Red (`#EF4444`) with gentle coral backings (`#FEF2F2`).

Backgrounds leverage crisp, bright chalk-white (`#FFFFFF`) and warm canvas gray (`#F8FAFC`). Typography and structural borders utilize slate neutrals (`#0F172A` down to `#64748B`), preserving extreme legibility across phonetic notation and spectrogram overlays.

## Typography
Plus Jakarta Sans provides geometric balance, friendly terminals, and optimal legibility on compact displays. Its high x-height maintains reading speed during dynamic sentence reading exercises.

JetBrains Mono is used exclusively for functional phonetics: IPA (International Phonetic Alphabet) transcription strings, decibel meters, duration timestamps, and phoneme tracking tags. The fixed-width character footprint prevents interface jitter when comparing the user's audio track alongside native target models.

## Layout & Spacing
Built for touch-first handheld navigation:
- **Mobile Column Grid:** 4-column fluid layout with an edge margin of `1.25rem` (20px) to keep critical controls away from physical phone chassis borders.
- **Rhythm & Safe Areas:** Built strictly around a 4px sub-grid with primary jumps of 8px (`0.5rem`), 14px (`0.875rem`), and 20px (`1.25rem`). Bottom-anchored speech recording actions accommodate thumb-reach zones, keeping interactive buttons at a minimum 48px target box.
- **Dynamic Content Flow:** Training prompt cards stack vertically with standard `space-md` gaps. Segmented phonetic rows wrap dynamically to avoid truncation of IPA tokens.

## Elevation & Depth
Depth is maintained through soft, multi-layered ambient drop shadows paired with crisp micro-borders (`1px solid #E2E8F0`). 

- **Level 0 (Base Canvas):** Pristine background `#F8FAFC` without shadow.
- **Level 1 (Card & Module Layer):** `#FFFFFF` surfaces with `box-shadow: 0 2px 8px -2px rgba(15, 23, 42, 0.05), 0 1px 3px 0 rgba(15, 23, 42, 0.04)`.
- **Level 2 (Audio Playback & Bottom Sheets):** Elevated interactive trays featuring subtle indigo-tinted ambient diffusion: `box-shadow: 0 12px 32px -6px rgba(99, 102, 241, 0.12), 0 4px 12px -2px rgba(15, 23, 42, 0.06)`.
- **Live Mic State:** Dynamic pulse glow applied to primary input nodes using an inner and outer emerald/indigo chromatic aura (`box-shadow: 0 0 0 6px rgba(99, 102, 241, 0.2)`).

## Shapes
The system utilizes a pill-shaped and highly rounded morphology (`roundedness: 3`). 

Interactive buttons, status pills, and IPA chips take full stadium/pill radii (`9999px`) to create friendly, tactile tap affordances. Modular surfaces like lesson containers, waveform visualizer decks, and bottom sheets adopt balanced `rounded-lg` (2rem / 32px) and `rounded-xl` (3rem / 48px) top-caps, producing an approachable consumer-grade mobile feel.

## Components

### Action Buttons
- **Primary Speak/Record Action:** Giant stadium floating trigger (68px height) centered along the lower viewport. In resting state: solid `#6366F1` with white icon. In recording state: transitions to pulsating `#EF4444` with sound-wave micro-animation.
- **Secondary Action:** Ghost and filled-tonal variants (`#EEF2FF` text with `#4338CA`) for audio playback and tempo speed toggle buttons (`0.8x`, `1.0x`).

### Phonetic IPA Chips
- Interactive pill chips displaying syllable breakups (e.g., `/vəʊ/` • `/kæl/` • `/ɪs/`).
- Default: `#F1F5F9` background, `#334155` text.
- Mastered: `#ECFDF5` background, `#065F46` text, with a `#10B981` border stroke.
- Needs Work: `#FEF2F2` background, `#991B1B` text, with an inline underline stroke in `#EF4444`. Tapping any chip opens an articulation sheet showing tongue position cross-sections.

### Waveform Audio Visualizer
- Symmetric dual-track audio visualizer displaying real-time frequency heights. Native speech target rendered as a muted ghost track (`#CBD5E1`), overlaid with the live learner track in dynamic emerald or indigo bars. 
- Bar width: 3px; gap: 2px; corner radius: full.

### Assessment Bottom Sheets
- Fixed-elevation bottom sheet snapping to 45% or 85% viewport heights. Contains overall pronunciation score (0–100%), acoustic fluency gauge, and targeted actionable feedback tips. Top edges utilize a 32px corner radius accompanied by a centered 36px wide grab handle (`#CBD5E1`).

## Brand & Style
The design system embodies an energetic, scientifically grounded, and high-precision language training companion. It bridges academic acoustic phonetics with the gamified feedback loops modern learners expect. 

The aesthetic is clean, tactile, and highly legible, prioritizing clarity in audio-visual biofeedback. Built around a crisp, high-contrast light default mode with dark elevation surfaces for waveform recording sessions, the UI evokes confidence, precision, and encouraging progression. It pairs high-energy micro-interactions with calm, analytical breakdowns to reduce performance anxiety during speech evaluation.

## Layout & Spacing
Built for touch-first handheld navigation:
- **Mobile Column Grid:** 4-column fluid layout with an edge margin of `1.25rem` (20px) to keep critical controls away from physical phone chassis borders.
- **Rhythm & Safe Areas:** Built strictly around a 4px sub-grid with primary jumps of 8px (`0.5rem`), 14px (`0.875rem`), and 20px (`1.25rem`). Bottom-anchored speech recording actions accommodate thumb-reach zones, keeping interactive buttons at a minimum 48px target box.
- **Dynamic Content Flow:** Training prompt cards stack vertically with standard `space-md` gaps. Segmented phonetic rows wrap dynamically to avoid truncation of IPA tokens.

## Elevation & Depth
Depth is maintained through soft, multi-layered ambient drop shadows paired with crisp micro-borders (`1px solid #E2E8F0`). 

- **Level 0 (Base Canvas):** Pristine background `#F8FAFC` without shadow.
- **Level 1 (Card & Module Layer):** `#FFFFFF` surfaces with `box-shadow: 0 2px 8px -2px rgba(15, 23, 42, 0.05), 0 1px 3px 0 rgba(15, 23, 42, 0.04)`.
- **Level 2 (Audio Playback & Bottom Sheets):** Elevated interactive trays featuring subtle indigo-tinted ambient diffusion: `box-shadow: 0 12px 32px -6px rgba(99, 102, 241, 0.12), 0 4px 12px -2px rgba(15, 23, 42, 0.06)`.
- **Live Mic State:** Dynamic pulse glow applied to primary input nodes using an inner and outer emerald/indigo chromatic aura (`box-shadow: 0 0 0 6px rgba(99, 102, 241, 0.2)`).

## Components

### Action Buttons
- **Primary Speak/Record Action:** Giant stadium floating trigger (68px height) centered along the lower viewport. In resting state: solid `#6366F1` with white icon. In recording state: transitions to pulsating `#EF4444` with sound-wave micro-animation.
- **Secondary Action:** Ghost and filled-tonal variants (`#EEF2FF` text with `#4338CA`) for audio playback and tempo speed toggle buttons (`0.8x`, `1.0x`).

### Phonetic IPA Chips
- Interactive pill chips displaying syllable breakups (e.g., `/vəʊ/` • `/kæl/` • `/ɪs/`).
- Default: `#F1F5F9` background, `#334155` text.
- Mastered: `#ECFDF5` background, `#065F46` text, with a `#10B981` border stroke.
- Needs Work: `#FEF2F2` background, `#991B1B` text, with an inline underline stroke in `#EF4444`. Tapping any chip opens an articulation sheet showing tongue position cross-sections.

### Waveform Audio Visualizer
- Symmetric dual-track audio visualizer displaying real-time frequency heights. Native speech target rendered as a muted ghost track (`#CBD5E1`), overlaid with the live learner track in dynamic emerald or indigo bars. 
- Bar width: 3px; gap: 2px; corner radius: full.

### Assessment Bottom Sheets
- Fixed-elevation bottom sheet snapping to 45% or 85% viewport heights. Contains overall pronunciation score (0–100%), acoustic fluency gauge, and targeted actionable feedback tips. Top edges utilize a 32px corner radius accompanied by a centered 36px wide grab handle (`#CBD5E1`).