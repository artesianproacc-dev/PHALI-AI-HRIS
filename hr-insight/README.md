# PHALI AI-HRIS

Nama produk terbaru: **PHALI AI-HRIS**, dengan **Ms. Phali — HRD Assistant**. Nama teknis repo/base `hr-insight` dan akun demo `@hrinsight.demo` dipertahankan untuk kompatibilitas. Source aplikasi, logo bernama, avatar, ikon PWA, migrasi, pengujian dan panduan sudah termasuk dalam paket.

PWA analitik deskriptif SDM berbahasa Indonesia: ringkasan tenaga kerja, turnover dan retensi, absensi dan cuti, biaya, rekrutmen, kinerja dan pelatihan, serta **Ms. Phali (HRD Assistant)** berbasis angka agregat untuk mendukung pengambilan keputusan SDM.

## Status hasil pengerjaan

Proyek telah diimplementasikan dan diuji lokal. URL live dan akun demo belum tersedia karena lingkungan pembuat tidak memiliki akses GitHub, proyek Supabase, atau kunci Groq. Jangan menganggap aplikasi sudah diterbitkan. Lihat DEPLOY.md untuk pelaksanaan terperinci dan VERIFICATION.md untuk bukti pemeriksaan.

## Arsitektur

```text
Ponsel / Desktop — PWA React + TypeScript + Tailwind + Recharts
                  HashRouter / GitHub Pages / Workbox
                            |
                 Supabase Auth (email + password)
                            |
        Supabase Postgres + RLS + RPC SECURITY INVOKER
                            |
            Supabase Edge Functions (verifikasi JWT)
              | agregat melalui RPC atas nama user
              | cache layanan + audit + batas permintaan
              v
          Groq OpenAI-compatible API (fetch server-side)
```

Frontend hanya membaca VITE_SUPABASE_URL dan VITE_SUPABASE_ANON_KEY. Kunci service role dan Groq tidak masuk bundle atau source. Secret disimpan pada environment Edge Functions. `verify_jwt=false` pada gateway sengaja digunakan: setiap function memverifikasi bearer token dengan `auth.getUser()` dan mengambil profil dari database. Ini mendukung JWT signing keys modern tanpa mempercayai klaim role dari klien.

## Fitur

- Login/logout, rute terlindungi, label peran, sidebar desktop dan navigasi bawah ponsel.
- Enam modul analitik dengan filter tanggal/departemen, KPI, grafik, tabel, ekspor CSV, dan cetak.
- CRUD karyawan dan impor CSV atomik: setiap baris divalidasi, berkas maksimal 2 MB, seluruh impor ditolak bila ada baris salah. Laporan error dapat diunduh.
- Empat peran: Admin SDM mengelola perusahaan, peran, audit dan data; Staf HR mengelola data; Manajer meninjau analitik dan AI; Pengamat melihat analitik. RLS/RPC dan Edge Functions menjaga hak akses di server.
- Pengaturan perusahaan: nama, bidang, alamat, email, telepon, situs web, zona waktu, dan unggah/hapus logo. Branding tampil pada sidebar, judul ruang kerja dan cetak.
- Profil pribadi: ubah nama dan unggah/hapus foto; semua peran hanya dapat mengubah profil sendiri. Gambar raster PNG/JPG/WebP maksimal 2 MB, bucket privat dengan signed URL.
- Narasi Ms. Phali pada setiap modul dan chat untuk Admin SDM/Staf HR/Manajer. Ms. Phali membantu membaca temuan, prioritas, opsi tindakan beserta risiko, dan kebutuhan verifikasi. Chat dengan enam tool RPC terbatas tanpa SQL bebas, maksimal empat putaran tool-call. Retry 429 maksimal dua kali. Batas 20 permintaan per pengguna per jam atomik menggunakan advisory lock database.
- Manifest PWA, ikon PNG 192/512 dan maskable, precache aset, penawaran instalasi pada browser pendukung, indikator koneksi dan pembaruan service worker.
- Hasil agregat terakhir untuk setiap kombinasi pengguna/modul/filter disimpan lokal. Logout membersihkan ringkasan tersimpan. Data karyawan individual dan respons AI tidak di-cache.

## Menjalankan lokal

Node.js 22 atau lebih baru. Dari direktori proyek:

```bash
npm ci
cp .env.example .env
# Isi VITE_SUPABASE_URL dan VITE_SUPABASE_ANON_KEY dalam .env
npm run dev
```

Buka `http://localhost:5173/hr-insight/`. Kredensial frontend menunjuk proyek Supabase yang sudah dimigrasi. Alternatif lokal dengan Docker: `npx supabase start`, `npx supabase db reset`, lalu ambil URL dan anon key dari `npx supabase status`. Jangan menjalankan reset pada data produksi.

```bash
npm run lint
npm test
npm run test:sql
npm run build
```

`lint` menggunakan pemeriksaan TypeScript ketat. SQL tests memakai PostgreSQL WASM PGlite dengan tabel auth/metadata Storage tiruan, role `authenticated`, dan RLS PostgreSQL asli. Kebijakan logo/foto dan empat peran juga diuji; layanan upload Storage sungguhan tetap memerlukan smoke test cloud. Pengujian ini tidak menggantikan smoke test pada Supabase live. SQL yang sama bisa dijalankan pada Supabase lokal menggunakan psql.

## Variabel lingkungan

| Variabel | Lokasi | Kegunaan |
| --- | --- | --- |
| VITE_SUPABASE_URL | frontend / GitHub secret atau variable | URL Supabase publik |
| VITE_SUPABASE_ANON_KEY | frontend / GitHub secret atau variable | anon key publik, bukan service role |
| VITE_BASE_PATH | build | `/hr-insight/`, otomatis dari nama repo pada Actions |
| SUPABASE_PROJECT_REF | terminal lokal | identitas proyek untuk link CLI |
| SUPABASE_ACCESS_TOKEN | terminal lokal | akses CLI Supabase |
| SUPABASE_DB_PASSWORD | terminal lokal | kata sandi database untuk link |
| SUPABASE_URL / SUPABASE_ANON_KEY | terminal lokal | pengguna demo dan smoke test |
| SUPABASE_SERVICE_ROLE_KEY | terminal lokal saja | membuat akun demo dan peran |
| GROQ_API_KEY | terminal untuk set secret / Edge Function | akses Groq |
| GROQ_MODEL | Edge Function | default `openai/gpt-oss-120b` |

Supabase menyediakan SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY secara otomatis pada Edge Functions. Jangan menambahkan awalan VITE pada secret server. `.env` dan seluruh `.env.*` selain contoh diabaikan git.

## Akun demo

Jalankan `node scripts/create-demo-users.mjs` setelah migrasi, dengan environment service role lokal. Dibuat `admin@hrinsight.demo` (hr_admin), `staff@hrinsight.demo` (hr_staff), `manager@hrinsight.demo` (manager), dan `viewer@hrinsight.demo` (viewer/Pengamat), masing-masing dengan password acak kuat yang dicetak sekali pada terminal. Password tidak disimpan atau di-commit. Bila akun sudah ada, skrip melewati tanpa mengganti password; reset melalui dashboard Supabase jika diperlukan. Domain `.demo` bukan inbox email; skrip membuat akun terkonfirmasi melalui Admin API.

## Keputusan dan batasan

1. Dataset sintetis tetap: 1 Oktober 2025–30 September 2026, 300 karyawan, delapan departemen. Gunakan rentang bawaan agar grafik terisi. Semua nama menggunakan label sintetis; tidak ada data orang sungguhan. Seed mengganti seluruh dataset, jadi hanya jalankan pada proyek demonstrasi.
2. Headcount merupakan snapshot tanggal akhir. Turnover bulanan = keluar / rerata headcount pada awal dan akhir interval bulan terpilih. Jika denominator nol, hasil nol; jangan menafsirkan ini sebagai kepastian retensi.
3. Kehadiran = (hadir + telat) / seluruh catatan. Ketidakhadiran tanpa catatan tidak disimpulkan otomatis. Seed hanya hari Senin–Jumat tanpa kalender libur nasional.
4. Payroll diprorata hari kalender setiap bulan dengan interval aktif `[tgl_masuk, tgl_keluar)`. Lembur estimasi `gaji/173 × 1,5 × jam`; bukan mesin payroll legal, belum menghitung pajak/tunjangan/jam berjenjang. Biaya rata-rata departemen memakai karyawan yang menerima payroll pada periode.
5. Rekrutmen dikelompokkan menurut tanggal buka. Time-to-hire adalah tanggal terisi dikurangi tanggal buka untuk lowongan terisi sampai akhir filter. Rata-rata pelatihan mencakup seluruh karyawan yang aktif pada sebagian periode, termasuk tanpa pelatihan.
6. RLS mengikuti permintaan: semua pengguna login dapat membaca data HR sumber, termasuk gaji, melalui API; UI viewer hanya menampilkan agregat. Jika hendak menggunakan data nyata, kebijakan akses sumber perlu disesuaikan sesuai organisasi. Audit hanya admin; cache hanya service role.
7. RPC memakai POST; Workbox Cache API hanya mendukung GET. Karena itu, aplikasi menerapkan stale-while-revalidate di lapisan aplikasi: tampilkan agregat tersimpan, lalu segarkan melalui RPC. Respons disimpan dalam localStorage per pengguna dan filter, sementara Workbox precache shell aplikasi. AI dan Auth tidak di-cache oleh service worker. Offline memerlukan login dan pembukaan dashboard sebelumnya; filter baru yang belum disimpan memerlukan jaringan. Sesi kedaluwarsa dapat memerlukan login daring. Offline bukan penyimpanan data permanen.
8. Privasi chat: pertanyaan mentah tidak pernah dikirim ke Groq. Edge Function memetakan topik lokal ke kosakata enam modul, lalu model memilih tool. Karena itu, chat menjawab ringkasan topik dan filter aktif, bukan detail bebas atau percakapan multi-turn. Filter departemen harus dipilih melalui antarmuka. Pertanyaan di luar topik ditolak; nama/NIK/permintaan perorangan tidak didukung.
9. Semua angka dikirim sebagai agregat; tidak ada nama, NIK, baris gaji per karyawan. Narasi masih perlu diverifikasi. Cache 24 jam menggunakan hash agregat agar perubahan data tidak memakai narasi lama. Cache perlu retensi berkala (`delete from ai_cache where dibuat_pada < now()-interval '2 days'`) jika pemakaian besar.
10. Batas Groq free tier bergantung model dan akun, bisa berubah. Aplikasi tidak menjamin kuota gratis atau ketersediaan model. HTTP 429 ditangani dengan retry 0,5 dan 1 detik, lalu pesan ramah. Satu permintaan chat dapat memakai beberapa panggilan model; batas lokal 20 bukan jaminan bebas 429 provider.
11. Daftar karyawan dibatasi 1.000 baris; audit 200 terbaru. Seed saat ini 300. Skala lebih besar memerlukan pagination. Semua waktu audit disimpan timestamptz; log audit ditampilkan sesuai zona waktu perusahaan. Waktu cache ringkasan masih memakai waktu lokal browser.
12. Satu instalasi Supabase mewakili satu organisasi/perusahaan; pengaturan identitas tidak membuat tenant baru dan tidak memisahkan data antarperusahaan. Logo/foto berada di bucket privat `company-assets`/`avatars`; hanya Admin SDM dapat mengubah logo, setiap pengguna hanya dapat mengunggah/menghapus foto pada folder UUID-nya sendiri. Signed URL diperbarui saat fokus, koneksi pulih, atau interval 50 menit. Logo/foto tidak di-cache oleh service worker dan dapat tidak tampil saat luring. Branding dinamis tersedia setelah login, bukan pada manifest PWA global.
13. Penulisan profil hanya melalui RPC sempit: `update_my_profile` tidak menerima role. `set_user_role` hanya untuk Admin SDM, dicatat dalam audit, dan tidak mengizinkan perubahan peran sendiri. Pengamat tidak memiliki akses AI (HTTP 403 pada Edge Function); Staf HR tidak dapat mengubah perusahaan/peran; Manajer tidak dapat mengubah data HR. Semua pengguna tetap dapat membaca sumber HR sesuai kebijakan awal yang dijelaskan pada poin 6.
14. Tidak ada workflow yang mengunggah service role atau Groq ke GitHub. GitHub Actions menerbitkan frontend saja; perubahan backend dideploy via CLI lokal.

## Referensi resmi

- https://supabase.com/docs/guides/functions/deploy
- https://supabase.com/docs/guides/deployment/database-migrations
- https://console.groq.com/docs/api-reference
- https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages

## Pembaruan pengaturan dan Ms. Phali

Lihat **UPDATE.md** untuk upgrade dari paket pertama tanpa menghapus data, matriks hak akses, dan langkah menggunakan logo/foto profil. Migrasi tambahan: `202610250002_organization_roles.sql` dan `202610250003_branding_storage.sql`. Pengguna lama tetap memiliki role semula.
