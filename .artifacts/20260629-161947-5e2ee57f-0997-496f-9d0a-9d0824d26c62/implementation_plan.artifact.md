# Diagnosa Audio Dipercepat dan Terdistorsi

Diagnosa: Masalah audio yang menjadi cepat lalu rusak biasanya terkait dengan **re-inisialisasi buffer** atau **state player** yang tidak bersih saat berpindah file. `just_audio` terkadang mengalami masalah sinkronisasi jam audio jika file baru dimuat sebelum file lama benar-benar dilepaskan.

## Proposed Changes

### Services

#### [audio_service.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/services/audio_service.dart)

- Menambah log debugging untuk memantau `speed`, `pitch`, dan `processingState` secara real-time.
- Memaksa reset `setSpeed(1.0)` dan `setPitch(1.0)` setiap kali memulai playback baru.
- Menambahkan `await _audioPlayer.stop()` dan sedikit delay sebelum `setAsset`/`setFilePath` untuk memberi waktu pada OS melepaskan driver audio.
- Menggunakan `PlayerState` untuk mendeteksi apakah player dalam keadaan "idle" sebelum memuat aset baru.

```dart
// Contoh pengetatan alur muat audio
Future<void> playAudio(String path, {required bool isBundled}) async {
  debugPrint('[AudioService] RE-LOADING AUDIO. Current speed: ${_audioPlayer.speed}');
  await _audioPlayer.stop();
  await _audioPlayer.setSpeed(1.0); // Reset speed
  // ... proses muat ...
}
```

## Verification Plan

### Manual Verification via Logs
1. **Lakukan Pemutaran**: Putar audio halaman 1, lalu cepat pindah ke halaman 2.
2. **Cek Log**:
    - Apakah `speed` tiba-tiba berubah dari 1.0?
    - Apakah ada error `PlayerException` saat proses `setAsset`?
    - Pantau apakah `processingState` melewati fase `loading` dan `buffering` dengan benar.
