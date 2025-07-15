import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/story_model.dart';

class AssetsLoader {
  static Future<Story> loadStory(String storyId) async {
    final String data = await rootBundle.loadString('assets/$storyId/metadata.json');
    final jsonResult = json.decode(data);
    return Story.fromJson(jsonResult);
  }
}
