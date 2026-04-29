// @ts-check
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';
import react from '@astrojs/react';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://kasetatlas.com',
  integrations: [
    tailwind({
      applyBaseStyles: false,
    }),
    mdx(),
    react(),
    sitemap(),
  ],
  i18n: {
    locales: ['th'],
    defaultLocale: 'th',
  },
  build: {
    format: 'directory',
  },
  vite: {
    ssr: {
      noExternal: ['react-icons'],
    },
  },
});
