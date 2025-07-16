import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryService {

  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    final imageRatio = page.widthImage / page.heightImage;
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

    final scaleX = renderedWidth / page.widthImage;
    final scaleY = renderedHeight / page.heightImage;

    return PageLayout(
      interactiveLeft: (page.x * scaleX) + imageOffsetX,
      interactiveTop: (page.y * scaleY) + imageOffsetY,
      interactiveWidth: page.width * scaleX,
      interactiveHeight: page.height * scaleY,
    );
  }

  List<String> generateAudioPaths(String storyId, int pageNumber, Language language) {
    final basePath = 'assets/$storyId';

    switch (language) {
      case Language.indonesia:
        return ['$basePath/page${pageNumber}_narasi_indonesia.mp3'];
      case Language.sunda:
        return ['$basePath/page${pageNumber}_narasi_sunda.mp3'];
      case Language.keduanya:
        return [
          '$basePath/page${pageNumber}_narasi_indonesia.mp3',
          '$basePath/page${pageNumber}_narasi_sunda.mp3',
        ];
    }
  }

  String generateObjectAudioPath(String storyId, String audioFile) {
    return 'assets/$storyId/$audioFile';
  }

  String generateImagePath(String storyId, String imageName) {
    return 'assets/$storyId/$imageName';
  }

  bool isFirstPage(int currentPage) {
    return currentPage == 0;
  }

  bool isLastPage(int currentPage, int totalPages) {
    return currentPage >= totalPages - 1;
  }
}