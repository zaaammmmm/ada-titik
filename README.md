# 📍 Ada Titik

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Status](https://img.shields.io/badge/status-In%20Development-orange)](https://github.com/zaaammmmm/ada-titik)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter%203.x-02569B?logo=flutter)](https://flutter.dev/)
[![Backend](https://img.shields.io/badge/Backend-Node.js%20%2F%20Express-339933?logo=node.js)](https://nodejs.org/)
[![Database](https://img.shields.io/badge/Database-PostgreSQL%20%2B%20Supabase-3ECF8E?logo=supabase)](https://supabase.com/)
[![Maps](https://img.shields.io/badge/Maps-Google%20Maps%20Platform-4285F4?logo=google-maps)](https://developers.google.com/maps)

</div>

> **"Bantuan tepat, sampai ke yang membutuhkan."**
>
> *"Kebaikan itu ada, tinggal kita temukan titiknya."*

---

## 🎯 Tentang Projek

**ada titik** adalah aplikasi *social donation mapping* berbasis lokasi yang bertujuan untuk menjembatani **donatur** dan **komunitas penyalur bantuan** secara transparan, akurat, dan efisien.

Berbeda dengan platform donasi konvensional, aplikasi ini tidak hanya menghubungkan pemberi dan penerima bantuan, tetapi menghadirkan **sistem berbasis peta interaktif (map-based system)** yang memungkinkan distribusi bantuan dilakukan secara **tepat sasaran** — hingga ke tingkat kelurahan.

### 🔍 Latar Belakang

Dalam praktik di masyarakat, terdapat beberapa permasalahan utama dalam ekosistem donasi:

| Masalah | Dampak |
|---|---|
| ❗ **Information Asymmetry** | Donatur tidak mengetahui lokasi kebutuhan bantuan terdekat |
| ❗ **Logistics Mismatch** | Bantuan menumpuk di lembaga besar, wilayah kecil terabaikan |
| ❗ **Kurangnya Validasi** | Banyak permintaan bantuan tidak jelas atau fiktif |
| ❗ **Minim Transparansi** | Donatur tidak tahu apakah bantuan benar-benar sampai |

**ada titik** hadir sebagai jawaban atas permasalahan tersebut dengan menggabungkan teknologi *Location-Based Service* (LBS), geo-fencing, dan sistem dokumentasi untuk membangun ekosistem donasi yang terukur dan berdampak nyata.

---

## ✨ Fitur Utama

<table>
<tr>
<td width="50%">

### 👤 Untuk Donatur
- 🗺️ **Peta Interaktif** — lihat titik bantuan secara real-time
- 📡 **Smart Notification** — notifikasi bantuan dalam radius tertentu
- 🔍 **Filter & Search** — berdasarkan jarak, kategori, dan urgensi
- 📸 **Transparansi** — lihat dokumentasi distribusi bantuan
- ⭐ **Rating System** — beri penilaian kepada komunitas
- 🚨 **Sistem Pelaporan** — laporkan bantuan yang tidak valid

</td>
<td width="50%">

### 🏘 Untuk Komunitas
- 📝 **Buat Permintaan Bantuan** dengan form yang lengkap
- 📍 **Tentukan Lokasi & Urgensi** secara presisi
- 💬 **Chat Real-time** dengan donatur
- 📊 **Dashboard** untuk kelola semua permintaan aktif
- 📸 **Upload Dokumentasi** bukti distribusi bantuan
- 🔄 **Update Status** bantuan secara transparan

</td>
</tr>
</table>

<table>
<tr>
<td width="50%">

### 👨‍💼 Untuk Admin
- 🎛️ **Dashboard Admin** yang komprehensif
- 📋 **Manajemen Laporan** dengan sistem verifikasi
- 🔒 **Moderasi Konten** dan validasi data
- 📈 **Analytics** untuk monitoring distribusi bantuan

</td>
<td width="50%">

### 🔐 Fitur Keamanan
- 📏 **Geo-Fencing Validation** — validasi lokasi distribusi ≤ 100 meter
- 🔐 **JWT Authentication** — multi-layer token security
- 🛡️ **Anti-Fraud System** — kombinasi geo-fencing & pelaporan
- 🔒 **Enkripsi Data** — keamanan data pengguna

</td>
</tr>
</table>

### 🗺️ Map-Based Donation System

Titik bantuan ditampilkan dalam peta dengan warna berdasarkan urgensi:

```
🔴 Mendesak    →  Perlu segera ditangani
🟡 Normal      →  Masih dalam batas wajar
🟢 Rendah      →  Tidak mendesak
```

### 🔄 Status Tracking System

```
📝 Open Request  →  🔄 On Progress  →  ✅ Completed
```

| Status | Deskripsi |
|---|---|
| **Open Request** | Menunggu bantuan dari donatur |
| **On Progress** | Sedang diproses dan disalurkan |
| **Completed** | Bantuan berhasil didistribusikan |

---

## 🧩 Fitur Berdasarkan Role

### 👤 Donatur
- Melihat peta bantuan real-time
- Mencari bantuan terdekat berdasarkan lokasi GPS
- Melihat detail dan urgensi permintaan bantuan
- Menyalurkan bantuan dan memantau status
- Memberikan rating kepada komunitas
- Melaporkan bantuan yang mencurigakan

### 🏘 Komunitas
- Membuat permintaan bantuan dengan lokasi presisi
- Menentukan tingkat urgensi dan kategori bantuan
- Menerima dan mengelola bantuan dari donatur
- Mendistribusikan bantuan ke penerima target
- Upload dokumentasi foto sebagai bukti distribusi
- Update status bantuan secara berkala

### 🛠 Admin
- Memverifikasi laporan dari donatur
- Moderasi sistem dan konten
- Menghapus atau menonaktifkan data tidak valid
- Memantau analytics distribusi bantuan

---

## 🛠️ Teknologi

### Frontend (Mobile)

| Library | Versi | Fungsi |
|---|---|---|
| **Flutter** | 3.x (Dart ≥3.0) | UI Framework cross-platform |
| **flutter_riverpod** | ^2.5.1 | State Management |
| **go_router** | ^13.2.0 | Navigasi & Routing |
| **dio** | ^5.7.0 | HTTP Client & Networking |
| **flutter_map** | ^6.1.0 | Peta interaktif berbasis OpenStreetMap |
| **geolocator** | ^11.0.0 | Layanan lokasi GPS |
| **supabase_flutter** | ^2.8.3 | Real-time & Auth client |
| **flutter_local_notifications** | ^17.2.3 | Notifikasi lokal |
| **image_picker** | ^1.2.2 | Upload foto dokumentasi |
| **google_fonts** | ^6.1.0 | Tipografi aplikasi |

### Backend

| Layer | Teknologi | Versi | Fungsi |
|---|---|---|---|
| **Runtime** | Node.js | 18+ | JavaScript runtime |
| **Framework** | Express.js | ^5.2.1 | REST API server |
| **Database** | PostgreSQL | Latest | Database utama |
| **Realtime & Auth** | Supabase | Latest | Realtime, Auth & Storage |
| **Authentication** | JWT (jsonwebtoken) | ^9.0.3 | Token-based auth |
| **File Upload** | Multer | ^2.1.1 | Upload gambar dokumentasi |
| **Validation** | express-validator | ^7.3.2 | Request validation |
| **Rate Limiting** | express-rate-limit | ^8.3.2 | Proteksi API |
| **Containerization** | Docker + Nginx | — | Deployment & reverse proxy |

---

## 👥 Tim Pengembang

<table>
<tr>
<td align="center" width="25%">
<b>Ahmad Zamroni Trikarta</b><br>
<i>Project Manager</i><br>
<i>Fullstack Developer</i>
<a href="https://github.com/zaaammmmm">@zaaammmmm</a>
</td>
<td align="center" width="25%">
<b>Agung Nugraha</b><br>
<i>Backend Developer</i><br>
<i>Database Architect</i><br>
<a href="https://github.com/NUGRAHA18">@NUGRAHA18</a>
</td>
<td align="center" width="25%">
<b>Ibnu Zaki</b><br>
<i>Frontend Developer</i><br>
<i>UI Implementation</i>
<a href="https://github.com/zakiibnu723">@zakiibnu723</a>
</td>
<td align="center" width="25%">
<b>Ahmad Mustofa Aslam</b><br>
<i>UI/UX Designer</i><br>
<i>Tester</i>
<a href="https://github.com/musthofaaslam">@musthofaaslam</a>
</td>
</tr>
</table>

**Kelompok 4 — Informatika, UIN Sunan Kalijaga Yogyakarta**

### 📋 Pembagian Tugas

| Role | Tanggung Jawab |
|---|---|
| **📱 Frontend Developer** | UI Implementation, Flutter screens, State management, Maps integration |
| **⚙️ Backend Developer** | REST API, Database design, Authentication, Real-time features |
| **🗄️ Database Architect** | Schema design, Migration management, Query optimization |
| **🔌 API Engineer** | Endpoint development, Dokumentasi API, Integration testing |

---

## 🚀 Getting Started

### 📋 Prasyarat

Pastikan Anda telah menginstal:

**Untuk Frontend (Mobile):**
- **Flutter SDK** (Dart ≥ 3.0.0)
- **Android Studio** atau **VS Code** dengan Flutter extension
- Emulator atau perangkat fisik yang sudah terhubung

**Untuk Backend:**
- **Node.js** (v18 atau lebih baru)
- **npm** atau **yarn**
- **PostgreSQL** (v14+) atau akses ke Supabase project
- **Docker** & **Docker Compose** (opsional, untuk deployment)
- **Git**

---

### 🔧 Instalasi — Frontend (Flutter)

1. **Clone Repository**
   ```bash
   # Main branch
   git clone https://github.com/zaaammmmm/ada-titik.git

   # Development branch
   git clone -b development https://github.com/zaaammmmm/ada-titik.git

   cd ada-titik
   ```

2. **Install Dependensi**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

---

## 🗂️ Struktur Projek

### Frontend (Flutter)

```
ada_titik/
├── 📁 lib/
│   ├── 📁 core/
│   │   ├── 📁 constants/        # Warna, teks, konfigurasi app
│   │   ├── 📁 network/          # API client & auth storage
│   │   ├── 📁 providers/        # Auth & state providers
│   │   ├── 📁 router/           # Konfigurasi navigasi (go_router)
│   │   ├── 📁 services/         # Location, notification, realtime
│   │   └── 📁 theme/            # App theme
│   └── 📁 features/
│       ├── 📁 admin/            # Layar & data admin
│       ├── 📁 auth/             # Login, register, reset password
│       ├── 📁 chat/             # Chat real-time
│       ├── 📁 community/        # Feed komunitas & komentar
│       ├── 📁 donation/         # Inti donasi & peta titik
│       ├── 📁 home/             # Dashboard utama
│       ├── 📁 maps/             # Layar peta interaktif
│       ├── 📁 news/             # Berita & informasi
│       └── 📁 notification/     # Notifikasi
├── 📁 assets/
│   ├── 📁 images/
│   └── 📁 icons/
└── 📄 pubspec.yaml
```

---

## 🔄 Alur Utama Sistem

```
1. 🏘  Komunitas membuat permintaan bantuan + set lokasi & urgensi
        ↓
2. 📡  Sistem broadcast notifikasi ke donatur dalam radius terdekat
        ↓
3. 👤  Donatur menerima notifikasi & memilih permintaan bantuan
        ↓
4. 💬  Donatur & Komunitas koordinasi via chat real-time
        ↓
5. 🚗  Donatur berangkat → sistem catat waktu keberangkatan
        ↓
6. 🤝  Donatur menyerahkan bantuan ke Komunitas
        ↓
7. 📏  Sistem validasi lokasi distribusi via Geo-Fencing (≤ 100 m)
        ↓
8. 📸  Komunitas upload foto dokumentasi distribusi ke penerima target
        ↓
9. ✅  Status → Completed | Donatur dapat +50 poin
        ↓
10. ⭐  Donatur memberikan rating kepada Komunitas
```

---

## 🔒 Keamanan & Validasi

> ⚠️ **PENTING**: Platform ini menangani data lokasi dan transaksi bantuan sensitif. Keamanan dan akurasi adalah prioritas utama.

### 🛡️ Fitur Keamanan

- 🔐 **JWT Multi-layer** — autentikasi berbasis token yang aman
- 📏 **Geo-Fencing (≤ 100 m)** — validasi lokasi distribusi bantuan secara GPS
- ⚡ **Rate Limiting** — proteksi dari serangan brute-force pada API
- 🔒 **Role-Based Access Control** — hak akses berbeda per tipe pengguna
- 🔑 **Password Reset** — sistem token SHA-256 dengan TTL 60 menit
- 🚫 **Anti-Enumeration** — endpoint forgot password tidak mengekspos keberadaan akun
- 📝 **Request Validation** — validasi input ketat di setiap endpoint

### 🔐 Kontrol Akses

| User Type | Permissions |
|---|---|
| **Donatur** | ✅ Lihat peta, salurkan bantuan, rating, laporan |
| **Komunitas** | ✅ Buat permintaan, kelola donasi, upload dokumentasi, chat |
| **Admin** | ✅ Verifikasi laporan, moderasi konten, manajemen data |

---

## 📈 Versi & Changelog

### v3.3 — 2026-05-31
- ✅ Upload gambar untuk community post (`POST /api/community/posts/image`)
- ✅ Forgot/Reset password end-to-end (token SHA-256, TTL 60 menit)
- ✅ Realtime `community_posts` & `donation_points` via Supabase publication

### v3.2 — 2026-05-29
- ✅ Tabel `donation_participants` + 7 endpoint alur donasi baru
- ✅ Auto-urgency, geo-fencing 100 m, +50 poin per complete
- ✅ Sistem notifikasi event-driven (7 tipe: departed, accepted, completed, dll.)
- ✅ Chat real-time via Supabase Realtime

### v3.1 — 2026-05-28
- ✅ 3 endpoint `Me` untuk `UserActivityScreen` Flutter
- ✅ Daftar postingan, likes, dan komentar user berbasis token

---

## 📌 Potensi Pengembangan

- 🗺️ **Heatmap** distribusi bantuan per wilayah
- 🤖 **AI Rekomendasi** lokasi bantuan prioritas
- 💳 **Integrasi Pembayaran Digital** untuk donasi non-fisik
- 🏆 **Sistem Reputasi Lanjutan** bagi komunitas terpercaya
- 📊 **Dashboard Analitik Admin** yang lebih komprehensif

---

## 💡 Catatan Pengembangan

- Gunakan `flutter pub get` setiap kali ada perubahan pada `pubspec.yaml`
- Jalankan `flutter clean` terlebih dahulu jika terjadi kendala pada cache
- Pastikan koneksi internet stabil saat mengunduh dependensi
- Setiap migrasi database bersifat **idempotent** — aman dijalankan ulang
- Untuk detail lengkap API, lihat `documentations/API_DOCUMENTATION.md`

---

## 📄 Lisensi

Projek ini dilisensikan di bawah **MIT License**.

```
MIT License

Copyright (c) 2026 Ada Titik Team — Kelompok 4 Informatika
UIN Sunan Kalijaga Yogyakarta
```

---

<div align="center">

**ada titik?** — *Tidak hanya mempermudah memberi, tetapi memastikan setiap bantuan sampai ke tempat yang tepat.* 📍

</div>
