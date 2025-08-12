import 'package:flutter/material.dart';
import 'package:kado_ceria/provider/language_provider.dart';
import 'package:provider/provider.dart';
import 'views/screens/splash_Screen.dart';
import 'models/app_state.dart';
import 'services/navigation_service.dart';
import 'viewmodels/book_viewmodel.dart';

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
        ChangeNotifierProvider(create: (_) => BookViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageProvider())
      ],
      child: MaterialApp(
        title: 'Flipbook App',
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: false,
      ),
    );
  }
}