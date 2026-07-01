import 'package:flutter/material.dart';

class BookModelBundle {
  final String id;
  final Map<Language, String> titles;
  final String folderName;
  final Map<Language, String> descriptions;
  final String author;
  final String illustrator;
  final String coverImagePath;
  final List<StoryPage> pages;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isBundled;
  final String? localDirectoryPath;

  BookModelBundle({
    required this.id,
    required this.titles,
    required this.folderName,
    required this.descriptions,
    required this.author,
    required this.illustrator,
    required this.coverImagePath,
    required this.pages,
    required this.primaryColor,
    required this.secondaryColor,
    this.isBundled = true,
    this.localDirectoryPath,
  });

  factory BookModelBundle.fromJson(Map<String, dynamic> json) {
    return BookModelBundle(
      id: json['id']?.toString() ?? '',
      titles: {
        Language.indonesia: json['title_id']?.toString() ?? 'No Title',
        Language.sunda: json['title_su']?.toString() ?? 'No Title',
      },
      folderName: json['folderName']?.toString() ?? '',
      descriptions: {
        Language.indonesia: json['description_id']?.toString() ?? '',
        Language.sunda: json['description_su']?.toString() ?? '',
      },
      author: json['author']?.toString() ?? 'Unknown',
      illustrator: json['illustrator']?.toString() ?? 'Unknown',
      coverImagePath: json['coverImage']?.toString() ?? json['coverImagePath']?.toString() ?? '',
      pages: (json['pages'] as List?)
          ?.map((e) => StoryPage.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      primaryColor: Color(
        int.parse((
            (json['theme']?['primary'])?.toString() ??
                json['primaryColor']?.toString() ??
                '#4FC3F7'
        ).replaceFirst('#', '0xFF')),
      ),
      secondaryColor: Color(
        int.parse((
            (json['theme']?['secondary'])?.toString() ??
                json['secondaryColor']?.toString() ??
                '#81D4FA'
        ).replaceFirst('#', '0xFF')),
      ),
      isBundled: json['isBundled'] ?? true,
      localDirectoryPath: json['localDirectoryPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_id': titles[Language.indonesia],
      'title_su': titles[Language.sunda],
      'folderName': folderName,
      'description_id': descriptions[Language.indonesia],
      'description_su': descriptions[Language.sunda],
      'author': author,
      'illustrator': illustrator,
      'coverImagePath': coverImagePath,
      'pages': pages.map((page) => page.toJson()).toList(),
      'primaryColor': '#${primaryColor.toARGB32().toRadixString(16).substring(2)}',
      'secondaryColor': '#${secondaryColor.toARGB32().toRadixString(16).substring(2)}',
      'isBundled': isBundled,
      'localDirectoryPath': localDirectoryPath,
    };
  }

  String getTitle(Language language) => titles[language] ?? titles[Language.indonesia]!;
  String getDescription(Language language) => descriptions[language] ?? descriptions[Language.indonesia]!;
}

class StoryPage {
  final String? image, backsound, narationId, narationSd;
  final double? widthImage, heightImage;
  final List<InteractiveObject> interactiveObjects;

  StoryPage({
    this.image,
    this.backsound,
    this.narationId,
    this.narationSd,
    this.widthImage,
    this.heightImage,
    this.interactiveObjects = const [],
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    List<InteractiveObject> objects = [];
    
    if (json['interactiveObjects'] != null) {
      objects = (json['interactiveObjects'] as List)
          .map((e) => InteractiveObject.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return StoryPage(
      image: json['image']?.toString(),
      backsound: json['backsound']?.toString(),
      narationId: json['narationId']?.toString(),
      narationSd: json['narationSd']?.toString(),
      widthImage: json['widthImage'] != null ? (json['widthImage'] as num).toDouble() : null,
      heightImage: json['heightImage'] != null ? (json['heightImage'] as num).toDouble() : null,
      interactiveObjects: objects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'backsound': backsound,
      'narationId': narationId,
      'narationSd': narationSd,
      'widthImage': widthImage,
      'heightImage': heightImage,
      'interactiveObjects': interactiveObjects.map((obj) => obj.toJson()).toList(),
    };
  }
}

class InteractiveObject {
  final String? audioObjectId, audioObjectSd;
  final double? x, y, width, height;

  InteractiveObject({
    this.audioObjectId,
    this.audioObjectSd,
    this.x,
    this.y,
    this.width,
    this.height,
  });

  factory InteractiveObject.fromJson(Map<String, dynamic> json) {
    return InteractiveObject(
      audioObjectId: json['audioObjectId']?.toString(),
      audioObjectSd: json['audioObjectSd']?.toString(),
      x: json['x'] != null ? (json['x'] as num).toDouble() : null,
      y: json['y'] != null ? (json['y'] as num).toDouble() : null,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (audioObjectId != null) 'audioObjectId': audioObjectId,
      if (audioObjectSd != null) 'audioObjectSd': audioObjectSd,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }
}

enum Language {
  indonesia('indonesia', {
    'indonesia': 'Bahasa Indonesia',
    'sunda': 'Basa Indonésia'
  }),
  sunda('sunda', {
    'indonesia': 'Bahasa Sunda',
    'sunda': 'Basa Sunda'
  }),
  keduanya('keduanya', {
    'indonesia': 'Kedua bahasa',
    'sunda': 'Duanana'
  });

  const Language(this.code, this.displayNames);
  final String code;
  final Map<String, String> displayNames;

  String getDisplayName(Language currentLanguage) {
    return displayNames[currentLanguage.code] ?? displayNames['indonesia']!;
  }
}

class PageLayout {
  final double interactiveLeft;
  final double interactiveTop;
  final double interactiveWidth;
  final double interactiveHeight;

  PageLayout({
    this.interactiveLeft = 0.0,
    this.interactiveTop = 0.0,
    this.interactiveWidth = 0.0,
    this.interactiveHeight = 0.0,
  });

  factory PageLayout.fromJson(Map<String, dynamic> json) {
    return PageLayout(
      interactiveLeft: (json['interactiveLeft'] as num?)?.toDouble() ?? 0.0,
      interactiveTop: (json['interactiveTop'] as num?)?.toDouble() ?? 0.0,
      interactiveWidth: (json['interactiveWidth'] as num?)?.toDouble() ?? 0.0,
      interactiveHeight: (json['interactiveHeight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interactiveLeft': interactiveLeft,
      'interactiveTop': interactiveTop,
      'interactiveWidth': interactiveWidth,
      'interactiveHeight': interactiveHeight,
    };
  }
}

class BookSummaryModel {
  final String idBuku;
  final String judulBukuIndonesia;
  final String judulBukuSunda;
  final String penulis;
  final String illustrator;
  final String coverImagePath;
  final String descriptionsIndonesia;
  final String descriptionsSunda;
  final String primaryColor;
  final String secondaryColor;
  final int version;
  final String fileSize;
  BookSummaryModel({
    required this.idBuku,
    required this.judulBukuIndonesia,
    required this.judulBukuSunda,
    required this.penulis,
    required this.illustrator,
    required this.coverImagePath,
    required this.descriptionsIndonesia,
    required this.descriptionsSunda,
    required this.primaryColor,
    required this.secondaryColor,
    required this.version,
    required this.fileSize,
  });
  factory BookSummaryModel.fromJson(Map<String, dynamic> json) {
    return BookSummaryModel(
      idBuku: json['id_buku']?.toString() ?? json['id']?.toString() ?? '',
      judulBukuIndonesia: json['judulBukuIndonesia']?.toString() ?? '',
      judulBukuSunda: json['judulBukuSunda']?.toString() ?? '',
      penulis: json['penulis']?.toString() ?? '',
      illustrator: json['illustrator']?.toString() ?? '',
      coverImagePath: json['coverImage']?.toString() ?? json['coverImagePath']?.toString() ?? '',
      descriptionsIndonesia: json['descriptionsIndonesia']?.toString() ?? '',
      descriptionsSunda: json['descriptionsSunda']?.toString() ?? '',
      primaryColor: json['primaryColor']?.toString() ?? '#FFFFFF',
      secondaryColor: json['secondaryColor']?.toString() ?? '#FFFFFF',
      // Parsing angka yang aman
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
      fileSize: json['fileSize']?.toString() ?? '0 MB',
    );
  }
}