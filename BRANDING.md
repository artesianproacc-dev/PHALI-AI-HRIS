# Identitas PHALI AI-HRIS

- Nama produk: **PHALI AI-HRIS**; dibaca *fa-li*.
- Asisten: **Ms. Phali — HRD Assistant**.
- Logo lengkap: simbol SDM dan grafik, tulisan **Phali** di bawah simbol, kemudian **AI-HRIS** sebagai keterangan kecil.
- Palet: hijau hutan `#123c38`, teal `#258c79`, mint `#b8efcf`, latar `#f4f7f6`.

## Aset yang disertakan

| Berkas | Penggunaan |
| --- | --- |
| `public/branding/phali-logo.png` | Logo lengkap transparan; halaman masuk dan sidebar |
| `public/branding/phali-symbol.png` | Simbol transparan; sumber ikon instalasi PWA |
| `public/branding/ms-phali.png` | Avatar transparan; pembuka chat, pesan asisten dan kartu narasi |
| `public/icon-192.png` | Ikon aplikasi/favikon 192 piksel |
| `public/icon-512.png` | Ikon instalasi 512 piksel |
| `public/maskable-512.png` | Ikon adaptif berlatar terang |

Logo aplikasi berbeda dari logo organisasi yang diunggah melalui Pengaturan. Avatar Ms. Phali juga berbeda dari foto profil pengguna. Aset branding adalah aset produk statis, sedangkan logo perusahaan dan foto pengguna tetap tersimpan privat di Supabase Storage.

## Pembuatan dan pemakaian

Logo dan avatar dibuat dengan fitur image generation bawaan. PNG transparan asli disertakan; tampilan bulat avatar dilakukan melalui CSS. Skrip `npm run icons` menurunkan ikon PNG dari simbol; tidak menimpa logo lengkap atau avatar asli.

Prompt avatar yang digunakan:

> Create one polished standalone character avatar for Ms. Phali (HRD Assistant), a friendly professional female AI human-resources assistant for the Indonesian HR Insight analytics application. Premium soft 3D editorial illustration, approachable adult woman, warm medium skin, dark brown shoulder-length tidy hair, subtle round glasses, kind confident smile, deep forest-green blazer over ivory blouse, small modern understated earpiece. Head and shoulders centered with generous safe margin for circular UI cropping. Sophisticated forest green #123c38, teal #258c79 and mint palette, soft studio light, clear recognizable face at small sizes. True transparent background. No lettering, no watermark, no extra objects, no frame. Single avatar only, square composition.

Prompt perubahan logo akhir (image generation bawaan):

> Change ONLY the main text on this logo from 'Phali' to 'PHALI', ALL UPPERCASE CAPITAL LETTERS. Exact spelling: P H A L I, rendered PHALI. No final A. Preserve the emblem of green people and rising chart, all colors, transparent background, professional sans-serif typeface style, and overall vertical composition. Keep the smaller subtitle exactly AI-HRIS unchanged beneath the main name. Recenter and adjust kerning of PHALI for a balanced polished brand lockup. Two text lines exactly: PHALI / AI-HRIS. Do not add anything else. True transparent background.

Logo utama menggunakan huruf kapital PHALI. Nama asisten tetap Ms. Phali — HRD Assistant.
