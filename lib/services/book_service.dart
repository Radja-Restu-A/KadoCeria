import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_model_bundle.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

class BookService {
  static BookModelBundle? _cachedBook;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.14:39246/api', // Simpan base URL di sini
    connectTimeout: const Duration(seconds: 10), // Wajib: agar tidak loading selamanya
    receiveTimeout: const Duration(seconds: 10),
  )); // Sesuaikan URL CMS Anda
  // Mengambil katalog dari API 1
  Future<List<BookSummaryModel>> fetchNetworkBookCatalog() async {
    try {
      final response = await _dio.get('/get/dataInformasiBuku');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => BookSummaryModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      // 3. Tangkap error Dio secara spesifik untuk mempermudah debugging
      debugPrint('Dio Error: ${e.message}');
      throw Exception('Gagal memuat katalog: ${e.response?.statusCode ?? e.type}');
    } catch (e) {
      throw Exception('Gagal memuat katalog buku dari server: $e');
    }
  }
  // Mengunduh berkas ZIP dari API 2 dan mengekstraknya secara lokal
  Future<String> downloadAndExtractBookArchive(String bookId) async {
    try {
      // 1. Dapatkan URL Unduhan S3 dari API 2
      final response = await _dio.get('/get/kontenBuku?id=$bookId');
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Gagal mendapatkan tautan unduhan konten.');
      }
      String downloadUrl = response.data['downloadUrl'];
      // 2. Tentukan jalur direktori internal dokumen aplikasi aman
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savePath = '${appDocDir.path}/tmp_$bookId.zip';
      String targetExtractionPath = '${appDocDir.path}/books/buku_$bookId';
      // 3. Proses pengunduhan fisik berkas zip ke penyimpanan
      await _dio.download(downloadUrl, savePath);
      // 4. Ekstraksi berkas zip menggunakan paket archive
      var bytes = File(savePath).readAsBytesSync();
      var archive = ZipDecoder().decodeBytes(bytes);
      for (var file in archive) {
        var filename = file.name;
        if (file.isFile) {
          var data = file.content as List<int>;
          File('$targetExtractionPath/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('$targetExtractionPath/$filename').createSync(recursive: true);
        }
      }
      // 5. Hapus berkas zip sementara setelah sukses diekstrak demi menghemat memori
      final tempZipFile = File(savePath);
      if (tempZipFile.existsSync()) tempZipFile.deleteSync();
      return targetExtractionPath; // Mengembalikan path lokal absolut folder buku
    } catch (e) {
      throw Exception('Proses unduhan atau ekstraksi buku gagal: $e');
    }
  }

  // Tambahkan method ini di dalam BookService
  Future<List<BookSummaryModel>> fetchLocalBundledCatalog() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/metadata.json');
      final Map<String, dynamic> fullData = json.decode(jsonString);
      final List<dynamic> jsonData = fullData['books'] ?? [];

      return jsonData.map((json) => BookSummaryModel(
        idBuku: json['id']?.toString() ?? '',
        judulBukuIndonesia: json['title_id'] ?? 'Tanpa Judul',
        judulBukuSunda: json['title_su'] ?? 'Tanpa Judul',
        penulis: json['author'] ?? 'Tidak diketahui',
        illustrator: json['illustrator'] ?? 'Tidak diketahui',
        // Path lokal (contoh: assets/images/cover_janiti.webp)
        coverImagePath: json['coverImagePath'] ?? '',
        descriptionsIndonesia: json['description_id'] ?? '-',
        descriptionsSunda: json['description_su'] ?? '-',
        primaryColor: json['primaryColor'] ?? '#FFFFFF',
        secondaryColor: json['secondaryColor'] ?? '#FFFFFF',
        version: 1,
        fileSize: 'Bundled',
      )).toList();
    } catch (e) {
      debugPrint('Gagal memuat metadata lokal: $e');
      return []; // Mengembalikan list kosong alih-alih melempar error yang mematikan aplikasi
    }
  }

  // Updated method to handle multiple interactive objects
  List<PageLayout> calculateInteractiveObjectsLayout(StoryPage page, BoxConstraints constraints) {
    List<PageLayout> layouts = [];

    // Handle null values dengan default values
    final pageWidthImage = page.widthImage ?? 1.0; // Prevent division by zero
    final pageHeightImage = page.heightImage ?? 1.0; // Prevent division by zero

    // Validasi untuk mencegah division by zero
    if (pageWidthImage <= 0 || pageHeightImage <= 0) {
      return layouts; // Return empty list jika dimensi image tidak valid
    }

    // Validasi constraints
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
      return layouts;
    }

    final imageRatio = pageWidthImage / pageHeightImage;
    final screenRatio = constraints.maxWidth / constraints.maxHeight;

    double renderedWidth, renderedHeight;
    double imageOffsetX = 0, imageOffsetY = 0;

    if (screenRatio > imageRatio) {
      renderedHeight = constraints.maxHeight;
      renderedWidth = renderedHeight * imageRatio;
      imageOffsetX = (constraints.maxWidth - renderedWidth) / 2;
    } else {
      renderedWidth = constraints.maxWidth;
      renderedHeight = renderedWidth / imageRatio;
      imageOffsetY = (constraints.maxHeight - renderedHeight) / 2;
    }

    // Prevent division by zero untuk scale calculations
    final scaleX = pageWidthImage > 0 ? renderedWidth / pageWidthImage : 1.0;
    final scaleY = pageHeightImage > 0 ? renderedHeight / pageHeightImage : 1.0;

    // Calculate layout for each interactive object
    for (InteractiveObject obj in page.interactiveObjects) {
      final objX = obj.x ?? 0.0;
      final objY = obj.y ?? 0.0;
      final objWidth = obj.width ?? 0.0;
      final objHeight = obj.height ?? 0.0;

      layouts.add(PageLayout(
        interactiveLeft: (objX * scaleX) + imageOffsetX,
        interactiveTop: (objY * scaleY) + imageOffsetY,
        interactiveWidth: objWidth * scaleX,
        interactiveHeight: objHeight * scaleY,
      ));
    }

    return layouts;
  }

  // Backward compatibility method - returns layout for first interactive object or default
  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    final layouts = calculateInteractiveObjectsLayout(page, constraints);

    if (layouts.isNotEmpty) {
      return layouts.first;
    }

    return PageLayout(
      interactiveLeft: 0.0,
      interactiveTop: 0.0,
      interactiveWidth: 0.0,
      interactiveHeight: 0.0,
    );
  }

  bool isFirstPage(int currentPage) {
    return currentPage == 0;
  }

  bool isLastPage(int currentPage, int totalPages) {
    return currentPage >= totalPages - 1;
  }

  // Helper method to check if a page has interactive objects
  bool hasInteractiveObjects(StoryPage page) {
    return page.interactiveObjects.isNotEmpty;
  }

  // Helper method to get count of interactive objects in a page
  int getInteractiveObjectsCount(StoryPage page) {
    return page.interactiveObjects.length;
  }

  // Helper method to get specific interactive object by index
  InteractiveObject? getInteractiveObjectAt(StoryPage page, int index) {
    if (index >= 0 && index < page.interactiveObjects.length) {
      return page.interactiveObjects[index];
    }
    return null;
  }

  // Main method for load all book from metadata.json
  static Future<List<BookModelBundle>> loadBooks() async {
    try {
      final String response = await rootBundle.loadString('assets/metadata.json');
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> booksJson = data['books'];

      return booksJson.map((json) => BookModelBundle.fromJson(json)).toList();
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  static Future<BookModelBundle?> getBook(String bookId) async {
    if (_cachedBook != null && _cachedBook!.id == bookId) {
      return _cachedBook;
    }

    try {
      final String response = await rootBundle.loadString('assets/books/$bookId/data.json');
      final Map<String, dynamic> data = json.decode(response);

      _cachedBook = BookModelBundle.fromJson(data);
      return _cachedBook;
    } catch (e) {
      debugPrint('Error loading book $bookId: $e');
      return null;
    }
  }

  // Method for load one book by ID (optional)
  static Future<BookModelBundle?> loadBookById(String id) async {
    try {
      final List<BookModelBundle> books = await loadBooks();
      return books.firstWhere((book) => book.id == id);
    } catch (e) {
      print('Error loading book with id $id: $e');
      return null;
    }
  }

  // Method for load complete metadata (optional)
  static Future<Map<String, dynamic>> loadMetadata() async {
    try {
      final String response = await rootBundle.loadString('assets/metadata.json');
      return json.decode(response);
    } catch (e) {
      print('Error loading metadata: $e');
      return {};
    }
  }
}