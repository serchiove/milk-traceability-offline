import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const api = process.env.ACOPIO_API_TARGET || 'http://127.0.0.1:18080';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    proxy: { '/api': api, '/actuator': api }
  }
});
