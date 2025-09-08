import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kado_ceria/provider/book_views_provider.dart';
import 'package:kado_ceria/services/book_views_service.dart';

@GenerateMocks([BookViewsService])
import 'book_views_provider_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  late MockBookViewsService mockService;
  late BookViewsProvider provider;

  const testBookId = 'test1';

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  setUp(() {
    mockService = MockBookViewsService();
    provider = BookViewsProvider();
    provider.service = mockService;
  });

  group('book views provider tests', () {
    test('normal case : getViews returns correct views', () async {
      // arrange
      when(mockService.getBookViews(testBookId))
          .thenAnswer((_) async => 500);

      // act
      await provider.initViews(testBookId);
      final views = await provider.getViews(testBookId);

      // assert
      expect(views, 500);
      verify(mockService.getBookViews(testBookId)).called(1);
    });

    test('normal case : increment views and update views', () async {
      // arrange
      when(mockService.incrementBookViews(testBookId))
          .thenAnswer((_) async => {});

      // Setup sequential responses untuk getBookViews
      when(mockService.getBookViews(testBookId))
          .thenAnswer((_) async => 500);

      // act
      await provider.initViews(testBookId);

      // Reset mock dan setup untuk setelah increment
      reset(mockService);
      when(mockService.incrementBookViews(testBookId))
          .thenAnswer((_) async => {});
      when(mockService.getBookViews(testBookId))
          .thenAnswer((_) async => 501);

      await provider.incrementViews(testBookId);
      final views = await provider.getViews(testBookId);

      // assert
      expect(views, 501);
      verify(mockService.incrementBookViews(testBookId)).called(1);
      verify(mockService.getBookViews(testBookId)).called(1);
    });

    test('Exception Handling: book views provider throws error', () async {
      // arrange
      when(mockService.getBookViews(testBookId))
          .thenThrow(Exception('Failed to load views'));

      // act & assert
      expect(() async => await provider.getViews(testBookId),
          throwsA(isA<Exception>()));
    });

    test('Exception Handling: increment views throws error', () async {
      // arrange
      when(mockService.getBookViews(testBookId))
          .thenAnswer((_) async => 500);
      when(mockService.incrementBookViews(testBookId))
          .thenThrow(Exception('Failed to increment views'));

      await provider.initViews(testBookId);

      // act & assert
      expect(() async => await provider.incrementViews(testBookId),
          throwsA(isA<Exception>()));
    });
  });
}