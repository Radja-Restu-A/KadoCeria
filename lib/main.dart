import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/screens/flipbook_screen.dart';
import 'models/app_state.dart';
import 'services/navigation_service.dart';
import 'config/app_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const FlipbookScreen(storyId: 'sakeclak_cihujan_hayang_ka_sagara'),
        debugShowCheckedModeBanner: AppConfig.enableDebugMode,
        showPerformanceOverlay: AppConfig.enablePerformanceOverlay,
      ),
    );
  }
}