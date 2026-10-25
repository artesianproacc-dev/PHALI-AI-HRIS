# Perbaikan deployment Edge Functions PHALI

Kasus: deploy menampilkan `Module not found .../supabase/functions/_shared/core.ts` setelah hanya index.ts terunggah. Paket ini menghindari kebutuhan pengunggahan helper lokal terpisah dengan menyertakan helper di dalam entrypoint setiap function. Penyebab internal kegagalan penemuan file oleh CLI pada mesin pengguna belum dipastikan; perbaikan menghilangkan ketergantungan lokal tersebut.

1. Ekstrak PHALI-PERBAIKAN-EDGE.zip ke folder sementara.
2. Salin seluruh isinya ke folder proyek yang berisi package.json, misalnya C:\Users\hi\Downloads\PHALI-AI-HRIS\hr-insight. Pilih Replace files jika ditanya. Gabungkan folder, jangan membuat satu folder supabase di dalam supabase yang lama. Patch tidak berisi .env, secret, migrasi atau seed.
3. Buka PowerShell pada folder proyek, jalankan:

```powershell
node scripts/prepare-edge-functions.mjs
```

4. Deploy ulang satu per satu:

```powershell
npx.cmd supabase functions deploy ai-narasi --project-ref rpoijmjcobisvypobzuc --use-api
npx.cmd supabase functions deploy ai-chat --project-ref rpoijmjcobisvypobzuc --use-api
```

Project ref di atas adalah ref yang disampaikan pengguna; tidak berisi kredensial. Jika diminta login, jalankan `npx.cmd supabase login` terlebih dahulu. Jika memakai proyek lain, ganti ref.

5. Setelah berhasil, pastikan kedua function tampil di dashboard Supabase. Lanjutkan pengaturan Pages dan pengujian AI melalui aplikasi dengan akun yang berhak. Jangan mengulang migrasi atau seed untuk patch ini.
6. Unggah perubahan file patch ke repository GitHub yang sama agar source di laptop dan GitHub konsisten; file konfigurasi lokal rahasia tidak ikut diunggah.

## Pemeliharaan kode

Edit `_shared/core.ts` dan `ai-narasi/handler.ts` / `ai-chat/handler.ts`, kemudian jalankan `npm run prepare:edge`. index.ts adalah hasil generator dan tidak diedit manual. `npm run build` serta workflow CI juga menyiapkan entrypoint. Tidak ada perubahan pada autentikasi, RLS, peran, kebijakan AI atau frontend dalam patch ini.

## Pemeriksaan yang dijalankan

- Generator dan pemeriksaan konsistensi hasil: lulus.
- Deno check untuk dua entrypoint dan dua handler: lulus.
- Empat tes backend (filter, JWT, 429 dan hak akses AI): lulus.
- Build frontend dengan prebuild generator: lulus.
- Deployment ke Supabase live belum dijalankan dari lingkungan pembuat karena kredensial login tidak tersedia.
