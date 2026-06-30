# Walkthrough - Perbaikan Masalah Akses Buku Bundled dan Loading

Saya telah memperbaiki dua masalah utama: kegagalan membuka buku bawaan (Janiti/Sakeclak) dan masalah *loading* selamanya pada buku unduhan.

## Perbaikan yang Dilakukan

### 1. Perbaikan Akses Buku Bundled (Janiti & Sakeclak)
- **Masalah**: Buku ID 1 dan 2 tidak memiliki file `data.json` sendiri karena datanya terpusat di `metadata.json`. Perubahan sebelumnya memaksa aplikasi mencari file yang tidak ada tersebut.
- **Solusi**: Memperbarui `BookService.getBook` untuk menangani ID 1 dan 2 secara khusus dengan mengambil data langsung dari `metadata.json`. Sekarang buku bawaan kembali bisa dibuka dengan normal.

### 2. Resolusi File Dinamis (Buku Unduhan)
- **Masalah**: Aplikasi mencari gambar/suara buku unduhan di dalam folder internal aplikasi (*Assets*), bukan di penyimpanan HP.
- **Solusi**: `FlipbookViewModel` kini menggunakan `FileImage` dan jalur file absolut untuk buku unduhan, sehingga perhitungan ukuran halaman selesai dan layar *loading* hilang.

### 3. Pembersihan Folder Ekstraksi
- Menambahkan logika di `BookService` untuk menghapus data lama sebelum mengekstrak buku baru, menjamin integritas data unduhan.

## Hasil Verifikasi

- **Buku Bundled**: ID 1 dan 2 terbukti mengarah ke `metadata.json` yang benar.
- **Buku Unduhan**: Proses *loading* kini singkat dan konten (gambar/audio) muncul dari penyimpanan internal HP.
- **Analisis Statis**: Kode telah diverifikasi dan bebas dari error sintaksis yang menghalangi build.
