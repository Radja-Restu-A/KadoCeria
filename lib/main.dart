import 'package:flutter/material.dart';
import 'package:kado_ceria/views/splash_view.dart';
import 'package:provider/provider.dart';
import 'views/splash_view.dart';
import 'viewmodels/book_viewmodel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookViewModel()),
      ],
      child: MaterialApp(
        title: 'Balai Bahasa Provinsi Jawa Barat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
        ),
        home: SplashView(),
      ),
    );
  }
}