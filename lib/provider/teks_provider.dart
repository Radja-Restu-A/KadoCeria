import '../models/book_model.dart';

class TeksProvider {
  static final Map<String, Map<String, String>> _strings = {
    'indonesia': {
      'appTitle': 'Balai Bahasa Provinsi Jawa Barat',
      'noBooks': 'Tidak ada buku tersedia',
      'retry': 'Coba Lagi',
      'loading': 'Memuat...',
      'error': 'Terjadi Kesalahan',
      'author' : 'Penulis',
      'stop': 'Hentikan',
      'onepage' : 'Dengarkan halaman ini',
      'fullbook' : 'Dengarkan seluruh cerita',
      'endreading': 'Selesai',
      'audioError': 'Maaf, sepertinya ada masalah untuk suara di halaman ini',
      'ok': 'Oke',
      'continue': 'Lanjut',
    },
    'sunda': {
      'appTitle': 'Balai Bahasa Provinsi Jawa Barat',
      'noBooks': 'Teu aya buku nu sayaga',
      'retry': 'Cobian Deui',
      'loading': 'Ngamuat...',
      'error': 'Aya Kasalahan',
      'author': 'Panulis',
      'stop': 'Eureun',
      'onepage': 'Regepkeun kaca ieu',
      'fullbook': 'Regepkeun carita ieu',
      'endreading': 'Rengse',
      'audioError': 'Punten, sigana aya masalah pikeun sora di kaca ieu',
      'ok': 'Oke',
      'continue': 'Teruskeun',
    },
  };

  static String getString(String key, Language language) {
    return _strings[language.code]?[key] ?? _strings['indonesia']![key]!;
  }
}