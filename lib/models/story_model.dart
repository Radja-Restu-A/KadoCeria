class Story {
  final String title;
  final List<StoryPage> pages;

  Story({required this.title, required this.pages});

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      title: json['title'],
      pages: (json['pages'] as List)
          .map((e) => StoryPage.fromJson(e))
          .toList(),
    );
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