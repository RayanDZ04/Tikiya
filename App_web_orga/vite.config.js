import { defineConfig } from 'vite';

// Le front appelle /api/* ; Vite proxifie vers l'API Rust (localhost:8080),
// ce qui évite tout souci de CORS en dev.
export default defineConfig({
  server: {
    port: 5000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
});
