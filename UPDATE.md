# Pembaruan PHALI AI-HRIS — Pengaturan organisasi, peran, dan Ms. Phali

## Hak akses

| Fitur | Admin SDM | Staf HR | Manajer | Pengamat |
| --- | --- | --- | --- | --- |
| Analitik, filter, CSV, cetak | Ya | Ya | Ya | Ya |
| Ms. Phali: narasi & chat keputusan | Ya | Ya | Ya | Tidak |
| CRUD dan impor data HR | Ya | Ya | Tidak | Tidak |
| Pengaturan perusahaan dan logo | Ya | Tidak | Tidak | Tidak |
| Mengubah peran pengguna lain | Ya | Tidak | Tidak | Tidak |
| Log audit | Ya | Tidak | Tidak | Tidak |
| Nama dan foto profil sendiri | Ya | Ya | Ya | Ya |

Pengaturan ini adalah satu organisasi per instalasi. Data karyawan tetap menjadi satu ruang kerja bersama. Ini bukan dukungan tenant perusahaan terpisah. Sesuai arsitektur awal, seluruh pengguna login masih memiliki akses SELECT tabel HR melalui API; jangan menafsirkan menu analitik sebagai penyembunyian gaji perorangan pada level database.

## Upgrade tanpa menghapus data

1. Ganti source proyek dengan isi paket terbaru. Simpan `.env` lokal sendiri dan jangan commit.
2. Dari direktori proyek yang sudah terhubung ke Supabase:

```bash
npm ci
npx supabase db push
npx supabase functions deploy ai-narasi
npx supabase functions deploy ai-chat
npm run lint
npm test
npm run test:sql
npm run build
git add .
git commit -m "Tambahkan organisasi, peran, logo, foto dan Ms. Phali"
git push origin main
```

Jangan gunakan seed/reset saat upgrade; migrasi tambahan mempertahankan karyawan dan pengguna lama. `db push` mengerjakan migrasi 002 (perusahaan/peran/profil) dan 003 (bucket/kebijakan Storage). Jika mengerjakan instalasi baru, ikuti DEPLOY.md. Secret Groq lama tetap dipakai.

3. Login akun Admin SDM, buka Pengaturan. Akun lama `hr_admin` tetap Admin SDM, akun `viewer` menjadi label Pengamat. Profil pengguna baru otomatis Pengamat.
4. Bila ingin akun demo Staf HR dan Manajer, jalankan ulang `node scripts/create-demo-users.mjs` memakai service role di environment lokal; akun lama dilewati dan passwordnya tidak diganti. Password akun baru dicetak sekali.
5. Jalankan pemeriksaan browser dan smoke test di DEPLOY.md. Deployment cloud belum dijalankan dari lingkungan pembuat karena kredensial belum tersedia.

## Mengatur perusahaan dan logo

Pengaturan → Organisasi / perusahaan → isi nama, bidang, kontak, alamat, situs web dan zona waktu. Pilih gambar logo lalu tekan **Simpan pengaturan perusahaan**. **Hapus gambar** juga baru diterapkan setelah disimpan.

Logo tampil pada sidebar dan header cetak. Nama perusahaan tampil di judul ruang kerja serta footer. Logo tidak mengubah ikon instalasi PWA (ikon produk PHALI AI-HRIS) dan tidak ditampilkan ke pengunjung sebelum login. Semua perubahan perusahaan masuk audit log.

## Mengatur peran

Pengaturan → Pengguna & peran → pilih peran → **Simpan peran**. Pengguna harus sudah memiliki akun di Supabase Auth dan profil hasil trigger. Daftar maksimal 1.000 pengguna. Anda tidak dapat mengubah peran sendiri melalui aplikasi; hal ini menjaga agar Admin SDM tetap tersedia. Perubahan peran di backend berlaku langsung pada permintaan berikutnya; menu pengguna lain disegarkan saat tab kembali fokus, koneksi pulih, atau muat ulang halaman.

## Nama dan foto profil

Klik foto/inisial pada header atau menu **Profil saya**. Isi nama, pilih foto, lalu tekan **Simpan profil**. Setiap pengguna hanya dapat mengubah profil sendiri. Foto pada header menampilkan hasil tersimpan. Foto berbentuk lingkaran dengan pemotongan otomatis; logo ditampilkan utuh.

PNG/JPG/WebP maksimal 2 MB; validasi signature berkas dan decode gambar dilakukan sebelum upload. SVG tidak didukung. Foto dan logo disimpan pada bucket privat dan ditampilkan melalui signed URL berdurasi satu jam. Kebijakan Storage membatasi perubahan logo ke Admin SDM dan perubahan foto ke folder UUID pemilik. Jika penyimpanan profil gagal setelah upload, berkas baru dibersihkan; berkas lama dibersihkan sesudah perubahan berhasil disimpan. Jika pembersihan gambar lama gagal, aplikasi memberi pesan tanpa membatalkan perubahan profil yang sudah tersimpan.

## Menggunakan Ms. Phali (HRD Assistant)

Tersedia untuk Admin SDM, Staf HR, dan Manajer. Buka menu **Ms. Phali**, tentukan filter periode dan departemen, lalu pilih contoh pertanyaan atau ketik pertanyaan, misalnya:

- Apa prioritas keputusan SDM periode ini?
- Apa rekomendasi untuk meninjau turnover dan retensi?
- Apa langkah evaluasi absensi dan biaya lembur?
- Bagaimana prioritas pelatihan berdasarkan kinerja?

Pertanyaan keputusan menghasilkan pertimbangan: temuan berbasis angka, prioritas dengan alasan, opsi tindakan/risiko, dan data tambahan yang perlu diverifikasi. Keputusan akhir tetap pada manusia. Ms. Phali tidak menilai individu, tidak membuat keputusan pemecatan, dan tidak mengirim nama/NIK/gaji individual ke Groq.

Pertanyaan mentah dipetakan secara lokal ke topik tetap untuk menjaga privasi. Pertanyaan prioritas umum meninjau keenam modul; pertanyaan spesifik memakai modul terkait. Filter tanggal/departemen mengikuti antarmuka. Riwayat chat ditampilkan selama halaman terbuka, tetapi setiap pertanyaan diproses mandiri; jawaban sebelumnya tidak dikirim sebagai konteks percakapan.

## Branding PHALI AI-HRIS

Nama tampilan kini PHALI AI-HRIS; asisten tetap Ms. Phali (HRD Assistant). Logo lengkap dengan tulisan Phali dan AI-HRIS berada di bawah simbol, digunakan di halaman masuk dan sidebar. Ikon PWA memakai simbol tanpa teks agar tetap terbaca pada ukuran kecil. Avatar Ms. Phali tampil pada chat dan kartu narasi. Aset statis branding ikut precache untuk akses luring.

Repo/base tetap `hr-insight` agar URL dan konfigurasi sebelumnya tetap kompatibel. Tidak perlu mengganti nama repo atau alamat akun demo. Jika Anda sengaja memilih repo baru `phali-ai-hris`, workflow mengikuti nama repo dan variabel VITE_BASE_PATH untuk build lokal harus `/phali-ai-hris/`; perbarui juga URL Auth Supabase.

Untuk memperbarui ikon setelah mengganti berkas simbol, jalankan `npm run icons`, kemudian build dan deploy kembali. Pada PWA yang sudah terpasang, browser dapat menunda pembaruan ikon; pasang ulang bila ikon lama masih tampil setelah versi baru aktif.
