import 'package:flutter/material.dart';

class BookModel {
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

  BookModel({
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
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'],
      titles: {
        Language.indonesia: json['title_id'],
        Language.sunda: json['title_su'],
      },
      folderName: json['folderName'],
      descriptions: {
        Language.indonesia: json['description_id'],
        Language.sunda: json['description_su'],
      },
      author: json['author'],
      illustrator: json['illustrator'],
      coverImagePath: json['coverImagePath'],
      pages: (json['pages'] as List)
          .map((e) => StoryPage.fromJson(e))
          .toList(),
      primaryColor: Color(
        int.parse(json['primaryColor'].replaceFirst('#', '0xFF')),
      ),
      secondaryColor: Color(
        int.parse(json['secondaryColor'].replaceFirst('#', '0xFF')),
      ),
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
    };
  }

  String getTitle(Language language) => titles[language] ?? titles[Language.indonesia]!;
  String getDescription(Language language) => descriptions[language] ?? descriptions[Language.indonesia]!;
}

class StoryPage {
  final String? image, backsound;
  final double? widthImage, heightImage;
  final List<InteractiveObject> interactiveObjects;

  StoryPage({
    this.image,
    this.backsound,
    this.widthImage,
    this.heightImage,
    this.interactiveObjects = const [],
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    List<InteractiveObject> objects = [];

    // Handle backward compatibility - jika masih menggunakan format lama
    if (json.containsKey('audioObjek') || json.containsKey('x')) {
      objects.add(InteractiveObject(
        audioObject: json['audioObjek'],
        x: json['x'] != null ? (json['x'] as num).toDouble() : null,
        y: json['y'] != null ? (json['y'] as num).toDouble() : null,
        width: json['width'] != null ? (json['width'] as num).toDouble() : null,
        height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      ));
    }

    // Handle new format - multiple interactive objects
    if (json.containsKey('interactiveObjects')) {
      objects = (json['interactiveObjects'] as List)
          .map((e) => InteractiveObject.fromJson(e))
          .toList();
    }

    return StoryPage(
      image: json['image'],
      backsound: json['backsound'],
      widthImage: json['widthImage'] != null ? (json['widthImage'] as num).toDouble() : null,
      heightImage: json['heightImage'] != null ? (json['heightImage'] as num).toDouble() : null,
      interactiveObjects: objects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'backsound': backsound,
      'widthImage': widthImage,
      'heightImage': heightImage,
      'interactiveObjects': interactiveObjects.map((obj) => obj.toJson()).toList(),
    };
  }
}

class InteractiveObject {
  final String? audioObject;
  final double? x, y, width, height;

  InteractiveObject({
    this.audioObject,
    this.x,
    this.y,
    this.width,
    this.height,
  });

  factory InteractiveObject.fromJson(Map<String, dynamic> json) {
    return InteractiveObject(
      audioObject: json['audioObject'] ?? json['audioObjek'], // backward compatibility
      x: json['x'] != null ? (json['x'] as num).toDouble() : null,
      y: json['y'] != null ? (json['y'] as num).toDouble() : null,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audioObject': audioObject,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}

// Language enum
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

// PageLayout data class
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
}