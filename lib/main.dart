import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/screens/dashboard_view.dart';
import 'models/app_state.dart';
import 'services/navigation_service.dart';
import 'config/app_config.dart';
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
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: DashboardView(),
        debugShowCheckedModeBanner: AppConfig.enableDebugMode,
        showPerformanceOverlay: AppConfig.enablePerformanceOverlay,
      ),
    );
  }
}