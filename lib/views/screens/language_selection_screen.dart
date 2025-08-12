// lib/views/screens/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:kado_ceria/views/widgets/language_card_widget.dart';
import 'package:provider/provider.dart';
import '../../provider/language_provider.dart';
import '../../models/book_model.dart';
import 'dashboard_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FC3F7), // Light blue
              Color(0xFF29B6F6), // Slightly darker blue
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative circles
              Positioned(
                top: 35,
                right: 40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0x0080cfff).withValues(alpha : 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 250,
                left: 20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0x0080cfff).withValues(alpha : 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                right: 60,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Color(0x0080cfff).withValues(alpha : 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Main content
              Column(
                children: [
                  // Text section - 1/3 of the screen (0.33)
                  Flexible(
                    flex: 45,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start, // posisi horizontal kiri
                          children: [
                            const Text(
                              'Pilih Bahasa\nuntuk teks tampilan',
                              textAlign: TextAlign.left, // memastikan teks rata kiri
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Language cards section - 2/3 of the screen (0.66)
                  Flexible(
                    flex: 55,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: LanguageCardWidget(
                                  description: 'Mayu langsung waé maca buku',
                                  language: 'Bahasa Sunda',
                                  languageEnum: Language.sunda,
                                  onTap: () => _navigateToLanguage(context, Language.sunda),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: LanguageCardWidget(
                                  description: 'Ayo langsung saja membaca buku',
                                  language: 'Bahasa Indonesia',
                                  languageEnum: Language.indonesia,
                                  onTap: () => _navigateToLanguage(context, Language.indonesia),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLanguage(BuildContext context, Language language) {
    context.read<LanguageProvider>().setLanguage(language);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }
}