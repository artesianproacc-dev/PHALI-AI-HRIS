# Laporan verifikasi — 25 Oktober 2026

## Berhasil dijalankan

| Pemeriksaan | Hasil |
| --- | --- |
| npm install dan package-lock | Berhasil |
| npm run lint | Lulus, TypeScript strict |
| npm test | 7 tes lulus: hak akses empat peran, signature gambar, penolakan SVG, serta format Indonesia, tanggal/gaji, CSV kutipan/BOM/laporan baris, status keluar |
| npm run test:sql | Lulus pada PostgreSQL WASM PGlite |
| Turnover dataset kecil | 1 keluar / ((2 awal + 1 akhir)/2) × 100 = 66,67%, bulanan dan departemen |
| Kehadiran dataset kecil | 2 hadir/telat dari 4 catatan = 50%; telat 25% |
| Time-to-hire dataset kecil | (10 + 20) / 2 = 15 hari; 30 pelamar |
| RLS viewer | INSERT ditolak, UPDATE dan DELETE nol baris; eskalasi profile, baca audit/cache, pemanggilan limiter administratif diblokir |
| Organisasi/peran/profil/Storage | Lulus: admin dapat mengubah perusahaan/peran; Staf HR CRUD; Manajer dilarang menulis HR; Pengamat anti-eskalasi; foto profil sendiri dan larangan unggah/ubah/hapus foto pengguna lain; logo hanya admin |
| Seed sintetis | 300 karyawan, 75.450 absensi, kelima status terisi |
| Enam RPC pada dataset seed | Seluruh fungsi berhasil dieksekusi |
| Deno check dua Edge Functions | Lulus, menggunakan dependensi npm yang dipin |
| Deno backend tests | 4 lulus: kontrol akses peran AI, filter, JWT wajib, 429 + 2 retry + pesan aman |
| npm run build | Lulus, tanpa error TypeScript; bundle dibagi untuk grafik/Supabase/React |
| PWA build | Manifest dan ikon dihasilkan; service worker dengan 22 aset precache |
| bash -n scripts/deploy.sh | Lulus |

PGlite memakai PostgreSQL dan RLS, dengan schema auth dan metadata Storage minimal tiruan. Pengujian Supabase hosted dan browser tetap diperlukan. Ini bukan klaim semua layanan live sudah bekerja.

## Percobaan deployment dan hambatan

- Supabase CLI 2.122.0 berhasil dipanggil melalui npx.
- `npx supabase projects list` menolak: access token belum disediakan.
- `scripts/deploy.sh` berhenti sesuai preflight: SUPABASE_PROJECT_REF belum tersedia.
- GitHub CLI tidak tersedia; token/login GitHub juga tidak ditemukan pada variabel lingkungan yang relevan.
- Tidak ada kredensial Supabase atau Groq. Secret tidak dibuat-buat dan tidak diganti dengan kredensial pihak lain.

## Belum dapat diverifikasi

- Repo GitHub publik, push remote, status CI GitHub dan URL GitHub Pages.
- Migrasi/seed di Supabase cloud, pembuatan akun demo dan password aktual.
- Login browser dengan akun demo, fungsi AI terhadap Groq sungguhan, dan smoke test live.
- Unggah/hapus gambar melalui layanan Storage sungguhan dan signed URL.
- Tampilan desktop/ponsel dalam browser, dialog instalasi PWA, pembaruan versi dan reload luring pada perangkat nyata.

DEPLOY.md memuat langkah untuk seluruh item di atas. `scripts/smoke.mjs` tersedia untuk login, enam RPC, dan satu narasi AI sesudah deployment. Build dist yang disertakan belum berisi konfigurasi proyek Supabase; lakukan build ulang setelah mengisi dua variabel publik. GitHub Actions akan melakukan build ulang tersebut.

## Pembaruan versi pengaturan

Implementasi menambahkan pengaturan satu perusahaan, empat peran, bucket privat logo/foto, RPC profil/peran, branding sidebar dan cetak, serta Ms. Phali (HRD Assistant) dengan mode pertimbangan keputusan. Semua migrasi dijalankan berurutan dalam tes SQL. Tidak ada migrasi atau deployment remote yang diklaim sudah dijalankan. Pembatasan upload ukuran/MIME oleh layanan Storage dan tampilan signed URL memerlukan pemeriksaan pada Supabase live; tes PGlite memeriksa kebijakan SQL pada metadata tiruan. Vitest dibatasi ke folder src agar tes Deno dijalankan oleh runtime Deno, bukan oleh Vitest.

## Branding PHALI AI-HRIS

Logo lengkap, simbol dan avatar asli tersedia pada `public/branding/`. Identitas aplikasi telah diselaraskan di halaman masuk, sidebar, footer, judul HTML, manifest serta panduan. Ikon 192/512/maskable diturunkan dari simbol. Pengujian build dan unit/backend diulang untuk paket akhir; keterbatasan deployment dan pengujian perangkat nyata tetap berlaku.
