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
      'pages': pages,
      'primaryColor': '#${primaryColor.value.toRadixString(16).substring(2)}',
      'secondaryColor': '#${secondaryColor.value.toRadixString(16).substring(2)}',
    };
  }
}

class StoryPage {
  final String image, audioObject;
  final double x, y, width, height, widthImage, heightImage;

  StoryPage({required this.image,  required this.audioObject, required this.height, required this.width, required this.x, required this.y, required this.heightImage, required this.widthImage});

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      image: json['image'],
      audioObject: json['audioObjek'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      widthImage: (json['widthImage'] as num).toDouble(),
      heightImage: (json['heightImage'] as num).toDouble(),
    );
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
    required this.interactiveLeft,
    required this.interactiveTop,
    required this.interactiveWidth,
    required this.interactiveHeight,
  });
}