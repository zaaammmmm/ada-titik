# TODO - Ada Titik (Chat Feature)

## Step 1 — Analisis & Spesifikasi
- [x] Identifikasi endpoint chat dari `Ada Titik API.postman_collection.json`
- [x] Tentukan integrasi UI chat ke screen Active Request

## Step 2 — Navigasi “Hubungi Komunitas”
- [x] Tambahkan tombol/link “Hubungi Komunitas” pada `lib/features/donation/active_requests_screen.dart`
- [x] Tambahkan tombol “Hubungi Komunitas” pada `lib/features/donation/request_detail_screen.dart`
- [x] Navigasi ke Chat Screen dengan parameter yang dibutuhkan (targetUserId & contextId)


## Step 3 — Buat Chat Screen + Repository
- [ ] Buat folder `lib/features/chat/`
- [ ] Buat `lib/features/chat/chat_screen.dart` (UI WhatsApp-like)
- [ ] Buat `lib/features/chat/data/chat_repository.dart` (panggil `/api/chats`)
- [ ] Implementasi load list conversation/messages, kirim pesan, dan mark as read

## Step 4 — Model & Mapping API
- [ ] Tambahkan model untuk conversation/message bila belum ada
- [ ] Pastikan mapping JSON sesuai response backend

## Step 5 — Testing & Lint
- [ ] `flutter analyze`
- [ ] Cek build/run (minimal)
