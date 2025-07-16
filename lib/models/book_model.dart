import 'package:flutter/material.dart';

class BookModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String author;
  final String illustrator;
  final String coverImagePath;
  final List<String> pages;
  final Color primaryColor;
  final Color secondaryColor;

  BookModel({
    required this.id,
    required this.title,
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
      subtitle: json['subtitle'] ?? '',
      description: json['description'],
      author: json['author'],
      illustrator: json['illustrator'],
      coverImagePath: json['coverImagePath'],
      pages: List<String>.from(json['pages']),
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