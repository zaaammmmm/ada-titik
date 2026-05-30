# Auth - Terms & Conditions + Forget Password

## Plan implementasi

1) Flutter UI
- [x] Buat `lib/features/auth/terms_and_conditions_screen.dart`.
- [x] Buat `lib/features/auth/forget_password_screen.dart`.
- [x] Tambahkan route di `lib/core/router/app_router.dart`.
- [x] Edit `lib/features/auth/login_screen.dart` agar tombol "Lupa Password?" menuju `forget_password`.
- [x] Opsional: di `register_screen.dart`, klik teks "Syarat & Ketentuan" menuju halaman terms.

2) Backend (Express)
- [ ] Tambahkan endpoint request reset: `POST /api/auth/forgot-password`.
- [ ] Tambahkan endpoint reset: `POST /api/auth/reset-password` (pakai token).
- [ ] Implement minimal via token reset disimpan di tabel (atau memory kalau belum ada skema, tapi lebih baik DB).
- [ ] Pastikan endpoint mengembalikan response status success/fail.

3) Integrasi Flutter -> Backend
- [x] Forget password screen memanggil `/api/auth/forgot-password`.
- [ ] Reset password (kalau terpisah) memanggil `/api/auth/reset-password`.
- [ ] Tambahkan handling error & validasi form.

4) QA
- [x] Jalankan `flutter analyze` (warning banyak tapi build tidak error).
- [ ] Jalankan test backend jika ada.


