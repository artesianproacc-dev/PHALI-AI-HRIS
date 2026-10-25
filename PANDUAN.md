# Panduan penggunaan PHALI AI-HRIS

## Mulai

Setelah instalasi sesuai DEPLOY.md, buka URL aplikasi dan masuk memakai email/password yang dibuat melalui Supabase. Pengguna baru mendapatkan peran Pengamat. Password akun demo dicetak saat skrip pembuatan akun dijalankan, bukan disimpan dalam paket.

Pada ponsel, menu utama berada di bawah dan bisa digeser. Pada desktop, menu berada di sidebar. Klik foto/inisial pada header untuk mengakses profil sendiri.

## Ringkasan dan modul SDM

Tersedia Ringkasan, Turnover & Retensi, Absensi & Cuti, Biaya Tenaga Kerja, Rekrutmen, serta Kinerja & Pelatihan. Pilih tanggal awal/akhir dan departemen. Kartu, grafik, dan tabel mengikuti filter. Untuk dataset demonstrasi, gunakan 1 Oktober 2025–30 September 2026.

Tombol CSV mengunduh tabel terkait. Tombol Cetak memakai dialog cetak browser; logo dan identitas perusahaan tercantum pada hasil cetak. Perhitungan dan batasannya dijelaskan pada catatan masing-masing modul dan README.md.

## Ms. Phali — HRD Assistant

Admin SDM, Staf HR dan Manajer dapat memakai **Jelaskan data ini** atau membuka menu **Ms. Phali**. Contoh pertanyaan:

- Apa prioritas keputusan SDM periode ini?
- Apa rekomendasi untuk meninjau turnover dan retensi?
- Apa langkah evaluasi absensi dan biaya lembur?
- Bagaimana prioritas pelatihan berdasarkan kinerja?

Ms. Phali mengambil agregat sesuai filter aktif. Pertanyaan keputusan diarahkan pada temuan, prioritas, opsi tindakan/risiko dan data yang perlu diverifikasi. Jawaban AI perlu diverifikasi dan keputusan akhir tetap pada manusia. Pertanyaan tidak memakai konteks pesan sebelumnya; sebutkan topik yang ingin dianalisis pada tiap pertanyaan. Jangan memasukkan data pribadi karyawan.

## Data karyawan

Admin SDM dan Staf HR dapat membuka Manajemen Data untuk menambah, mengubah atau menghapus karyawan. Penghapusan juga menghapus catatan terkait setelah konfirmasi. Untuk impor, unduh Template CSV, isi kolom, lalu pilih berkas. Tanggal memakai YYYY-MM-DD; gender Perempuan/Laki-laki; status aktif/keluar; gaji berupa angka tanpa pemisah ribuan. Bila status keluar, tanggal keluar wajib diisi.

Sistem menampilkan kesalahan per baris dan menyediakan unduhan laporannya. Seluruh impor dibatalkan bila ada baris salah. Perbaiki berkas lalu unggah lagi. Impor menambahkan karyawan baru, bukan memperbarui baris lama.

## Perusahaan dan logo

Admin SDM membuka Pengaturan → Organisasi / perusahaan. Isi identitas dan kontak, pilih zona waktu, lalu unggah logo PNG/JPG/WebP maksimal 2 MB. Tekan Simpan pengaturan perusahaan. Untuk menghapus logo, pilih Hapus gambar lalu simpan. Logo perusahaan muncul terpisah dari logo aplikasi PHALI AI-HRIS.

Satu instalasi mewakili satu organisasi. Mengganti nama perusahaan tidak membuat tenant baru atau memisahkan data perusahaan lain.

## Peran dan audit

Pengaturan → Pengguna & peran tersedia bagi Admin SDM. Pilih peran akun lain dan simpan. Akun harus sudah terdaftar pada Supabase Auth. Peran sendiri tidak dapat diubah melalui aplikasi.

- Admin SDM: analitik, AI, data HR, perusahaan/logo, peran dan audit.
- Staf HR: analitik, AI dan pengelolaan data HR.
- Manajer: analitik dan AI; tanpa perubahan data HR.
- Pengamat: analitik, CSV dan cetak; tanpa AI/perubahan data HR.

Semua peran boleh mengubah nama dan foto profil sendiri. Log Audit hanya dapat dibuka Admin SDM dan menampilkan 200 aktivitas terbaru.

## Foto profil

Buka Profil saya, ubah nama atau pilih gambar PNG/JPG/WebP maksimal 2 MB, kemudian Simpan profil. Foto akan tampil pada header. Hapus gambar baru berlaku setelah disimpan. Pengguna tidak dapat mengganti foto milik akun lain. Avatar Ms. Phali merupakan aset asisten dan tidak ikut berubah.

## Install dan luring

Pada browser pendukung, gunakan Install aplikasi atau menu instalasi browser. Pada Safari iPhone gunakan Bagikan → Tambah ke Layar Utama. Instalasi memerlukan HTTPS dan konfigurasi deployment yang valid.

Buka dashboard secara daring terlebih dahulu agar ringkasan tersimpan. Ketika luring, hanya kombinasi modul/filter yang sudah disimpan yang dapat ditampilkan. Data berlabel waktu simpan; AI dan penyimpanan perubahan memerlukan internet. Logo/foto pribadi dari Storage dapat tidak tampil luring. Aset aplikasi dan avatar Ms. Phali diprecache. Logout menghapus ringkasan agregat tersimpan pada perangkat.

Saat muncul Versi baru tersedia, pilih Perbarui aplikasi. Ikon PWA yang sudah terpasang dapat memerlukan pemasangan ulang jika browser belum memperbaruinya.
