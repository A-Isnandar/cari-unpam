# CariUnpam 🔍🎓

CariUnpam adalah aplikasi platform komunitas kampus (mirip forum/sosmed) berbasis seluler yang dirancang khusus untuk memfasilitasi mahasiswa Universitas Pamulang (UNPAM) dalam menemukan barang yang hilang, melaporkan temuan barang, serta berdiskusi seputar kejadian di sekitar kampus.

Fitur unggulan dari aplikasi ini adalah sistem pelaporan kehilangan (Lost & Found) yang interaktif, dilengkapi dengan **Sistem Verifikasi (Thread/Komentar)** yang memungkinkan pengguna lain merespons dengan mengunggah foto bukti kecocokan barang.

---

## 🚀 Fitur Utama

- **Autentikasi Aman:** Login dan Register menggunakan Firebase Authentication.
- **Lost & Found Feed:** Beranda interaktif untuk melihat daftar barang hilang, barang ditemukan, dan informasi lainnya.
- **Sistem Verifikasi (Thread):** Kolom interaktif di setiap postingan untuk membalas/memverifikasi dengan bukti foto.
- **Unggah Gambar Anti-Blokir:** Terintegrasi dengan API ImgBB untuk penyimpanan gambar dengan *proxy caching* (`wsrv.nl`) untuk mem-bypass pemblokiran ISP lokal (Internet Baik).
- **Full-Screen Image Viewer:** Fitur *zoom in/out* gambar interaktif ala sosial media populer.
- **Sistem Status & Reward:** Melacak status penyelesaian ("DICARI", "DITEMUKAN", "HILANG") dan menampilkan hadiah (*reward*) untuk penemu barang.

---

## 🛠️ Tech Stack & Arsitektur

Proyek ini dibangun menggunakan teknologi modern dengan arsitektur yang modular:

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend & Database:** 
    *   [Cloud Firestore](https://firebase.google.com/docs/firestore) (NoSQL Database Realtime)
    *   [Firebase Authentication](https://firebase.google.com/docs/auth) (Manajemen Pengguna)
*   **Media Storage:** [ImgBB API](https://api.imgbb.com/) (Penyimpanan gambar gratis) via REST API.
*   **Proxy Caching:** `wsrv.nl` (Bypass Cloudflare/ISP block untuk memuat gambar).
*   **State Management:** `StatefulWidget` & Flutter Hooks/Core logic.

### Struktur Data (Firestore)
- `users`: Menyimpan profil pengguna (UID, email, nama).
- `posts`: Menyimpan detail postingan utama (judul, deskripsi, foto, lokasi, status).
  - `verifications` (Sub-collection): Menyimpan utas balasan/bukti kecocokan dari pengguna lain di dalam setiap postingan.

---

## 💻 Cara Instalasi & Menjalankan (Development)

Ikuti langkah-langkah di bawah ini untuk menjalankan *source code* aplikasi ini di perangkat Anda.

### Prasyarat
1. Pastikan Anda sudah menginstal [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Pastikan Anda memiliki perangkat Android fisik atau Android Emulator yang sudah berjalan.
3. Hubungkan akun Firebase ke project ini (Pastikan `google-services.json` sudah ada di folder `android/app/`).

### Langkah-langkah

1. **Kloning atau Buka Repository**
   Buka folder proyek ini di terminal/IDE Anda (VS Code / Android Studio).
   ```bash
   cd d:/src/cariunpam
   ```

2. **Unduh Dependencies (Package)**
   Jalankan perintah ini untuk mengunduh semua pustaka (library) yang dibutuhkan:
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi (Mode Debug)**
   Untuk menjalankan aplikasi dengan fitur *Hot Reload* (cocok untuk modifikasi kodingan):
   ```bash
   flutter run
   ```

---

## 📦 Cara Membangun (Build) File APK

Jika Anda ingin membuat file APK mandiri (tanpa perlu disambungkan ke komputer) untuk dibagikan ke teman atau diinstal secara permanen:

1. **Buka terminal dan jalankan:**
   ```bash
   flutter build apk --release
   ```

2. **Ambil file APK Anda:**
   Setelah proses memakan waktu beberapa menit (tahap minifikasi ProGuard/R8), file *installer* Android akan muncul di:
   `build/app/outputs/flutter-apk/app-release.apk`

*Catatan: APK versi `--release` ini berukuran jauh lebih kecil, berjalan 3x lebih cepat (karena kompilasi AOT), dan kompatibel dengan semua jenis prosesor HP Android masa kini.*
