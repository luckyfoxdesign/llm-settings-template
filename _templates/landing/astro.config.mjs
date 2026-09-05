// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import vercelStatic from "@astrojs/vercel";

// https://astro.build/config
export default defineConfig({
  // Set the real origin of [project-name] before the first deploy; `site` is
  // what canonical URLs and @astrojs/sitemap are derived from.
  // site: "https://[project-name].example",

  // Force static output (no SSR).
  output: "static",

  adapter: vercelStatic(),

  // Base path: change if the site is served from a subdirectory.
  // For https://example.com/[repo-name]/ set base: "/[repo-name]/".
  base: "/",

  build: {
    format: "directory", // keeps URLs clean: /about/ -> /about/index.html
  },

  // Dev server options.
  server: {
    host: true, // allow external connections (important for Docker)
    port: 3000,
  },

  vite: {
    plugins: [tailwindcss()],
  },
});
