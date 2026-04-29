import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx,vue,svelte}'],
  theme: {
    extend: {
      colors: {
        // Kaset Atlas Brand Colors
        kaset: {
          green: '#2F6B3F',         // Primary — logo, headings, primary buttons
          'green-dark': '#1F4A2A',  // Hover/active state
          'green-light': '#5A9068', // Subtle backgrounds, hover states
        },
        soil: {
          brown: '#8A5A33',         // Earth — soil, roots, source sections
          'brown-dark': '#5C3A20',
          'brown-light': '#B5895E',
        },
        sun: {
          orange: '#F59E42',        // Accent — badges, hover, highlights
          'orange-dark': '#D97A1F',
          'orange-light': '#FBC080',
        },
        water: {
          blue: '#3B82A0',          // Information — water, irrigation, info boxes
          'blue-dark': '#256075',
          'blue-light': '#7AAEC4',
        },
        rice: {
          cream: '#F7F1E3',         // Primary background
          'cream-dark': '#E8DCBF',
          'cream-light': '#FCF8ED',
        },
        charcoal: {
          DEFAULT: '#26312A',        // Body text
          dark: '#1A2520',
          light: '#4A5752',
        },
        // Confidence indicators
        confidence: {
          high: '#2F6B3F',     // Use kaset green
          medium: '#F59E42',   // Use sun orange
          low: '#B5895E',      // Use soil brown light
          uncertain: '#8B8680', // Neutral grey
        },
      },
      fontFamily: {
        thai: ['"LINE Seed Sans Thai"', '"Noto Sans Thai"', 'sans-serif'],
        sans: ['Inter', '"IBM Plex Sans"', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', '"Fira Code"', 'monospace'],
      },
      fontSize: {
        // Optimized for Thai readability — slightly larger than default
        'caption': ['0.8125rem', { lineHeight: '1.5', letterSpacing: '0.01em' }],
        'body': ['1.0625rem', { lineHeight: '1.75', letterSpacing: '0' }],
        'lead': ['1.1875rem', { lineHeight: '1.7' }],
        'h4': ['1.25rem', { lineHeight: '1.4', fontWeight: '600' }],
        'h3': ['1.5rem', { lineHeight: '1.35', fontWeight: '700' }],
        'h2': ['1.875rem', { lineHeight: '1.3', fontWeight: '700' }],
        'h1': ['2.5rem', { lineHeight: '1.2', fontWeight: '700' }],
        'display': ['3.5rem', { lineHeight: '1.1', fontWeight: '800' }],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      maxWidth: {
        'reading': '68ch',  // Optimal for Thai body text
        'wide': '84rem',
      },
      borderRadius: {
        'card': '0.75rem',
        'badge': '0.375rem',
      },
      boxShadow: {
        'card': '0 1px 3px rgba(38, 49, 42, 0.06), 0 1px 2px rgba(38, 49, 42, 0.04)',
        'card-hover': '0 4px 12px rgba(38, 49, 42, 0.08), 0 2px 4px rgba(38, 49, 42, 0.04)',
        'inset-line': 'inset 0 -1px 0 rgba(38, 49, 42, 0.08)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(4px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
      typography: ({ theme }: { theme: (path: string) => string }) => ({
        DEFAULT: {
          css: {
            '--tw-prose-body': theme('colors.charcoal.DEFAULT'),
            '--tw-prose-headings': theme('colors.kaset.green-dark'),
            '--tw-prose-links': theme('colors.water.blue'),
            '--tw-prose-bold': theme('colors.charcoal.dark'),
            maxWidth: theme('maxWidth.reading'),
            fontSize: theme('fontSize.body[0]'),
            lineHeight: '1.75',
          },
        },
      }),
    },
  },
  plugins: [],
};

export default config;
