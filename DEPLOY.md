# Deploy PHALI AI-HRIS ke GitHub Pages dan Supabase

## Status lingkungan pembuat

Tidak ada `gh` atau login GitHub, tidak ada SUPABASE_PROJECT_REF, SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD, SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, atau GROQ_API_KEY. Supabase CLI dapat dijalankan melalui npx. Karena akses ini tidak tersedia, repo remote, database cloud, akun demo, function live, CI remote, dan URL live belum dibuat. File tidak menggunakan kredensial pengganti palsu.

## 1. Prasyarat dan pengambilan kredensial

Pasang Node.js 22+, Git, GitHub CLI (https://cli.github.com). Jalankan dari Bash/Git Bash/WSL. Untuk PowerShell gunakan `$env:NAMA="nilai"` sebagai padanan `export NAMA="nilai"`.

1. Supabase: buka https://supabase.com/dashboard, buat proyek baru khusus demonstrasi dan simpan password database. Project ref ada di Settings > General / Project ID dan juga bagian subdomain URL `https://REF.supabase.co`. Project URL dan `anon` key ada di Settings > API / API Keys. Gunakan legacy anon key untuk VITE_SUPABASE_ANON_KEY; **jangan gunakan service_role**. Service role diambil dari bagian secret/legacy keys untuk skrip lokal saja. Access token CLI dibuat lewat https://supabase.com/dashboard/account/tokens atau `npx supabase login`.
2. Groq: buka https://console.groq.com, masuk, buka API Keys, pilih Create API Key dan simpan ke environment lokal. Cek halaman Models dan Limits untuk ketersediaan `openai/gpt-oss-120b`. Gunakan model yang mendukung tool calling jika mengganti.
3. GitHub: `gh auth login`, pilih akun pemilik repo. Pastikan `gh auth status` berhasil.
4. Jangan tempel secret pada file source, README, GitHub Issue, terminal yang direkam, atau variabel VITE. Masukkan environment secara privat. `.env` tidak otomatis di-load oleh shell; `node --env-file=.env ...` dapat dipakai untuk skrip Node, tetapi variabel deployment perlu diekspor.

Contoh nama variabel yang perlu diekspor (ganti nilai di terminal lokal; tidak di source):

```bash
export SUPABASE_PROJECT_REF="REF_ANDA"
export SUPABASE_URL="https://REF_ANDA.supabase.co"
export SUPABASE_ANON_KEY="ANON_KEY_ANDA"
export SUPABASE_SERVICE_ROLE_KEY="SERVICE_ROLE_LOKAL"
export SUPABASE_ACCESS_TOKEN="TOKEN_CLI_ANDA"
export SUPABASE_DB_PASSWORD="PASSWORD_DATABASE_ANDA"
export GROQ_API_KEY="KUNCI_GROQ_ANDA"
export GROQ_MODEL="openai/gpt-oss-120b"
```

## 2. Deployment otomatis dari komputer Anda

Ekstrak ZIP, masuk direktori `hr-insight`, isi environment di atas, lalu:

```bash
export HR_INSIGHT_SEED=yes
bash scripts/deploy.sh
```

Skrip menguji, build, link Supabase, migrasi, seed bila opt-in, deploy dua function, set secret melalui file sementara mode 600, buat empat pengguna demo, buat repo publik, set dua secret frontend, aktifkan Pages Actions, lalu push main. Catat password demo yang hanya dicetak sekali. Seed menghapus data domain yang sudah ada; gunakan proyek khusus demo. Jika berhenti, baca error dan ikuti langkah manual di bawah. Skrip dapat dijalankan kembali; seed tetap destruktif bila opt-in, akun yang sudah ada dilewati.

## 3. Backend manual

Konfigurasi `supabase/config.toml` sudah tersedia; **jangan menimpa dengan `supabase init`**. Pada folder baru yang belum punya config saja gunakan `npx supabase init`.

```bash
npm ci
npx supabase --version
npx supabase login
npx supabase link --project-ref "$SUPABASE_PROJECT_REF"
npx supabase db push --include-seed
npm run prepare:edge
npx supabase functions deploy ai-narasi --use-api
npx supabase functions deploy ai-chat --use-api
```

`db push --include-seed` menjalankan migrasi dan seed yang dikonfigurasi. Jika seed tidak dijalankan pada proyek yang sudah pernah di-seed, jalankan isi `supabase/seed.sql` melalui SQL Editor dashboard untuk reset demonstrasi secara eksplisit. Jangan menjalankan reset pada proyek produksi.

Set secret dengan file sementara di luar repo:

```bash
secret_file=$(mktemp)
chmod 600 "$secret_file"
printf 'GROQ_API_KEY=%s\nGROQ_MODEL=%s\n' "$GROQ_API_KEY" "${GROQ_MODEL:-openai/gpt-oss-120b}" > "$secret_file"
npx supabase secrets set --env-file "$secret_file"
rm -f "$secret_file"
node scripts/create-demo-users.mjs
```

Jangan ubah role dari metadata signup. Trigger selalu membuat viewer; skrip Admin API memperbarui profil admin lewat service role. Pada Supabase Auth > URL Configuration, set Site URL ke `https://USERNAME.github.io/hr-insight/`, tambahkan URL tersebut sebagai Redirect URL; untuk lokal tambahkan `http://localhost:5173/hr-insight/`. Login email/password biasa tidak memakai callback eksternal.

Jika CLI tidak dapat login: gunakan SQL Editor Supabase untuk menjalankan ketiga file migrasi secara berurutan (termasuk organisasi/peran dan Storage), lalu seed hanya untuk instalasi baru. Di Edge Functions dashboard, buat `ai-narasi` dan `ai-chat`, unggah file `index.ts` beserta folder `_shared` sesuai import relatif (gunakan editor multi-file jika tersedia). Atur secrets di Edge Functions > Secrets. Matikan gateway legacy Verify JWT untuk kedua function; validasi tetap wajib dilakukan oleh `auth.getUser()` dalam kode. CLI adalah jalur yang disarankan untuk menjaga struktur import. Buat akun terkonfirmasi lewat skrip Admin API; jangan menyimpan password dalam SQL/repo.

## 4. GitHub manual

```bash
git init -b main
git add .
git commit -m "Bangun PHALI AI-HRIS PWA"
gh auth login
gh repo create hr-insight --public --source=. --remote=origin
printf '%s' "$SUPABASE_URL" | gh secret set VITE_SUPABASE_URL
printf '%s' "$SUPABASE_ANON_KEY" | gh secret set VITE_SUPABASE_ANON_KEY
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
gh api --method POST "repos/$repo/pages" -f build_type=workflow
git push -u origin main
gh run list
gh run watch
```

Jika repo sudah punya `.git`, lewati init dan commit bila tidak ada perubahan. Jika Pages sudah aktif, gunakan `--method PUT` alih-alih POST. Jika API gagal, buka repo > Settings > Pages > Build and deployment > Source: **GitHub Actions**. Bila tidak memakai gh: buat repo **public** bernama hr-insight lewat web, `git remote add origin https://github.com/USERNAME/hr-insight.git`, lalu push. Tambahkan VITE_SUPABASE_URL dan VITE_SUPABASE_ANON_KEY melalui Settings > Secrets and variables > Actions > New repository secret.

Workflow `deploy.yml` menjalankan npm ci, TypeScript, Vitest, SQL/RLS, Deno check, validasi variabel, build, upload artifact dan deploy Pages. Base Vite mengikuti nama repo; HashRouter menjaga navigasi. Jika repo diganti nama, workflow menyesuaikan base otomatis; URL Auth perlu disesuaikan. Build lokal menggunakan `/hr-insight/` atau environment VITE_BASE_PATH.

URL setelah workflow berhasil: `https://USERNAME.github.io/hr-insight/`. Ambil URL aktual dari job deployment / Settings > Pages; ini format, bukan klaim aplikasi sudah live.

## 5. Smoke test setelah live

```bash
export DEMO_EMAIL="admin@hrinsight.demo"
# Isi password dari keluaran create-demo-users secara privat.
read -rs -p "Password demo: " DEMO_PASSWORD
export DEMO_PASSWORD
npm run smoke
unset DEMO_PASSWORD
```

Skrip login, memanggil enam RPC dan ai-narasi sekali, lalu logout. Ini memakai kuota Groq. Lakukan pemeriksaan browser tambahan:

1. Buka URL Pages aktual, login admin, cek data 2025-10-01 sampai 2026-09-30.
2. Buka enam modul, ubah departemen dan periode, cek grafik/tabel/CSV/cetak. Narasi harus memuat angka yang sesuai filter. Chat harus memberi jawaban SDM dan menolak pertanyaan non-SDM.
3. Tambah/ubah/hapus karyawan sintetis, impor template dan CSV salah. Audit harus bertambah.
4. Logout, login viewer: menu data/audit hilang. SQL test di bawah memastikan RLS, bukan hanya UI.
5. Buka Pengaturan sebagai admin, isi identitas perusahaan dan unggah logo PNG/JPG/WebP. Pastikan branding dan cetak mengikuti perubahan. Buka Profil saya pada setiap peran, ubah nama/foto; pastikan tidak bisa mengubah profil atau folder foto orang lain. Uji Staf HR dapat mengubah data tetapi tidak perusahaan/peran; Manajer dapat memakai Ms. Phali tanpa mengubah data; Pengamat tidak dapat memakai AI.
6. Buka beberapa dashboard daring. Di DevTools > Application pastikan service worker aktif dan manifest/ikon valid. Reload satu kali setelah instalasi SW. Matikan jaringan, reload URL dan buka kombinasi filter yang sudah tersimpan; tampil pesan ringkasan luring. Filter belum tersimpan harus menampilkan pesan belum ada cache. AI dinonaktifkan saat luring.
7. Chrome/Edge Android: gunakan Install aplikasi. Safari iOS: Bagikan > Tambah ke Layar Utama; beforeinstallprompt tidak tersedia di Safari. PWA harus HTTPS.
8. Push perubahan baru, tunggu Actions selesai, buka ulang: tampil pembaruan versi bila service worker mendeteksi versi baru, pilih Perbarui aplikasi.

## 6. SQL/RLS pada database lokal Supabase

```bash
npx supabase start
npx supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/metrics_rls.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/organization_roles.sql
```

Dataset uji menggunakan transaksi dan rollback; tidak menetap. Pengujian PGlite tanpa Docker juga tersedia: `npm run test:sql`. Auth dibuat tiruan di PGlite, sedangkan Supabase lokal memakai auth asli. Jangan jalankan test pada produksi. Uji viewer yang menghasilkan UPDATE/DELETE nol baris merupakan perilaku RLS normal; INSERT melempar insufficient_privilege.

## 7. Pemecahan masalah

- Layar login menyatakan belum dikonfigurasi: isi dua secrets publik sebelum build, ulang workflow. Variabel Vite disisipkan saat build.
- Login gagal: cek email sudah dikonfirmasi oleh skrip, URL proyek dan anon key benar, serta user punya profile. Jika user dibuat sebelum trigger, tambahkan profile melalui SQL Editor secara terkontrol.
- RPC tidak ditemukan: migrasi belum di-push atau schema cache belum terbarui. Periksa Supabase Logs, jangan mengganti ke service role pada frontend.
- Function 401: sesi tidak valid; login kembali. Gateway legacy JWT harus mengikuti config (`verify_jwt=false`); kode tetap memverifikasi JWT melalui Auth.
- AI 503: cek GROQ_API_KEY/model tersedia, deployment function dan koneksi keluar. Tidak ada rincian secret dalam error klien.
- AI 429: tunggu kuota provider atau jendela per pengguna satu jam. Jangan menaikkan limit tanpa mempertimbangkan biaya.
- Actions merah pada konfigurasi: kedua secret frontend belum diatur. Actions merah pada Pages: aktifkan sumber GitHub Actions dan repo public.
- Data kosong: gunakan rentang seed dan departemen yang sesuai. Default akhir seed September 2026, bukan tanggal hari ini.
- Sebelum data nyata, evaluasi kebijakan bahwa seluruh pengguna login dapat SELECT sumber gaji; ini mengikuti spesifikasi demo dan bukan pembatasan akses per departemen.

## Pembaruan dari paket pertama

Ikuti UPDATE.md. Gunakan `npx supabase db push` tanpa `--include-seed`, deploy ulang ai-chat dan ai-narasi, lalu push frontend. Tidak perlu membuat ulang akun lama. Migrasi Storage membuat bucket privat; jangan mengubah bucket ke public. Jika foto/logo tidak bisa diunggah, periksa migrasi 003 dan hak pengguna; jangan menambahkan service role ke frontend.

## Perbaikan bundling helper pada Windows

Jika deploy API menampilkan `Module not found .../_shared/core.ts`, gunakan patch `PHALI-PERBAIKAN-EDGE.zip`. Entrypoint index.ts kini menyertakan kode helper secara langsung sehingga tidak bergantung pada penemuan file lokal oleh CLI. Sumber yang dapat diedit tetap `_shared/core.ts` dan `ai-narasi/handler.ts` / `ai-chat/handler.ts`. Jalankan `npm run prepare:edge` setelah mengubah sumber. Build frontend juga memanggil generator melalui prebuild. Jangan mengedit index.ts hasil generator secara manual.

Patch tidak berisi migrasi database, kredensial atau penggantian konfigurasi Supabase. Terapkan pada folder proyek lama; tidak perlu mengulang seed atau SQL. Deploy cloud masih memerlukan login Supabase pengguna sendiri.
