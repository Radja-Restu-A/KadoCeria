import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/book_viewmodel.dart';
import '../../provider/language_provider.dart';
import '../../provider/teks_provider.dart';
import '../widgets/book_card_widget.dart';
import '../screens/flipbook_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookViewModel, LanguageProvider>(
      builder: (context, bookViewModel, languageProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4FC3F7),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/logo/hade.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                Expanded(
                  child: Text(
                    TeksProvider.getString('appTitle', languageProvider.selectedLanguage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: _buildBody(context, bookViewModel, languageProvider),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context,
      BookViewModel viewModel,
      LanguageProvider languageProvider,
      ) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${viewModel.error}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.refreshBooks(),
              child: Text(
                TeksProvider.getString('retry', languageProvider.selectedLanguage),
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              TeksProvider.getString('noBooks', languageProvider.selectedLanguage),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshBooks,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: viewModel.books.length,
        itemBuilder: (context, index) {
          final book = viewModel.books[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                return BookCardWidget(
                  book: book,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlipbookScreen(
                          bookId: book.id,
                          bookTitle: book.getTitle(languageProvider.selectedLanguage),
                          bookPrimaryColor: book.primaryColor,
                          bookSecondaryColor: book.secondaryColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}