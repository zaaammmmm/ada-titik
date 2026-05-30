# TODO_GPS

## Tujuan
Membuat tombol **📍 Gunakan Lokasi Saya** berfungsi baik di:
- Linux desktop (geolocator sering return null/serviceEnabled false)
- Android (butuh permission runtime + provider aktif)

## Langkah Implementasi
1. Update `LocationService.getCurrentPosition()` agar:
   - Memanggil `Geolocator.getLastKnownPosition()` sebagai fallback.
   - Memunculkan error yang lebih informatif (service disabled vs permission denied vs plugin exception).
   - (Opsional) menurunkan desiredAccuracy/cek ulang permission.
2. Update UI `AddTitikScreen` agar:
   - Menyediakan tindakan saat lokasi gagal (contoh: tombol “Coba lagi” + link ke pengaturan lokasi).
   - Menggunakan fallback koordinat (last known) jika ada.
   - Memanggil `Geolocator.requestPermission()` + cek permission status final.
3. Untuk Android:
   - Pastikan `AndroidManifest.xml` punya permission lokasi.
   - Pastikan geolocator sudah di-initialize dan permission ditangani.
4. Jalankan test manual:
   - Android real device: enable/disable location, deny permission, revoke permission.
   - Linux desktop: jalankan di browser build dan desktop build, cek behavior.

## File yang kemungkinan diedit
- `lib/core/services/location_service.dart`
- `lib/features/donation/add_titik_screen.dart`
- `android/app/src/main/AndroidManifest.xml`

