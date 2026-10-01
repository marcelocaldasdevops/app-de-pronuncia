/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#4648d4",
          container: "#6063ee",
          fixed: "#e1e0ff",
          "fixed-dim": "#c0c1ff",
        },
        secondary: {
          DEFAULT: "#006c49",
          container: "#6cf8bb",
          fixed: "#6ffbbe",
          "fixed-dim": "#4edea3",
        },
        tertiary: {
          DEFAULT: "#825100",
          container: "#a36700",
          fixed: "#ffddb8",
          "fixed-dim": "#ffb95f",
        },
        surface: {
          DEFAULT: "#faf8ff",
          dim: "#d2d9f4",
          bright: "#faf8ff",
          variant: "#dae2fd",
          container: {
            lowest: "#ffffff",
            low: "#f2f3ff",
            DEFAULT: "#eaedff",
            high: "#e2e7ff",
            highest: "#dae2fd",
          },
        },
        "on-surface": {
          DEFAULT: "#131b2e",
          variant: "#464554",
        },
        phoneme: {
          green: "#10b981",
          "green-bg": "#ecfdf5",
          amber: "#f59e0b",
          "amber-bg": "#fffbeb",
          red: "#ef4444",
          "red-bg": "#fef2f2",
        },
      },
      fontFamily: {
        headline: ['"Plus Jakarta Sans"', 'sans-serif'],
        body: ['"Plus Jakarta Sans"', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'monospace'],
      },
      borderRadius: {
        DEFAULT: "1rem",
        lg: "2rem",
        xl: "3rem",
        full: "9999px",
      },
      spacing: {
        gutter: "1rem",
        margin: "1.25rem",
        "space-xs": "0.25rem",
        "space-sm": "0.5rem",
        "space-md": "0.875rem",
        "space-lg": "1.25rem",
        "space-xl": "2rem",
      },
      boxShadow: {
        sm: "0 2px 8px -2px rgba(15, 23, 42, 0.05), 0 1px 3px 0 rgba(15, 23, 42, 0.04)",
        md: "0 12px 32px -6px rgba(99, 102, 241, 0.12), 0 4px 12px -2px rgba(15, 23, 42, 0.06)",
        mic: "0 0 0 8px rgba(70, 72, 212, 0.18), 0 0 0 16px rgba(70, 72, 212, 0.08)",
      }
    },
  },
  plugins: [],
};
