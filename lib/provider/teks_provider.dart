import '../models/book_model_bundle.dart';

class TeksProvider {
  static final Map<String, Map<String, String>> _strings = {
    'indonesia': {
      'appTitle': 'Balai Bahasa Provinsi Jawa Barat',
      'noBooks': 'Tidak ada buku tersedia',
      'retry': 'Coba Lagi',
      'loading': 'Memuat...',
      'error': 'Terjadi Kesalahan',
      'author' : 'Penulis',
      'illustrator': 'Ilustrator',
      'read': 'Baca',
      'download': 'Unduh',
      'stop': 'Hentikan',
      'onepage' : 'Dengarkan halaman ini',
      'fullbook' : 'Dengarkan seluruh cerita',
      'endreading': 'Selesai',
      'audioError': 'Maaf, sepertinya ada masalah untuk suara di halaman ini',
      'ok': 'Oke',
      'continue': 'Lanjut',
      'myLibrary': 'Koleksi Saya',
      'discover': 'Jelajahi Buku Baru',
    },
    'sunda': {
      'appTitle': 'Balai Bahasa Provinsi Jawa Barat',
      'noBooks': 'Teu aya buku nu sayaga',
      'retry': 'Cobian Deui',
      'loading': 'Ngamuat...',
      'error': 'Aya Kasalahan',
      'author': 'Panulis',
      'illustrator': 'Ilustrator',
      'read': 'Baca',
      'download': 'Unduh',
      'stop': 'Eureun',
      'onepage': 'Regepkeun kaca ieu',
      'fullbook': 'Regepkeun carita ieu',
      'endreading': 'Réngsé',
      'audioError': 'Punten, sigana aya masalah pikeun sora di kaca ieu',
      'ok': 'Oke',
      'continue': 'Teruskeun',
      'myLibrary': 'Koléksi Abdi',
      'discover': 'Kotéktak Buku Anyar',
    },
  };

  static String getString(String key, Language language) {
    try{
      return _strings[language.code]?[key] ?? _strings['indonesia']![key]!;
    }catch(e){
      throw Exception('Failed to get string for key $key and language ${language.code}: $e');
    }
  }
}