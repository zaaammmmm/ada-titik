# Ada Titik — Dokumentasi API

> **ada titik?** · Social Donation Mapping Platform
> Backend: Node.js + Express 5 · Database: PostgreSQL + PostGIS · Storage: Supabase
> Kelompok 4 – Informatika, UIN Sunan Kalijaga Yogyakarta
> **Versi dokumen:** v3 (2026-05-25)

---

## Daftar Isi

1. [Gambaran Umum](#1-gambaran-umum)
2. [Base URL & Environment](#2-base-url--environment)
3. [Autentikasi](#3-autentikasi)
4. [Rate Limiting](#4-rate-limiting)
5. [Format Response](#5-format-response)
6. [Kode Status HTTP](#6-kode-status-http)
7. [Role & Hak Akses](#7-role--hak-akses)
8. [Auth — `/api/auth`](#8-auth--apiauth)
9. [Donations — `/api/donations`](#9-donations--apidonations)
10. [Documentation — `/api/documentation`](#10-documentation--apidocumentation)
11. [Ratings — `/api/ratings`](#11-ratings--apiratings)
12. [Reports — `/api/reports`](#12-reports--apireports)
13. [Admin — `/api/admin`](#13-admin--apiadmin)
14. [Analytics — `/api/analytics`](#14-analytics--apianalytics)
15. [Notifications — `/api/notifications`](#15-notifications--apinotifications)
16. [Users — `/api/users`](#16-users--apiusers)
17. [Community — `/api/community`](#17-community--apicommunity)
18. [Health Check](#18-health-check)
19. [Panduan Postman](#19-panduan-postman)
20. [Aturan Validasi Lengkap](#20-aturan-validasi-lengkap)
21. [Changelog v3](#21-changelog-v3)
22. [Ringkasan Endpoint](#22-ringkasan-endpoint)

---

## 1. Gambaran Umum

**Ada Titik** adalah platform *social donation mapping* berbasis lokasi. API ini menyediakan seluruh backend untuk mengelola titik bantuan, autentikasi pengguna, dokumentasi distribusi, sistem rating, pelaporan fraud, modul komunitas, dan moderasi admin.

### Arsitektur Singkat

```
Flutter App ──► Express API (Node.js) ──► PostgreSQL + PostGIS
                                     ──► Supabase Storage (foto avatar & dokumentasi)
                                     ──► JWT (autentikasi)
```

### Alur Utama

```
Komunitas membuat titik bantuan
    → Donatur melihat di peta & menyalurkan bantuan
    → Status: Open → On Progress → Completed (geo-fencing ≤100m)
    → Komunitas upload dokumentasi foto
    → Donatur memberi rating
    → Donatur bisa melaporkan jika mencurigakan
    → Admin memverifikasi laporan & moderasi
    → Komunitas berbagi update melalui modul Community
```

---

## 2. Base URL & Environment

| Environment | Base URL |
|---|---|
| Development | `http://localhost:3000` |
| Staging | Lihat konfigurasi `.env.staging` |
| Production | Set lewat Railway env |

### Variabel Environment yang Diperlukan

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://user:password@host:5432/titik_baik
JWT_SECRET=string_acak_panjang_dan_rumit
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
ALLOWED_ORIGINS=https://app.example.com,https://web.example.com
```

> `ALLOWED_ORIGINS` hanya diberlakukan saat `NODE_ENV=production`.

### Bucket Supabase Storage yang Dipakai

| Bucket | Public? | Dipakai oleh |
|---|:---:|---|
| `documentation` | ✅ | `POST /api/documentation` |
| `avatars` | ✅ | `POST /api/users/avatar` |

### Seed Akun Default (setelah `npm run seed`)

| Email | Password | Role |
|---|---|---|
| `admin@titikbaik.id` | `password123` | admin |
| `komunitas@example.com` | `password123` | komunitas |
| `donatur@example.com` | `password123` | donatur |

---

## 3. Autentikasi

API menggunakan **JWT (JSON Web Token)**. Token dikirimkan melalui header `Authorization`.

### Format Header

```
Authorization: Bearer <token>
```

### Payload JWT

```json
{
  "userId": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
  "role": "donatur",
  "iat": 1714000000,
  "exp": 1714086400
}
```

- **`userId`** bertipe UUID (bukan integer)
- **Masa berlaku:** 1 hari (24 jam)
- **Algoritma:** HS256
- Jika token kadaluarsa → `400 Bad Request`
- Jika token tidak valid → `400 Bad Request`
- Jika tidak ada header `Authorization` → `401 Unauthorized`

### Optional Auth

Beberapa endpoint (mis. `GET /api/community/posts`) mendukung **optional auth**: bisa diakses anonim, tetapi jika header `Authorization` valid dikirim, response akan diperkaya (mis. field `liked_by_me`).

---

## 4. Rate Limiting

| Konfigurasi | Nilai |
|---|---|
| Window | 15 menit |
| Maks request per IP | 100 request |
| Response jika melebihi | `429 Too Many Requests` |

---

## 5. Format Response

### Response Sukses

```json
{
  "message": "Deskripsi aksi",
  "data": { ... },
  "pagination": {
    "total": 50,
    "total_pages": 5,
    "current_page": 1,
    "limit": 10
  }
}
```

> `pagination` hanya muncul pada endpoint yang mendukung paginasi.

### Response Login/Register

```json
{
  "message": "Login berhasil",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "name": "Budi Santoso",
    "email": "budi@example.com",
    "role": "donatur"
  }
}
```

### Response Error

```json
{
  "error": "Pesan error singkat"
}
```

### Response Error Validasi (400)

```json
{
  "error": "Validasi gagal",
  "details": [
    { "field": "email", "message": "Format email tidak valid" },
    { "field": "password", "message": "Password minimal 8 karakter" }
  ]
}
```

---

## 6. Kode Status HTTP

| Kode | Arti | Kapan Muncul |
|---|---|---|
| `200 OK` | Sukses | GET, PATCH, DELETE berhasil |
| `201 Created` | Dibuat | POST berhasil membuat resource baru |
| `400 Bad Request` | Validasi gagal | Input tidak sesuai aturan validasi, token tidak valid/kadaluarsa |
| `401 Unauthorized` | Tidak terautentikasi | Header `Authorization` tidak ada |
| `403 Forbidden` | Tidak diizinkan | Role tidak punya akses, atau bukan pemilik resource |
| `404 Not Found` | Tidak ditemukan | Resource tidak ada atau sudah di-soft-delete |
| `409 Conflict` | Konflik data | Email sudah terdaftar, sudah pernah rating |
| `429 Too Many Requests` | Rate limit | Melebihi 100 request per 15 menit |
| `500 Internal Server Error` | Error server | Terjadi kesalahan di sisi server |
| `503 Service Unavailable` | DB tidak terhubung | Koneksi database gagal |

---

## 7. Role & Hak Akses

| Fitur | Publik | Donatur | Komunitas | Admin |
|---|:---:|:---:|:---:|:---:|
| Lihat daftar titik bantuan | ✅ | ✅ | ✅ | ✅ |
| Lihat detail titik bantuan | ✅ | ✅ | ✅ | ✅ |
| Lihat analytics & heatmap | ✅ | ✅ | ✅ | ✅ |
| Register & login | ✅ | ✅ | ✅ | ✅ |
| Lihat daftar community posts | ✅ | ✅ | ✅ | ✅ |
| Lihat komentar post | ✅ | ✅ | ✅ | ✅ |
| Lihat titik terdekat | — | ✅ | ✅ | ✅ |
| Memberi rating | — | ✅ | — | — |
| Melaporkan titik (fraud) | — | ✅ | — | — |
| Lihat profil & aktivitas | — | ✅ | ✅ | ✅ |
| Update profil | — | ✅ | ✅ | ✅ |
| Upload avatar | — | ✅ | ✅ | ✅ |
| Like / unlike post | — | ✅ | ✅ | ✅ |
| Komentar post | — | ✅ | ✅ | ✅ |
| Buat titik bantuan | — | — | ✅ | — |
| Edit titik bantuan | — | — | ✅ (milik sendiri) | — |
| Update status titik | — | ✅ | ✅ | — |
| Upload dokumentasi foto | — | — | ✅ | — |
| Buat community post | — | — | ✅ | — |
| Lihat semua laporan | — | — | — | ✅ |
| Update status laporan | — | — | — | ✅ |
| Hapus titik (soft delete) | — | — | — | ✅ |
| Statistik sistem (admin) | — | — | — | ✅ |

> **Catatan:** Untuk mengubah status titik ke `Completed`, hanya komunitas yang membuat titik tersebut dan berada dalam radius ≤100 meter yang diizinkan.

---

## 8. Auth — `/api/auth`

### 8.1 Register

Mendaftarkan akun pengguna baru.

```
POST /api/auth/register
```

**Autentikasi:** Tidak diperlukan

**Request Body:**

```json
{
  "name": "Budi Santoso",
  "email": "budi@example.com",
  "password": "password123",
  "role": "donatur"
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `name` | string | Ya | Maks 100 karakter |
| `email` | string | Ya | Format email valid |
| `password` | string | Ya | Min 8 karakter |
| `role` | string | Ya | Hanya `donatur` atau `komunitas` |

> **Catatan:** Role `admin` tidak bisa didaftarkan melalui endpoint ini.

**Response 201 Created:**

```json
{
  "message": "Registrasi berhasil",
  "userId": "a1f05293-3804-4175-8b34-ac72e1eaab5e"
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | Validasi gagal (field tidak valid) |
| `409` | Email sudah terdaftar |

---

### 8.2 Login

```
POST /api/auth/login
```

**Autentikasi:** Tidak diperlukan

**Request Body:**

```json
{
  "email": "budi@example.com",
  "password": "password123"
}
```

**Response 200 OK:**

```json
{
  "message": "Login berhasil",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "name": "Budi Santoso",
    "email": "budi@example.com",
    "role": "donatur"
  }
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `401` | Email tidak ditemukan atau password salah |

---

### 8.3 Cek Token (Verify Me)

```
GET /api/auth/me
```

**Autentikasi:** Bearer Token (semua role)

**Response 200 OK:**

```json
{
  "message": "Selamat datang di area aman!",
  "user": {
    "userId": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "role": "donatur",
    "iat": 1714000000,
    "exp": 1714086400
  }
}
```

---

## 9. Donations — `/api/donations`

> **Baru di v3:** field `category`, `goal_amount`, `collected_amount`, `author_name`, `author_avatar` di response. Filter `?category=` di list endpoint.

### 9.1 Lihat Semua Titik Bantuan

```
GET /api/donations
```

**Autentikasi:** Tidak diperlukan (publik)

**Query Parameters:**

| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `status` | string | `Open` | `Open` / `On Progress` / `Completed` |
| `urgency` | string | — | `Mendesak` / `Normal` / `Rendah` |
| `category` | string | — | `Pangan` / `Medis` / `Pendidikan` / `Infrastruktur` / `Pakaian` / `Lainnya` / `Umum` |
| `search` | string | — | Cari pada `title` dan `description` (case-insensitive) |
| `page` | integer | `1` | Nomor halaman |
| `limit` | integer | `10` | Jumlah per halaman (maks: 100) |

**Contoh Request:**

```
GET /api/donations?category=Pangan&urgency=Mendesak&search=banjir&page=1&limit=5
```

**Response 200 OK:**

```json
{
  "message": "Data titik bantuan berhasil diambil",
  "pagination": {
    "total": 50,
    "total_pages": 10,
    "current_page": 1,
    "limit": 5
  },
  "data": [
    {
      "id": 12,
      "title": "Bantuan Pangan Korban Banjir Code",
      "description": "Dibutuhkan beras, mie instan, dan air mineral untuk 50 KK.",
      "status": "Open",
      "urgency": "Mendesak",
      "category": "Pangan",
      "goal_amount": "5000000.00",
      "collected_amount": "0.00",
      "created_at": "2026-05-20T08:00:00.000Z",
      "longitude": 110.3695,
      "latitude": -7.7956,
      "author_name": "Komunitas Berbagi Jogja",
      "author_avatar": "https://your-project.supabase.co/storage/v1/object/public/avatars/.../avatar.png"
    }
  ]
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | Nilai `urgency`, `status`, atau `category` tidak valid |

---

### 9.2 Titik Bantuan Terdekat (Nearby)

Mencari titik bantuan berstatus `Open` dalam radius tertentu dari posisi user. Hasil diurutkan dari yang terdekat.

```
GET /api/donations/nearby
```

**Autentikasi:** Bearer Token (semua role)

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|---|---|:---:|---|
| `lat` | float | Ya | Latitude posisi user (-90 hingga 90) |
| `lng` | float | Ya | Longitude posisi user (-180 hingga 180) |
| `radius` | float | Ya | Radius pencarian dalam **meter** (> 0) |

**Response 200 OK:**

```json
{
  "message": "Menampilkan titik bantuan dalam radius 5000 meter",
  "count": 3,
  "data": [
    {
      "id": 3,
      "title": "Bantuan Air Bersih",
      "description": "...",
      "status": "Open",
      "urgency": "Normal",
      "category": "Pangan",
      "goal_amount": "2000000.00",
      "collected_amount": "0.00",
      "longitude": 110.371,
      "latitude": -7.797,
      "distance_meters": 234.5
    }
  ]
}
```

---

### 9.3 Detail Titik Bantuan

```
GET /api/donations/:id
```

**Autentikasi:** Tidak diperlukan (publik)

**Response 200 OK:**

```json
{
  "message": "Detail titik bantuan berhasil diambil",
  "data": {
    "id": 12,
    "title": "Bantuan Pangan Korban Banjir Code",
    "description": "Dibutuhkan beras, mie instan, dan air mineral untuk 50 KK.",
    "status": "Open",
    "urgency": "Mendesak",
    "category": "Pangan",
    "goal_amount": "5000000.00",
    "collected_amount": "0.00",
    "created_at": "2026-05-20T08:00:00.000Z",
    "created_by": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "longitude": 110.3695,
    "latitude": -7.7956,
    "creator_name": "Komunitas Berbagi Jogja",
    "creator_avatar": "https://your-project.supabase.co/storage/v1/object/public/avatars/.../avatar.png",
    "avg_rating": "4.5",
    "total_ratings": 8,
    "total_docs": 3
  }
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `404` | Titik tidak ditemukan atau sudah dihapus |

---

### 9.4 Buat Titik Bantuan

```
POST /api/donations
```

**Autentikasi:** Bearer Token (**komunitas** saja)

**Request Body:**

```json
{
  "title": "Bantuan Pangan Korban Banjir Code",
  "description": "Dibutuhkan beras, mie instan, dan air mineral untuk 50 KK.",
  "longitude": 110.3695,
  "latitude": -7.7956,
  "urgency": "Mendesak",
  "category": "Pangan",
  "goal_amount": 5000000
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `title` | string | Ya | Maks 200 karakter |
| `longitude` | float | Ya | -180 hingga 180 |
| `latitude` | float | Ya | -90 hingga 90 |
| `description` | string | Tidak | Teks bebas |
| `urgency` | string | Tidak | `Mendesak` / `Normal` / `Rendah` (default: `Normal`) |
| `category` | string | Tidak | Lihat daftar kategori (default: `Umum`) |
| `goal_amount` | number | Tidak | ≥ 0 (default: `0`) |

**Response 201 Created:**

```json
{
  "message": "Titik bantuan berhasil ditambahkan",
  "data": {
    "id": 15,
    "title": "Bantuan Pangan Korban Banjir Code",
    "status": "Open",
    "urgency": "Mendesak",
    "category": "Pangan",
    "goal_amount": "5000000.00"
  }
}
```

---

### 9.5 Edit Titik Bantuan

```
PATCH /api/donations/:id
```

**Autentikasi:** Bearer Token (**komunitas** — pemilik saja)

**Request Body** (minimal satu field wajib diisi):

```json
{
  "title": "Bantuan Pangan Korban Banjir Code (Update)",
  "urgency": "Normal",
  "category": "Pangan",
  "goal_amount": 7500000,
  "description": "Situasi sudah membaik, bantuan tetap diperlukan."
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `title` | string | Tidak | Maks 200 karakter |
| `urgency` | string | Tidak | `Mendesak` / `Normal` / `Rendah` |
| `category` | string | Tidak | Lihat daftar kategori |
| `goal_amount` | number | Tidak | ≥ 0 |
| `description` | string | Tidak | Teks bebas |

> Lokasi (`longitude`, `latitude`), `status`, dan `collected_amount` tidak dapat diubah melalui endpoint ini.

**Response 200 OK:**

```json
{
  "message": "Titik bantuan berhasil diperbarui",
  "data": {
    "id": 15,
    "title": "Bantuan Pangan Korban Banjir Code (Update)",
    "description": "Situasi sudah membaik...",
    "urgency": "Normal",
    "status": "Open",
    "category": "Pangan",
    "goal_amount": "7500000.00"
  }
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | Tidak ada field yang diisi |
| `403` | Bukan pemilik titik bantuan |
| `404` | Titik tidak ditemukan |

---

### 9.6 Update Status Titik Bantuan

| Transisi | Siapa | Syarat Tambahan |
|---|---|---|
| `Open` → `On Progress` | Semua donatur & komunitas | Tidak ada |
| `On Progress` → `Completed` | Komunitas **pembuat** saja | Harus berada dalam radius ≤100 meter |

```
PATCH /api/donations/:id/status
```

**Autentikasi:** Bearer Token (donatur atau komunitas)

**Request Body — Completed (dengan geo-fencing):**

```json
{
  "status": "Completed",
  "user_lat": -7.7956,
  "user_lng": 110.3695
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `status` | string | Ya | `On Progress` atau `Completed` |
| `user_lat` | float | Ya (untuk Completed) | -90 hingga 90 |
| `user_lng` | float | Ya (untuk Completed) | -180 hingga 180 |

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | Status tidak valid, atau `user_lat`/`user_lng` tidak disertakan untuk Completed |
| `403` | Bukan pembuat titik (untuk Completed), atau jarak > 100 meter |
| `404` | Titik tidak ditemukan |

---

## 10. Documentation — `/api/documentation`

### 10.1 Lihat Dokumentasi Titik

```
GET /api/documentation/:point_id
```

**Autentikasi:** Bearer Token (semua role)

**Response 200 OK:**

```json
{
  "message": "Dokumentasi berhasil diambil",
  "count": 3,
  "data": [
    {
      "id": 5,
      "point_id": 15,
      "photo_url": "https://your-project.supabase.co/storage/v1/object/public/documentation/15/1714000000-abc123.jpg",
      "caption": "Distribusi sembako hari pertama",
      "created_at": "2026-04-05T10:00:00.000Z"
    }
  ]
}
```

---

### 10.2 Upload Dokumentasi (Foto)

```
POST /api/documentation
```

**Autentikasi:** Bearer Token (**komunitas** saja)
**Content-Type:** `multipart/form-data`

**Form Fields:**

| Field | Tipe | Wajib | Keterangan |
|---|---|:---:|---|
| `point_id` | text | Ya | ID titik bantuan |
| `photo` | file | Ya | File gambar (`image/*`) — maks 5 MB |
| `caption` | text | Tidak | Keterangan foto |

**Response 201 Created:**

```json
{
  "message": "Dokumentasi berhasil diunggah",
  "data": {
    "id": 7,
    "point_id": 15,
    "photo_url": "https://your-project.supabase.co/storage/v1/object/public/documentation/15/1714000000-xyz456.jpg",
    "caption": "Distribusi sembako hari pertama"
  }
}
```

---

## 11. Ratings — `/api/ratings`

### 11.1 Lihat Rating Titik Bantuan

```
GET /api/ratings/:point_id
```

**Autentikasi:** Bearer Token (semua role)

### 11.2 Beri Rating

```
POST /api/ratings
```

**Autentikasi:** Bearer Token (**donatur** saja)

**Request Body:**

```json
{
  "point_id": 15,
  "score": 5,
  "review": "Bantuan tepat sasaran dan distribusi berjalan lancar!"
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `point_id` | integer | Ya | ID titik bantuan yang valid (min: 1) |
| `score` | integer | Ya | Antara 1 hingga 5 |
| `review` | string | Tidak | Maks 1000 karakter |

**Batasan:** Satu donatur hanya bisa memberi rating **satu kali** per titik bantuan (UNIQUE constraint).

---

## 12. Reports — `/api/reports`

### 12.1 Laporkan Titik Bantuan

```
POST /api/reports
```

**Autentikasi:** Bearer Token (**donatur** saja)

**Request Body:**

```json
{
  "point_id": 15,
  "reason": "Alamat tidak sesuai dengan yang tertera. Sudah dicek langsung ke lokasi."
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `point_id` | integer | Ya | ID titik bantuan yang valid (min: 1) |
| `reason` | string | Ya | Tidak boleh kosong, maks 1000 karakter |

---

## 13. Admin — `/api/admin`

Semua endpoint Admin memerlukan autentikasi dengan role **admin**.

### 13.1 Lihat Semua Laporan

```
GET /api/admin/reports
```

**Query Parameters:** `status`, `page`, `limit`

### 13.2 Update Status Laporan

```
PATCH /api/admin/reports/:id
```

**Request Body:**

```json
{ "status": "resolved" }
```

`status` valid: `resolved` / `dismissed`.

### 13.3 Statistik Sistem

```
GET /api/admin/stats
```

### 13.4 Hapus Titik (Soft Delete)

```
DELETE /api/admin/points/:id
```

Soft delete: `deleted_at` di-set, data tidak hilang dari DB.

---

## 14. Analytics — `/api/analytics`

Endpoint analytics bersifat **publik** — tidak memerlukan autentikasi.

### 14.1 Statistik Ringkasan

```
GET /api/analytics/stats
```

### 14.2 Data Heatmap

```
GET /api/analytics/heatmap
```

**Nilai Weight:**

| Urgency | Weight |
|---|:---:|
| `Mendesak` | `3` |
| `Normal` | `2` |
| `Rendah` | `1` |

---

## 15. Notifications — `/api/notifications`

> **Diubah di v3:** response sekarang berbentuk notifikasi (`title`, `subtitle`, `type`) agar bisa langsung ditampilkan di FE tanpa pemetaan tambahan. Handler dipindah ke `notificationController.js`.

### 15.1 Notifikasi Bantuan Terdekat

Mengambil daftar titik bantuan `Open` terdekat dari posisi user, diurutkan berdasarkan waktu dibuat (terbaru). Digunakan untuk daftar notifikasi di aplikasi mobile.

```
GET /api/notifications/nearby
```

**Autentikasi:** Bearer Token (semua role)

**Query Parameters:**

| Parameter | Tipe | Wajib | Default | Keterangan |
|---|---|:---:|---|---|
| `lat` | float | Ya | — | Latitude posisi user (-90 hingga 90) |
| `lng` | float | Ya | — | Longitude posisi user (-180 hingga 180) |
| `radius` | float | Tidak | `5000` | Radius dalam meter |
| `limit` | integer | Tidak | `5` | Jumlah notifikasi (maks: 50) |

**Contoh Request:**

```
GET /api/notifications/nearby?lat=-7.7956&lng=110.3695&radius=5000&limit=10
Authorization: Bearer eyJ0eXAi...
```

**Response 200 OK:**

```json
{
  "message": "Data notifikasi bantuan terdekat berhasil diambil",
  "count": 2,
  "data": [
    {
      "id": 18,
      "title": "Bantuan baru di dekat Anda",
      "subtitle": "Bantuan Air Bersih Mendesak",
      "type": "nearby_donation",
      "urgency": "Mendesak",
      "category": "Pangan",
      "distance_meters": 235,
      "longitude": 110.371,
      "latitude": -7.797,
      "point_id": 18,
      "created_at": "2026-05-20T10:00:00.000Z"
    }
  ]
}
```

> Field `title` selalu konstan `"Bantuan baru di dekat Anda"`. `subtitle` berisi judul titik. `type` untuk grouping di FE.

---

## 16. Users — `/api/users`

> **Baru di v3:** field `avatar_url`, `donation_count`, `points_helped`, `total_donation` di profile (semantik **per-role**). Endpoint baru `POST /api/users/avatar` untuk upload. Shape `getUserActivity` di-normalize ke `{ title, subtitle, type, created_at, ... }`.

### 16.1 Lihat Profil

```
GET /api/users/profile
```

**Autentikasi:** Bearer Token (semua role)

**Response 200 OK (untuk role komunitas/admin):**

```json
{
  "data": {
    "id": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "name": "Komunitas Berbagi Jogja",
    "email": "komunitas@example.com",
    "role": "komunitas",
    "bio": "Komunitas relawan bencana Yogyakarta.",
    "avatar_url": "https://your-project.supabase.co/storage/v1/object/public/avatars/.../avatar.png",
    "created_at": "2026-03-01T07:00:00.000Z",
    "donation_count": 12,
    "points_helped": 5,
    "total_donation": 35000000
  }
}
```

**Response 200 OK (untuk role donatur):**

```json
{
  "data": {
    "id": "bf89e3ca-e149-4f37-b19b-757523ad48f0",
    "name": "Budi Santoso",
    "email": "budi@example.com",
    "role": "donatur",
    "bio": "Aktif membantu masyarakat sekitar Yogyakarta.",
    "avatar_url": null,
    "created_at": "2026-03-01T07:00:00.000Z",
    "donation_count": 8,
    "points_helped": 5,
    "total_donation": 18000000
  }
}
```

**Semantik field stats (per-role):**

| Field | Komunitas / Admin | Donatur |
|---|---|---|
| `donation_count` | Jumlah titik bantuan yang **dibuat** (tidak termasuk yang di-soft-delete) | Jumlah rating yang pernah diberikan |
| `points_helped` | Jumlah titik yang berstatus `Completed` | Jumlah titik `Completed` yang dia rate |
| `total_donation` | `SUM(goal_amount)` dari semua titik aktif yang dibuat | `SUM(goal_amount)` dari semua titik `Completed` yang dia rate |

---

### 16.2 Update Profil

```
PATCH /api/users/profile
```

**Autentikasi:** Bearer Token (semua role)

**Request Body:**

```json
{
  "name": "Komunitas Berbagi Jogja",
  "bio": "Komunitas relawan bencana Yogyakarta.",
  "avatar_url": "https://your-cdn.example.com/avatar.png"
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `name` | string | Ya | Min 1 karakter, maks 100 karakter |
| `bio` | string | Tidak | Maks 500 karakter |
| `avatar_url` | string | Tidak | URL valid, maks 500 karakter |

> Untuk **upload file** avatar (bukan URL), gunakan endpoint **16.3 Upload Avatar**.

**Response 200 OK:**

```json
{
  "message": "Profil berhasil diperbarui",
  "data": {
    "id": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "name": "Komunitas Berbagi Jogja",
    "role": "komunitas",
    "bio": "Komunitas relawan bencana Yogyakarta.",
    "avatar_url": "https://your-cdn.example.com/avatar.png"
  }
}
```

---

### 16.3 Upload Avatar **(Baru v3)**

Mengunggah file avatar ke bucket Supabase `avatars` (public). URL hasil upload otomatis disimpan ke `users.avatar_url`.

```
POST /api/users/avatar
```

**Autentikasi:** Bearer Token (semua role)
**Content-Type:** `multipart/form-data`

**Form Fields:**

| Field | Tipe | Wajib | Keterangan |
|---|---|:---:|---|
| `avatar` | file | Ya | File gambar (`image/*`) — maks 5 MB |

**Contoh cURL:**

```bash
curl -X POST http://localhost:3000/api/users/avatar \
  -H "Authorization: Bearer eyJ0eXAi..." \
  -F "avatar=@/path/to/foto.jpg"
```

**Response 200 OK:**

```json
{
  "message": "Avatar berhasil diunggah",
  "data": {
    "id": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
    "name": "Komunitas Berbagi Jogja",
    "avatar_url": "https://your-project.supabase.co/storage/v1/object/public/avatars/<user_id>/<timestamp>-<rand>.jpg"
  }
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | Field `avatar` tidak diisi atau bukan file gambar |
| `500` | Bucket `avatars` belum dibuat di Supabase, atau gagal upload |

---

### 16.4 Riwayat Aktivitas

```
GET /api/users/activity
```

**Autentikasi:** Bearer Token (semua role)

**Query Parameters:**

| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `page` | integer | `1` | Nomor halaman |
| `limit` | integer | `10` | Jumlah per halaman (maks: 50) |

**Shape uniform v3:** semua role return `{ id, title, subtitle, type, created_at, ... }`. Field tambahan berbeda berdasarkan `type`.

**Response untuk Komunitas/Admin** — `type: "donation_managed"`:

```json
{
  "pagination": { "total": 7, "total_pages": 1, "current_page": 1, "limit": 10 },
  "data": [
    {
      "id": 15,
      "title": "Bantuan Pangan Korban Banjir Code",
      "subtitle": "Open • Mendesak",
      "type": "donation_managed",
      "status": "Open",
      "urgency": "Mendesak",
      "category": "Pangan",
      "created_at": "2026-04-01T08:00:00.000Z"
    }
  ]
}
```

**Response untuk Donatur** — `type: "rating_given"`:

```json
{
  "pagination": { "total": 3, "total_pages": 1, "current_page": 1, "limit": 10 },
  "data": [
    {
      "id": 9,
      "title": "Bantuan Pangan Korban Banjir Code",
      "subtitle": "Memberi nilai 5/5",
      "type": "rating_given",
      "score": 5,
      "review": "Bantuan tepat sasaran!",
      "point_id": 15,
      "point_status": "Completed",
      "point_category": "Pangan",
      "created_at": "2026-04-10T14:00:00.000Z"
    }
  ]
}
```

---

## 17. Community — `/api/community`

> **Baru di v3.** Modul postingan komunitas: posts, comments, likes.

### Skema Data

**`community_posts`** (tabel utama):

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | int | PK, serial |
| `author_id` | uuid | FK → users.id |
| `content` | text | Isi post |
| `post_type` | string | Lihat tabel di bawah |
| `image_url` | string | Opsional |
| `likes_count` | int | Counter denormalisasi |
| `created_at` | timestamp | — |

**Nilai `post_type` yang valid:**

| Nilai | Deskripsi |
|---|---|
| `bantuanDibutuhkan` | Permintaan bantuan komunitas |
| `pertanyaan` | Pertanyaan / diskusi |
| `updateKomunitas` | Update kegiatan (default) |
| `inspirasi` | Cerita inspiratif |
| `kisahSukses` | Kisah sukses distribusi |

---

### 17.1 List Posts

```
GET /api/community/posts
```

**Autentikasi:** **Optional** (Bearer Token). Jika token valid dikirim, field `liked_by_me` mencerminkan status like user; jika anonim, selalu `false`.

**Query Parameters:**

| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `tab` | string | `terbaru` | `terbaru` / `populer` / `diskusi` |
| `page` | integer | `1` | Nomor halaman |
| `limit` | integer | `10` | Maks 50 |

**Perilaku tab:**

| Tab | ORDER BY | Filter |
|---|---|---|
| `terbaru` | `created_at DESC` | — |
| `populer` | `likes_count DESC, created_at DESC` | — |
| `diskusi` | `created_at DESC` | `post_type IN ('bantuanDibutuhkan', 'pertanyaan')` |

**Response 200 OK:**

```json
{
  "pagination": { "total": 25, "total_pages": 3, "current_page": 1, "limit": 10 },
  "data": [
    {
      "id": 12,
      "content": "Update: distribusi paket pangan tahap 2 selesai. Terima kasih kepada para donatur!",
      "post_type": "updateKomunitas",
      "image_url": null,
      "likes_count": 18,
      "created_at": "2026-05-20T10:00:00.000Z",
      "author_id": "a1f05293-3804-4175-8b34-ac72e1eaab5e",
      "author_name": "Komunitas Berbagi Jogja",
      "author_avatar": "https://your-project.supabase.co/storage/v1/object/public/avatars/.../avatar.png",
      "author_role": "komunitas",
      "comments_count": 4,
      "liked_by_me": false
    }
  ]
}
```

---

### 17.2 Buat Post

```
POST /api/community/posts
```

**Autentikasi:** Bearer Token (**komunitas** saja)

**Request Body:**

```json
{
  "content": "Update: distribusi paket pangan tahap 2 selesai...",
  "post_type": "updateKomunitas",
  "image_url": null
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `content` | string | Ya | Min 1 karakter, maks 5000 karakter |
| `post_type` | string | Tidak | Lihat tabel post_type (default: `updateKomunitas`) |
| `image_url` | string | Tidak | URL valid, maks 500 karakter |

**Response 201 Created:**

```json
{
  "message": "Postingan berhasil dibuat",
  "data": {
    "id": 12,
    "content": "...",
    "post_type": "updateKomunitas",
    "image_url": null,
    "likes_count": 0,
    "created_at": "2026-05-20T10:00:00.000Z"
  }
}
```

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | Konten kosong atau `post_type` invalid |
| `403` | Role bukan komunitas |

---

### 17.3 Toggle Like

Like atau unlike post (toggle). Jika user sudah like, request ini akan **menghapus** like; sebaliknya menambah.

```
POST /api/community/posts/:id/like
```

**Autentikasi:** Bearer Token (semua role)

**Response 200 OK:**

```json
{
  "message": "Postingan disukai",
  "liked": true,
  "likes_count": 19
}
```

atau (kalau dibatalkan):

```json
{
  "message": "Like dibatalkan",
  "liked": false,
  "likes_count": 18
}
```

**Catatan implementasi:** menggunakan transaction `SELECT ... FOR UPDATE` agar `likes_count` konsisten saat banyak user like bersamaan.

**Response Error:**

| Kode | Kondisi |
|---|---|
| `400` | ID post invalid (bukan integer ≥ 1) |
| `404` | Postingan tidak ditemukan |

---

### 17.4 Lihat Komentar Post

```
GET /api/community/posts/:id/comments
```

**Autentikasi:** Tidak diperlukan (publik)

**Query Parameters:** `page` (default 1), `limit` (default 20, maks 100)

**Response 200 OK:**

```json
{
  "pagination": { "total": 4, "total_pages": 1, "current_page": 1, "limit": 20 },
  "data": [
    {
      "id": 7,
      "content": "Terima kasih atas updatenya, semangat terus!",
      "created_at": "2026-05-20T11:00:00.000Z",
      "author_id": "bf89e3ca-e149-4f37-b19b-757523ad48f0",
      "author_name": "Budi Santoso",
      "author_avatar": null,
      "author_role": "donatur"
    }
  ]
}
```

Komentar diurutkan `created_at ASC` (lama → baru).

---

### 17.5 Buat Komentar

```
POST /api/community/posts/:id/comments
```

**Autentikasi:** Bearer Token (semua role)

**Request Body:**

```json
{
  "content": "Terima kasih atas updatenya, semangat terus!"
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|:---:|---|
| `content` | string | Ya | Min 1 karakter, maks 2000 karakter |

**Response 201 Created:**

```json
{
  "message": "Komentar berhasil ditambahkan",
  "data": {
    "id": 7,
    "post_id": 12,
    "content": "Terima kasih atas updatenya, semangat terus!",
    "created_at": "2026-05-20T11:00:00.000Z"
  }
}
```

---

## 18. Health Check

### 18.1 Cek Kesehatan Sistem

```
GET /health
```

**Autentikasi:** Tidak diperlukan

**Response 200 OK:**

```json
{
  "status": "healthy",
  "database": "connected",
  "uptime": 3600.52,
  "timestamp": "2026-05-20T10:00:00.000Z"
}
```

> ⚠️ Saat ini route `/health` di repo **belum aktif** di `server.js` (hanya dipakai di test). Akan diaktifkan saat hardening produksi.

---

## 19. Panduan Postman

### Import Koleksi

1. Buka Postman → klik **Import**
2. Import dua file berikut dari folder `/postman/`:
   - `TitikBaik.postman_collection.json`
   - `TitikBaik.postman_environment.json`
3. Aktifkan environment **"Ada Titik – Local (Yogyakarta)"** di dropdown kanan atas

### Environment Variables (v3)

| Variable | Nilai Default | Keterangan |
|---|---|---|
| `base_url` | `http://localhost:3000` | URL server |
| `email_komunitas` | `komunitas@test.com` | Akun komunitas test |
| `password_komunitas` | `password123` | Password komunitas |
| `email_donatur` | `donatur@test.com` | Akun donatur test |
| `password_donatur` | `password123` | Password donatur |
| `email_admin` | `admin@test.com` | Akun admin test |
| `password_admin` | `password123` | Password admin |
| `token` | *(auto)* | Token login terakhir |
| `token_komunitas` | *(auto)* | Token komunitas, terisi setelah Login Komunitas |
| `token_donatur` | *(auto)* | Token donatur, terisi setelah Login Donatur |
| `token_admin` | *(auto)* | Token admin, terisi setelah Login Admin |
| `user_id_komunitas` | *(auto)* | UUID komunitas |
| `user_id_donatur` | *(auto)* | UUID donatur |
| `user_id_admin` | *(auto)* | UUID admin |
| `point_id` | *(auto)* | ID titik, terisi setelah Donations Create |
| `post_id` | *(auto)* | ID post, terisi setelah Community Create Post |
| `report_id` | `1` | ID laporan (manual) |
| `lat_jogja` | `-7.7956` | Latitude Tugu Yogyakarta |
| `lng_jogja` | `110.3695` | Longitude Tugu Yogyakarta |

### Urutan Pengujian yang Disarankan

```
1. Auth → Login Komunitas → token_komunitas tersimpan
2. Auth → Login Donatur → token_donatur tersimpan
3. Auth → Login Admin → token_admin tersimpan
4. Users → Upload Avatar (komunitas) → avatar_url tersimpan di DB
5. Donations → Create (komunitas) → point_id tersimpan
6. Donations → List All → verify field baru (category, goal_amount, author_name)
7. Documentation → Upload (komunitas, lampirkan foto)
8. Ratings → Give Rating (donatur)
9. Community → Create Post (komunitas) → post_id tersimpan
10. Community → Toggle Like (donatur)
11. Community → Create Comment (donatur)
12. Notifications → Nearby → verify shape (title, subtitle, type)
13. Donations → Update Status → On Progress
14. Donations → Update Status → Completed (komunitas, dengan user_lat/lng)
15. Reports → Create Report (donatur)
16. Admin → List Reports → verifikasi
17. Admin → Delete Point (soft delete)
```

### Auto-save Script (sudah built-in)

- **Login Komunitas/Donatur/Admin** → menyimpan `token`, `token_<role>`, `user_id_<role>`
- **Donations → Create** → menyimpan `point_id`
- **Community → Create Post** → menyimpan `post_id`

### Tips

- Folder **Admin** memakai `{{token_admin}}` khusus, tidak ketimpa Login Donatur/Komunitas.
- Untuk testing `liked_by_me=true` di **Community → List Posts** (yang default `noauth`), ganti Authorization request menjadi Bearer dengan `{{token_donatur}}`.

---

## 20. Aturan Validasi Lengkap

### Register

| Field | Wajib | Aturan |
|---|:---:|---|
| `name` | Ya | Tidak kosong, maks 100 karakter |
| `email` | Ya | Format email valid |
| `password` | Ya | Min 8 karakter |
| `role` | Ya | Hanya `donatur` atau `komunitas` |

### Login

| Field | Wajib | Aturan |
|---|:---:|---|
| `email` | Ya | Format email valid |
| `password` | Ya | Tidak kosong |

### Buat/Edit Titik Bantuan

| Field | Wajib (Buat) | Wajib (Edit) | Aturan |
|---|:---:|:---:|---|
| `title` | Ya | Tidak | Maks 200 karakter |
| `longitude` | Ya | — | -180 hingga 180 |
| `latitude` | Ya | — | -90 hingga 90 |
| `urgency` | Tidak | Tidak | `Mendesak` / `Normal` / `Rendah` |
| `category` | Tidak | Tidak | `Pangan` / `Medis` / `Pendidikan` / `Infrastruktur` / `Pakaian` / `Lainnya` / `Umum` |
| `goal_amount` | Tidak | Tidak | Number ≥ 0 |
| `description` | Tidak | Tidak | Teks bebas |

### Update Status

| Field | Wajib | Aturan |
|---|:---:|---|
| `status` | Ya | `On Progress` atau `Completed` |
| `user_lat` | Ya (jika Completed) | -90 hingga 90 |
| `user_lng` | Ya (jika Completed) | -180 hingga 180 |

### Beri Rating

| Field | Wajib | Aturan |
|---|:---:|---|
| `point_id` | Ya | Integer, min 1 |
| `score` | Ya | Integer, 1 hingga 5 |
| `review` | Tidak | Maks 1000 karakter |

### Laporan

| Field | Wajib | Aturan |
|---|:---:|---|
| `point_id` | Ya | Integer, min 1 |
| `reason` | Ya | Tidak kosong, maks 1000 karakter |

### Update Profil

| Field | Wajib | Aturan |
|---|:---:|---|
| `name` | Ya | Min 1 karakter, maks 100 karakter |
| `bio` | Tidak | Maks 500 karakter |
| `avatar_url` | Tidak | URL valid, maks 500 karakter |

### Upload Avatar (multipart)

| Field | Wajib | Aturan |
|---|:---:|---|
| `avatar` | Ya | File `image/*`, maks 5 MB |

### Nearby Donations Query

| Field | Wajib | Aturan |
|---|:---:|---|
| `lat` | Ya | Float, -90 hingga 90 |
| `lng` | Ya | Float, -180 hingga 180 |
| `radius` | Ya | Float, lebih dari 0 (dalam meter) |

### Nearby Notifications Query

| Field | Wajib | Aturan |
|---|:---:|---|
| `lat` | Ya | Float, -90 hingga 90 |
| `lng` | Ya | Float, -180 hingga 180 |
| `radius` | Tidak | Float, > 0 (default 5000) |
| `limit` | Tidak | Integer, 1 hingga 50 (default 5) |

### Buat Community Post

| Field | Wajib | Aturan |
|---|:---:|---|
| `content` | Ya | Min 1 karakter, maks 5000 karakter |
| `post_type` | Tidak | `bantuanDibutuhkan` / `pertanyaan` / `updateKomunitas` / `inspirasi` / `kisahSukses` |
| `image_url` | Tidak | URL valid, maks 500 karakter |

### Buat Community Comment

| Field | Wajib | Aturan |
|---|:---:|---|
| `content` | Ya | Min 1 karakter, maks 2000 karakter |

### Community Tab

| Field | Wajib | Aturan |
|---|:---:|---|
| `tab` | Tidak | `terbaru` / `populer` / `diskusi` |

---

## 21. Changelog v3

Per 2026-05-25. Migration: `database/migration_v3.sql`.

### DB Schema

- `users` — kolom baru: `avatar_url VARCHAR(500)`
- `donation_points` — kolom baru: `category` (enum 7 nilai), `goal_amount NUMERIC(15,2)`, `collected_amount NUMERIC(15,2)`
- Tabel baru: `community_posts`, `community_comments`, `post_likes`
- Index baru: `idx_donation_points_category`, `idx_community_posts_created`, `idx_community_posts_type`, `idx_community_comments_post`

### Endpoint

| Endpoint | Status |
|---|---|
| `POST /api/users/avatar` | **Baru** — upload file avatar |
| `GET /api/community/posts` | **Baru** — list dgn tab terbaru/populer/diskusi |
| `POST /api/community/posts` | **Baru** — komunitas only |
| `POST /api/community/posts/:id/like` | **Baru** — toggle like |
| `GET /api/community/posts/:id/comments` | **Baru** |
| `POST /api/community/posts/:id/comments` | **Baru** |
| `GET /api/users/profile` | **Diubah** — stats per-role (donation_count, points_helped, total_donation), `avatar_url` |
| `PATCH /api/users/profile` | **Diubah** — terima `avatar_url` |
| `GET /api/users/activity` | **Diubah** — shape uniform `{ id, title, subtitle, type, created_at }` |
| `GET /api/donations` | **Diubah** — filter `?category=`, response include `category`, `goal_amount`, `collected_amount`, `author_name`, `author_avatar` |
| `GET /api/donations/:id` | **Diubah** — include `creator_avatar`, `category`, `goal_amount`, `collected_amount` |
| `POST /api/donations` | **Diubah** — terima `category`, `goal_amount` |
| `PATCH /api/donations/:id` | **Diubah** — terima `category`, `goal_amount` |
| `GET /api/notifications/nearby` | **Diubah** — response berbentuk notifikasi (`title`, `subtitle`, `type`), tambah query `limit`, response include `distance_meters`, `category`, `point_id` |

### Breaking Changes untuk FE

- `GET /api/users/activity` lama: shape berbeda untuk komunitas vs donatur. **Sekarang:** uniform `{ title, subtitle, type, ... }`. FE harus update parser.
- `GET /api/notifications/nearby` lama: hanya return `{ id, title, urgency, distance }`. **Sekarang:** notification-shaped (`title` konstan, `subtitle` = judul titik).
- Field numerik `goal_amount`, `collected_amount`, `total_donation` di response berbentuk **string desimal** (`"5000000.00"`) dari driver pg — FE perlu `parseFloat()` jika butuh angka.

---

## 22. Ringkasan Endpoint

| # | Method | Endpoint | Auth | Role |
|---|---|---|:---:|---|
| 1 | POST | `/api/auth/register` | — | Publik |
| 2 | POST | `/api/auth/login` | — | Publik |
| 3 | GET | `/api/auth/me` | JWT | Semua |
| 4 | GET | `/api/donations` | — | Publik |
| 5 | GET | `/api/donations/nearby` | JWT | Semua |
| 6 | GET | `/api/donations/:id` | — | Publik |
| 7 | POST | `/api/donations` | JWT | Komunitas |
| 8 | PATCH | `/api/donations/:id` | JWT | Komunitas (pemilik) |
| 9 | PATCH | `/api/donations/:id/status` | JWT | Donatur, Komunitas |
| 10 | GET | `/api/documentation/:point_id` | JWT | Semua |
| 11 | POST | `/api/documentation` | JWT | Komunitas |
| 12 | GET | `/api/ratings/:point_id` | JWT | Semua |
| 13 | POST | `/api/ratings` | JWT | Donatur |
| 14 | POST | `/api/reports` | JWT | Donatur |
| 15 | GET | `/api/admin/reports` | JWT | Admin |
| 16 | PATCH | `/api/admin/reports/:id` | JWT | Admin |
| 17 | GET | `/api/admin/stats` | JWT | Admin |
| 18 | DELETE | `/api/admin/points/:id` | JWT | Admin |
| 19 | GET | `/api/analytics/stats` | — | Publik |
| 20 | GET | `/api/analytics/heatmap` | — | Publik |
| 21 | GET | `/api/notifications/nearby` | JWT | Semua |
| 22 | GET | `/api/users/profile` | JWT | Semua |
| 23 | PATCH | `/api/users/profile` | JWT | Semua |
| 24 | POST | `/api/users/avatar` | JWT | Semua |
| 25 | GET | `/api/users/activity` | JWT | Semua |
| 26 | GET | `/api/community/posts` | Optional | Semua |
| 27 | POST | `/api/community/posts` | JWT | Komunitas |
| 28 | POST | `/api/community/posts/:id/like` | JWT | Semua |
| 29 | GET | `/api/community/posts/:id/comments` | — | Publik |
| 30 | POST | `/api/community/posts/:id/comments` | JWT | Semua |

---

*Dokumentasi ini sinkron dengan source code per 2026-05-25 (migration_v3.sql).*
