import 'package:flutter/material.dart';

class BookModel {
  final String id;
  final String title;
  final String folderName;
  final String subtitle;
  final String description;
  final String author;
  final String illustrator;
  final String coverImagePath;
  final List<StoryPage> pages;
  final Color primaryColor;
  final Color secondaryColor;

  BookModel({
    required this.id,
    required this.title,
    required this.folderName,
    required this.subtitle,
    required this.description,
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
      title: json['title'],
      folderName: json['folderName'],
      subtitle: json['subtitle'] ?? '',
      description: json['description'],
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
      'title': title,
      'folderName': folderName,
      'subtitle': subtitle,
      'description': description,
      'author': author,
      'illustrator': illustrator,
      'coverImagePath': coverImagePath,
      'pages': pages.map((page) => page.toJson()).toList(),
      'primaryColor': '#${primaryColor.value.toRadixString(16).substring(2)}',
      'secondaryColor': '#${secondaryColor.value.toRadixString(16).substring(2)}',
    };
  }
}

class StoryPage {
  final String? image;
  final double? widthImage, heightImage;
  final List<InteractiveObject> interactiveObjects;

  StoryPage({
    this.image,
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
      widthImage: json['widthImage'] != null ? (json['widthImage'] as num).toDouble() : null,
      heightImage: json['heightImage'] != null ? (json['heightImage'] as num).toDouble() : null,
      interactiveObjects: objects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
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
  indonesia('indonesia', 'Bahasa Indonesia'),
  sunda('sunda', 'Bahasa Sunda'),
  keduanya('keduanya', 'Kedua Bahasa');

  const Language(this.code, this.displayName);
  final String code;
  final String displayName;
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