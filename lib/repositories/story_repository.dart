import '../models/story_model.dart';
import '../core/assets_loader.dart';

class StoryRepository {
  Future<Story> getStory(String storyId) async {
    try {
      return await AssetsLoader.loadStory(storyId);
    } catch (e) {
      throw Exception('Failed to load story: $e');
    }
  }

  Future<List<String>> getAvailableStories() async {
    // Implementation for getting available stories
    // This would typically read from a manifest or directory
    return ['story1', 'story2', 'story3'];
  }
}