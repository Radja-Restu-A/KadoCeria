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
    baseUrl: 'http://192.168.1.13/cms-kadoceria/public/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  Future<List<BookSummaryModel>> fetchNetworkBookCatalog() async {
    try {
      final response = await _dio.get('/get/dataInformasiBuku');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => BookSummaryModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Dio Error: ${e.message}');
      throw Exception('Gagal memuat katalog: ${e.response?.statusCode ?? e.type}');
    } catch (e) {
      throw Exception('Gagal memuat katalog buku dari server: $e');
    }
  }

  Future<List<BookSummaryModel>> fetchDownloadedBooksMetadata() async {
    List<BookSummaryModel> downloadedBooks = [];
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory booksDir = Directory('${appDocDir.path}/books');

      if (!await booksDir.exists()) {
        return [];
      }

      List<FileSystemEntity> entities = await booksDir.list().toList();
      for (var entity in entities) {
        if (entity is Directory) {
          File dataFile = File('${entity.path}/data.json');
          if (await dataFile.exists()) {
            try {
              String content = await dataFile.readAsString();
              Map<String, dynamic> data = json.decode(content);
              downloadedBooks.add(BookSummaryModel(
                idBuku: data['id']?.toString() ?? '',
                judulBukuIndonesia: data['title_id']?.toString() ?? '',
                judulBukuSunda: data['title_su']?.toString() ?? '',
                penulis: data['author']?.toString() ?? '',
                illustrator: data['illustrator']?.toString() ?? '',
                coverImagePath: '${entity.path}/${data['coverImagePath'] ?? data['coverImage'] ?? ''}',
                descriptionsIndonesia: data['description_id']?.toString() ?? '',
                descriptionsSunda: data['description_su']?.toString() ?? '',
                primaryColor: (data['theme']?['primary'])?.toString() ?? data['primaryColor']?.toString() ?? '#4FC3F7',
                secondaryColor: (data['theme']?['secondary'])?.toString() ?? data['secondaryColor']?.toString() ?? '#81D4FA',
                version: int.tryParse(data['version']?.toString() ?? '1') ?? 1,
                fileSize: 'Downloaded',
              ));
            } catch (e) {
              debugPrint('Error parsing data.json in ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching downloaded books metadata: $e');
    }
    return downloadedBooks;
  }
  Future<String> downloadAndExtractBookArchive(String bookId) async {
    debugPrint('[BookService] Starting download for bookId: $bookId');
    try {
      final response = await _dio.get('/get/kontenBuku?id=$bookId');
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Gagal mendapatkan tautan unduhan konten.');
      }
      String downloadUrl = response.data['downloadUrl'];
      debugPrint('[BookService] Download URL obtained: $downloadUrl');

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savePath = '${appDocDir.path}/tmp_$bookId.zip';
      String targetExtractionPath = '${appDocDir.path}/books/buku_$bookId';

      debugPrint('[BookService] Save Path: $savePath');
      debugPrint('[BookService] Extraction Path: $targetExtractionPath');

      final targetDir = Directory(targetExtractionPath);
      if (targetDir.existsSync()) {
        debugPrint('[BookService] Target directory exists, deleting...');
        targetDir.deleteSync(recursive: true);
      }
      targetDir.createSync(recursive: true);

      debugPrint('[BookService] Downloading ZIP file...');
      await _dio.download(downloadUrl, savePath);
      debugPrint('[BookService] ZIP Downloaded successfully');

      debugPrint('[BookService] Starting extraction...');
      var bytes = File(savePath).readAsBytesSync();
      var archive = ZipDecoder().decodeBytes(bytes);
      for (var file in archive) {
        var filename = file.name;
        if (file.isFile) {
          var data = file.content as List<int>;
          File('$targetExtractionPath/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
          debugPrint('[BookService] Extracted file: $filename');
        } else {
          Directory('$targetExtractionPath/$filename').createSync(recursive: true);
          debugPrint('[BookService] Created directory: $filename');
        }
      }
      final tempZipFile = File(savePath);
      if (tempZipFile.existsSync()) tempZipFile.deleteSync();
      
      debugPrint('[BookService] Extraction complete. Folder path: $targetExtractionPath');
      return targetExtractionPath;
    } catch (e) {
      debugPrint('[BookService] CRITICAL ERROR during download/extract: $e');
      throw Exception('Proses unduhan atau ekstraksi buku gagal: $e');
    }
  }

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
      return [];
    }
  }

  List<PageLayout> calculateInteractiveObjectsLayout(StoryPage page, BoxConstraints constraints) {
    List<PageLayout> layouts = [];

    final pageWidthImage = page.widthImage ?? 1.0;
    final pageHeightImage = page.heightImage ?? 1.0;

    if (pageWidthImage <= 0 || pageHeightImage <= 0) {
      return layouts;
    }

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

    final scaleX = pageWidthImage > 0 ? renderedWidth / pageWidthImage : 1.0;
    final scaleY = pageHeightImage > 0 ? renderedHeight / pageHeightImage : 1.0;

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

  bool hasInteractiveObjects(StoryPage page) {
    return page.interactiveObjects.isNotEmpty;
  }

  int getInteractiveObjectsCount(StoryPage page) {
    return page.interactiveObjects.length;
  }

  InteractiveObject? getInteractiveObjectAt(StoryPage page, int index) {
    if (index >= 0 && index < page.interactiveObjects.length) {
      return page.interactiveObjects[index];
    }
    return null;
  }

  static Future<List<BookModelBundle>> loadBooks() async {
    try {
      final String response = await rootBundle.loadString('assets/metadata.json');
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> booksJson = data['books'];

      return booksJson.map((json) => BookModelBundle.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading books: $e');
      return [];
    }
  }

  static Future<BookModelBundle?> getBook(String bookId) async {
    debugPrint('[BookService] Attempting to get book data for ID: $bookId');
    if (_cachedBook != null && _cachedBook!.id == bookId) {
      debugPrint('[BookService] Returning cached book');
      return _cachedBook;
    }

    try {
      if (bookId == "1" || bookId == "2") {
        debugPrint('[BookService] Loading BUNDLED book $bookId from metadata.json');
        final List<BookModelBundle> bundledBooks = await loadBooks();
        try {
          _cachedBook = bundledBooks.firstWhere((b) => b.id == bookId);
          debugPrint('[BookService] Successfully loaded from BUNDLED metadata');
          return _cachedBook;
        } catch (e) {
          debugPrint('[BookService] Book ID $bookId not found in metadata.json');
        }
      }

      try {
        final assetPath = 'assets/books/$bookId/data.json';
        debugPrint('[BookService] Checking assets at: $assetPath');
        final String response = await rootBundle.loadString(assetPath);
        final Map<String, dynamic> data = json.decode(response);
        _cachedBook = BookModelBundle.fromJson(data);
        debugPrint('[BookService] Successfully loaded from ASSETS');
        return _cachedBook;
      } catch (e) {
        debugPrint('[BookService] Not found in assets or error: $e');
      }

      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localDataFile = File('${appDocDir.path}/books/buku_$bookId/data.json');
      debugPrint('[BookService] Checking local storage at: ${localDataFile.path}');
      
      if (await localDataFile.exists()) {
        debugPrint('[BookService] Local data file FOUND');
        final String response = await localDataFile.readAsString();
        final Map<String, dynamic> data = json.decode(response);
        
        Map<String, dynamic> modData = Map.from(data);
        modData['isBundled'] = false;
        modData['localDirectoryPath'] = '${appDocDir.path}/books/buku_$bookId';
        
        _cachedBook = BookModelBundle.fromJson(modData);
        debugPrint('[BookService] Successfully loaded from LOCAL STORAGE');
        return _cachedBook;
      } else {
        debugPrint('[BookService] Local data file NOT found');
      }
      
      return null;
    } catch (e) {
      debugPrint('[BookService] CRITICAL ERROR loading book $bookId: $e');
      return null;
    }
  }

  static Future<BookModelBundle?> loadBookById(String id) async {
    return await getBook(id);
  }

  static Future<Map<String, dynamic>> loadMetadata() async {
    try {
      final String response = await rootBundle.loadString('assets/metadata.json');
      return json.decode(response);
    } catch (e) {
      debugPrint('Error loading metadata: $e');
      return {};
    }
  }
}