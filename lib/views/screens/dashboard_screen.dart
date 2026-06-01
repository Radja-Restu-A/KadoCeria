import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_model_bundle.dart';
import '../../viewmodels/book_viewmodel.dart';
import '../../provider/language_provider.dart';
import '../../provider/teks_provider.dart';
import '../widgets/book_card_widget.dart';
import '../screens/flipbook_screen.dart';
import '../screens/language_selection_screen.dart';

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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF4FC3F7),
            child: const Icon(
              Icons.language,
              color: Colors.white,
            ),
          ),
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

    final downloadedBooks = viewModel.books.where((b) =>
    viewModel.bookStates[b.idBuku] == "READY"
    ).toList();

    final onlineBooks = viewModel.books.where((b) =>
    viewModel.bookStates[b.idBuku] != "READY"
    ).toList();

    return RefreshIndicator(
      onRefresh: viewModel.refreshBooks,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (downloadedBooks.isNotEmpty) ...[
            _buildSectionHeader(TeksProvider.getString('myLibrary', languageProvider.selectedLanguage)),
            const SizedBox(height: 10),
            ...downloadedBooks.map((book) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildBookCard(context, book, viewModel, languageProvider),
            )),
            const SizedBox(height: 20),
          ],
          if (onlineBooks.isNotEmpty) ...[
            _buildSectionHeader(TeksProvider.getString('discover', languageProvider.selectedLanguage)),
            const SizedBox(height: 10),
            ...onlineBooks.map((book) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildBookCard(context, book, viewModel, languageProvider),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4FC3F7),
      ),
    );
  }

  Widget _buildBookCard(
      BuildContext context,
      dynamic book,
      BookViewModel viewModel,
      LanguageProvider languageProvider,
      ) {
    final String bookState = viewModel.bookStates[book.idBuku] ?? "NOT_DOWNLOADED";
    final String currentTitle = languageProvider.selectedLanguage == Language.indonesia
        ? book.judulBukuIndonesia
        : book.judulBukuSunda;

    Color primaryColor;
    try {
      primaryColor = Color(int.parse(book.primaryColor.replaceAll('#', '0xFF')));
    } catch (e) {
      primaryColor = const Color(0xFF4FC3F7);
    }

    Color secondaryColor;
    try {
      secondaryColor = Color(int.parse(book.secondaryColor.replaceAll('#', '0xFF')));
    } catch (e) {
      secondaryColor = const Color(0xFF81D4FA);
    }

    return BookCardWidget(
      book: book,
      status: bookState,
      onTap: () {
        if (bookState == "READY") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlipbookScreen(
                bookId: book.idBuku,
                bookTitle: currentTitle,
                bookPrimaryColor: primaryColor,
                bookSecondaryColor: secondaryColor,
              ),
            ),
          );
        } else if (bookState == "NOT_DOWNLOADED") {
          viewModel.triggerDownloadBook(book.idBuku, book.version);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buku sedang diunduh...')),
          );
        }
      },
    );
  }
}