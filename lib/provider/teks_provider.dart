// lib/provider/teks_provider.dart
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
      // 'titles': 'Setetes Air Hujan, Ingin ke Samudra',
      // 'descriptions': 'Kania dan Gumiwang sedang bermain layangan di halaman rumah mereka. Langit mendung. Setetes air hujan mengenai hidung Kania. Hujan pun turun, keduanya bermain hujan-hujanan. Kania penasaran ke mana berlalunya setetes air hujan yang jatuh dari langit itu. Kania dan Gumiwang kemudian mengikuti aliran air ke selokan yang menuju ke sawah. Di sawah, mereka bertemu dengan kakek mereka yang sedang berteduh di sebuah saung. Sambil menunggu hujan reda, Kakek mendongeng tentang perjalanan setetes air hujan yang ingin ke samudra. Dari dongeng Kakek, akhirnya Kania dan Gumiwang menjadi tahu tentang hujan.',
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
      // 'titles': 'Sakeclak Cihujan Hayang ka Sagara',
      // 'descriptions': 'Kania jeung Gumiwang keur ngalayang langlayangan di pakarangan. Langit mendung. Titisan hujan neunggeul irung Kania. Hujan ngaririncik, duaan ulin hujan.Kania naros ka mana lir cihujan nu turun ti langit. Kania jeung Gumiwang tuluy nuturkeun aliran cai nepi ka solokan anu ngajugjug ka sawah. Di sawah, panggih jeung akina nu keur ngonci di gubug. Bari ngadagoan hujan eureun, Embah nyaritakeun lalampahan titisan hujan ka sagara.Tina carita Embah, Kania jeung Gumiwang ahirna diajar ngeunaan hujan.'
    },
  };

  static String getString(String key, Language language) {
    return _strings[language.code]?[key] ?? _strings['indonesia']![key]!;
  }
}