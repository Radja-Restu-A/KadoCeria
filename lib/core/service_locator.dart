import '../services/audio_service.dart';
import '../services/story_service.dart';
import '../repositories/story_repository.dart';

class ServiceLocator {
  static final _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Services
  final AudioService audioService = AudioService();
  final StoryService storyService = StoryService();

  // Repositories
  final StoryRepository storyRepository = StoryRepository();

  // Dispose method for cleanup
  void dispose() {
    audioService.dispose();
  }
}