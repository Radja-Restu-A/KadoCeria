# Perbaikan Parsing JSON dan Notifikasi Build Phase

Berdasarkan log yang diberikan, terdapat dua masalah utama:
1. **Parsing Error**: `type 'Null' is not a subtype of type 'String'` saat memuat `data.json` dari buku hasil unduhan. Ini menunjukkan ada field yang hilang atau null di file JSON dari server.
2. **Framework Error**: `setState() or markNeedsBuild() called during build`. Ini terjadi karena `triggerDownloadBook` memanggil `notifyListeners()` di tengah-tengah proses build dialog.

## Proposed Changes

### Model

#### [book_model_bundle.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/models/book_model_bundle.dart)
- Memberikan nilai default (`?? ''`) untuk semua field String di `BookModelBundle.fromJson`.
- Menangani potensi `primaryColor` atau `secondaryColor` yang null atau tidak ada.
- Menambahkan null check pada `pages`, `interactiveObjects`, dll.

### View / UI

#### [dashboard_screen.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/views/screens/dashboard_screen.dart)
- Membungkus panggilan `viewModel.triggerDownloadBook` di dalam `WidgetsBinding.instance.addPostFrameCallback` untuk mencegah pembaruan state selama fase build.

### ViewModel

#### [book_viewmodel.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/viewmodels/book_viewmodel.dart)
- Memperkecil cakupan `notifyListeners()` agar hanya dipanggil jika benar-benar diperlukan.

## Verification Plan

### Manual Verification via Logs
1. **Download Check**: Jalankan alur unduhan, pastikan error "setState during build" tidak muncul lagi di log.
2. **Parsing Check**: Klik "BACA", pastikan log menunjukkan `Successfully loaded from LOCAL STORAGE` tanpa ada error tipe data `Null`.
3. **UI Check**: Pastikan *aspect ratio* berhasil dihitung dan buku terbuka.
