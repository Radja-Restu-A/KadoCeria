import '../models/book_model.dart';

class TeksProvider {
  static final Map<String, Map<String, String>> _strings = {
    'indonesia': {
      'appTitle': 'Balai Bahasa Provinsi Jawa Barat',
      'noBooks': 'Tidak ada buku tersedia',
      'listenPage': 'Dengarkan Halaman Ini',
      'listenBook': 'Dengarkan Seluruh Buku',
      'retry': 'Coba Lagi',
      'loading': 'Memuat...',
      'error': 'Terjadi Kesalahan',
      'author' : 'Penulis',
      'stop': 'Hentikan',
      'onepage' : 'Dengarkan halaman ini',
      'fullbook' : 'Dengarkan seluruh buku',
      'endreading': 'Selesai Membaca',
      // ✅ TAMBAHAN: String untuk audio error modal
      'audioError': 'Maaf, sepertinya ada masalah untuk suara di halaman ini',
      'ok': 'Oke',
      'continue': 'Lanjut',
    },
    'sunda': {
      'appTitle': 'Balai Bahasa Provinsi Jawa Barat',
      'noBooks': 'Teu aya buku nu sayaga',
      'listenPage': 'Dangukeun Kaca Ieu',
      'listenBook': 'Dangukeun Sakabéh Buku',
      'retry': 'Cobian Deui',
      'loading': 'Ngamuat...',
      'error': 'Aya Kasalahan',
      'author': 'Panulis',
      'stop': 'Eureun',
      'onepage': 'Dangukeun kaca ieu',
      'fullbook': 'Dangukeun sakabéh buku',
      'endreading': 'Rengse Maca',
      // ✅ TAMBAHAN: String untuk audio error modal
      'audioError': 'Hampura, sigana aya masalah pikeun sora di kaca ieu',
      'ok': 'Oke',
      'continue': 'Teruskeun',
    },
  };

  static String getString(String key, Language language) {
    return _strings[language.code]?[key] ?? _strings['indonesia']![key]!;
  }
}