import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import {VitePWA} from 'vite-plugin-pwa';
const base=process.env.VITE_BASE_PATH||'/hr-insight/';
export default defineConfig({base,build:{rollupOptions:{output:{manualChunks:{graphiques:['recharts'],supabase:['@supabase/supabase-js'],react:['react','react-dom','react-router-dom']}}}},plugins:[react(),VitePWA({registerType:'prompt',includeAssets:['offline.html','branding/*.png'],manifest:{name:'PHALI AI-HRIS',short_name:'PHALI',lang:'id',theme_color:'#123c38',background_color:'#f4f7f6',display:'standalone',start_url:base,scope:base,icons:[{src:'icon-192.png',sizes:'192x192',type:'image/png'},{src:'icon-512.png',sizes:'512x512',type:'image/png'},{src:'maskable-512.png',sizes:'512x512',type:'image/png',purpose:'maskable'}]},workbox:{navigateFallback:'index.html',maximumFileSizeToCacheInBytes:6*1024*1024,globPatterns:['**/*.{js,css,html,png,svg,woff2}']}})]});
