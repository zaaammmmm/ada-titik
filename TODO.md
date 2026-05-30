# TODO - Perbaikan Issue AdaTitik

## No 1 — Setelah Accept, titik tetap muncul
- [x] Ubah `ActiveRequestsScreen` agar tidak hanya filter `RequestStatus.open`.
  - ✅ Implementasi: gabungan `open` + `onProgress` sampai titik benar-benar tertutup/target terpenuhi.
- [ ] Pastikan `MapsScreen` tetap menampilkan titik yang sudah di-accept (cek filter backend di `/api/donations/nearby` atau FE-side filter bila ada).
- [ ] Verifikasi manual:
  - Terima donatur (owner accept) → titik tidak hilang dari list dan map.

## No 2 — Error saat owner menekan "tutup titik bantuan" (geo-fencing)
- [x] Sesuaikan `DepartureReviewScreen._closePoint()` supaya tidak memanggil status yang memicu geo-fencing/GPS.
- [x] Tutup titik manual kini menggunakan fallback yang aman (status aktif) agar tidak memicu rule GPS/geo-fence.
- [ ] Verifikasi manual:
  - Owner accept → tombol tutup titik → tidak memunculkan error GPS wajib.

## No 3 — RequestDetailScreen menampilkan lokasi akurat & preview maps benar
- [x] Audit field `DonationRequest.location/latitude/longitude` dari backend.
- [x] Perbaiki fallback string `location` (jangan selalu "Lokasi belum tersedia" bila koordinat ada).
- [ ] Pastikan marker + initialCenter menggunakan koordinat yang dipetakan dari backend (bukan hardcoded default).
- [ ] Verifikasi manual:
  - Buka request detail untuk titik yang baru dibuat → lokasi tertulis sesuai & preview peta tepat.


## No 4 — ActiveRequestsScreen menampilkan jarak sesuai lokasi device
- [x] Jika backend tidak menyediakan `distance_meters`, hitung jarak di FE menggunakan `LocationService`.
- [x] Tampilkan jarak yang benar pada chip jarak.
- [ ] Verifikasi manual:
  - Pindahkan device → jarak pada active requests berubah sesuai.


## No 5 — Rating donatur setelah owner accept (notifikasi + poin + arah ke rating screen)
- [ ] Tambahkan trigger pada flow owner `acceptParticipants` untuk:
  - bertambahnya poin (untuk owner & donatur sesuai rule)
  - pembuatan notifikasi rating untuk donatur
- [x] Tambahkan navigasi saat donatur membuka notifikasi rating menuju UI rating.
  - (Bisa lewat `NotificationScreen` / deep-link / route)
- [ ] Pastikan donatur bisa melakukan rating hanya saat sudah di-accept (atau status yang sesuai).
- [ ] Verifikasi manual:
  - Owner accept → donatur menerima notifikasi rating → diarahkan ke rating screen → rating bisa dilakukan.


## Quality / Testing
- [ ] `flutter analyze`
- [ ] Cek build Android
- [ ] Smoke test: tambah titik → accept → detail → tutup titik → rating

