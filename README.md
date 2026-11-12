# Klarwave Music

Pemutar musik mobile dengan desain **liquid glass**, gratis, tanpa iklan, dan tanpa akun.
Dibangun dengan **Flutter/Dart** — satu codebase untuk Android dan iOS, dikompilasi AOT
(tanpa JavaScript bridge) sehingga cepat dan ringan.

> Nama "Klarwave Music" sudah dipakai di kode, label aplikasi, dan CI. Tetap lakukan
> pengecekan merek di bagian [Nama & merek](#nama--merek) sebelum publikasi.

## Fitur

- **Beranda** — tangga lagu trending (minggu/bulan/sepanjang masa), riwayat putar, radio langsung.
- **Cari** — satu pencarian menggabungkan Audius, Internet Archive, Openverse, dan ccMixter,
  dengan filter per sumber; stasiun radio dari Radio Browser; filter genre dan arsip Indonesia.
- **Pemutar penuh** — artwork besar, kontrol play/pause, prev/next, shuffle, repeat (semua/1 lagu),
  seek, antrean, dan **timer tidur**.
- **Lirik tersinkronisasi** — diambil dari LRCLIB, auto-scroll dan highlight baris aktif.
- **Koleksi** — lagu disukai, playlist buatan sendiri, dan riwayat; semua tersimpan lokal.
- **Audio latar** — notifikasi media & kontrol kunci layar (audio_service/just_audio).
- **Antrean & lanjut otomatis** — lagu berlanjut sendiri, dengan acak dan ulang.
- **Desain** — latar aurora animasi, panel kaca (blur + border specular), navigasi kaca mengapung.

## Sumber musik (legal)

Aplikasi ini **bukan** klien Spotify/YouTube Music. Katalog Spotify/YouTube tidak boleh
distribusikan ulang; proyek ini memakai sumber yang memang bebas dan legal:

| Kebutuhan | Sumber | Catatan |
| --- | --- | --- |
| Musik on-demand | [Audius API](https://docs.audius.org) | Streaming gratis, tanpa API key |
| Arsip audio | [Internet Archive](https://archive.org/developers/) | Domain publik & CC, tanpa API key |
| Audio CC | [Openverse](https://api.openverse.org/v1/) | Mengindeks Jamendo, Wikimedia, Freesound; tanpa API key |
| Remix CC | [ccMixter](https://ccmixter.org/query-api) | Komunitas remix Creative Commons |
| Radio internet | [Radio Browser](https://www.radio-browser.info) | Direktori stasiun publik |
| Lirik | [LRCLIB](https://lrclib.net) | Database lirik komunitas, tanpa API key |

Atribusi: Openverse mewajibkan kredit pembuat dan lisensi; aplikasi menampilkannya di
menu **Sumber & lisensi** setiap lagu dan menautkan halaman asal. Sebutkan juga bahwa
data pencarian berasal dari Openverse. Hak cipta lirik dan rekaman tetap milik
pemiliknya masing-masing; jangan menambahkan sumber yang melanggar ketentuan layanan
pihak ketiga.

### Cakupan katalog dan target 95%

Kombinasi sumber gratis ini memperluas katalog, tetapi **tidak bisa mencapai 95% lagu
Indonesia mainstream**. Lagu milik label besar tidak tersedia di Audius, Internet
Archive, Openverse, maupun ccMixter. Perkiraan realistis:

- Audius + arsip + Openverse + ccMixter: sebagian kecil katalog Indonesia modern,
  lebih kuat untuk indie, elektronik, remix, lagu daerah, keroncong, dan rekaman lawas.
- Radio Browser: banyak stasiun Indonesia, tetapi hanya siaran langsung.
- Impor musik lokal: satu-satunya cara mendekati 95% untuk koleksi pribadi pengguna.

Untuk katalog label yang lengkap diperlukan lisensi komersial (mis. penyedia B2B)
atau integrasi langganan pengguna; keduanya di luar cakupan aplikasi gratis ini.

## Menjalankan di lokal

Prasyarat: Flutter SDK (stable), Android SDK untuk Android, Xcode untuk iOS.

```powershell
# 1. Buat folder android/ dan ios/ (hanya sekali, atau setelah upgrade Flutter)
.\tool\setup.ps1        # Windows PowerShell
# bash tool/setup.sh     # macOS / Linux

# 2. Ambil dependensi
flutter pub get

# 3. Jalankan ke perangkat/emulator (hot reload aktif)
flutter run
```

Folder `android/` dan `ios/` sengaja tidak di-commit (lihat `.gitignore`).
Kustomisasi native yang penting disimpan di `platform_overrides/` dan disalin oleh
skrip setup, sehingga build lokal dan CI selalu identik.

### Build rilis manual

```powershell
flutter build apk --release              # universal
flutter build apk --release --split-per-abi
flutter build appbundle --release
flutter build ios --release              # butuh signing Apple
```

APK release dari template memakai *debug key* supaya bisa langsung dipasang untuk pengujian.
Untuk Play Store, tambahkan keystore sendiri lalu konfigurasi `signingConfigs` di
`android/app/build.gradle.kts`.

## Release otomatis di GitHub

Workflow `.github/workflows/release.yml` menjalankan:

1. `tool/setup.sh` → generate folder native,
2. `flutter pub get`,
3. build APK universal, APK per-ABI, dan AAB,
4. upload artifact, dan
5. publish GitHub Release saat ref berupa tag `v*`.

Langkah rilis:

```bash
git init
git add .
git commit -m "feat: Klarwave Music 1.1.0"
git branch -M main
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main

git tag v1.1.0
git push origin v1.1.0
```

Job iOS hanya berjalan lewat **Run workflow** (manual) dan menghasilkan
`Runner.app` *unsigned*; memasang di iPhone tetap memerlukan sertifikat Apple.
Butuh custom signing? Tambahkan secret lalu sesuaikan langkah build.

## Struktur

```
lib/
  main.dart                  bootstrap, tema, audio background
  src/
    models.dart              Track, LyricLine
    providers.dart           Riverpod providers
    player/controller.dart   mesin pemutar (just_audio) + sleep timer
    services/                Audius, Radio Browser, LRCLIB, penyimpanan lokal
    ui/                      kit liquid glass, layar, sheet, lirik
platform_overrides/          manifest/perizinan native yang wajib
tool/setup.sh|ps1            generator folder android/ios
.github/workflows/release.yml
```

## Privasi

Tanpa akun, tanpa analytics, tanpa iklan. Data (disukai, playlist, riwayat) hanya
tersimpan di perangkat lewat `shared_preferences`.

## Nama & merek

Nama yang dipakai: **Klarwave Music** — gabungan "klar" (jernih, seperti kaca) dan
"wave" (gelombang suara), terdengar internasional tetapi tetap mudah dieja di Indonesia.

Tidak ada nama yang bisa dijamin "bebas copyright" tanpa pencarian merek resmi, jadi
lakukan checklist ini sebelum publikasi:

1. Cari nama persis di **PDKI/DJKI** (Indonesia, kelas 9 & 41), **USPTO TESS**, **EUIPO eSearch**.
2. Cek Play Store, App Store, GitHub, domain `.com`/`.id`, serta handle Instagram/TikTok/X.
3. Lakukan pencarian Google dengan tanda kutip untuk benturan merek.
4. Jika "Klarwave" bentrok, pakai varian distingtif (mis. "Klarwave Audio") daripada
   nama generik.

Identitas teknis yang terpasang:

| Bagian | Nilai |
| --- | --- |
| Dart package | `klarwave` (`pubspec.yaml`) |
| Android applicationId / iOS bundle id | `com.klarwave.music` |
| Label Android / iOS | `Klarwave Music` |
| Notification channel | `com.klarwave.music.audio` |

Mengganti nama lagi berarti mengganti `name` di `pubspec.yaml`, label Android/iOS,
`applicationId`/bundle id di `tool/setup.sh`/`setup.ps1`, folder Kotlin
(`platform_overrides/android/app/src/main/kotlin/com/klarwave/music/`), dan string
`klarwave.*` di `AppStore`.

## Keterbatasan

- Katalog bergantung pada ketersediaan API Audius, Internet Archive, Openverse, ccMixter,
  dan Radio Browser; sumber yang gagal diabaikan dan sumber lain tetap tampil.
- Openverse anonim dibatasi 20 permintaan/menit dan 200/hari; hasil di-cache 10 menit.
  Untuk pemakaian berat, daftarkan token Openverse dan tambahkan header `Authorization`.
- Kualitas dan ketersediaan stream arsip bervariasi; sebagian rekaman lama mono atau
  memiliki metadata tidak lengkap.
- Lirik tidak tersedia untuk semua lagu (LRCLIB berbasis kontribusi).
- Radio umumnya siaran langsung: seek tidak tersedia.
- Artwork notifikasi mengikuti URL artwork dari sumber.
