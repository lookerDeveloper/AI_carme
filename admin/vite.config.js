import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://10.56.193.133:3000',
        changeOrigin: true
      },
      '/uploads': {
        target: 'http://10.56.193.133:3000',
        changeOrigin: true
      }
    }
  }
})
